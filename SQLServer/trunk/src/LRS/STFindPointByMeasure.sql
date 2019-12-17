SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindPointByMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindPointByMeasure];
  PRINT 'Dropped [$(lrsowner)].[STFindPointByMeasure] ...';
END;
GO

Print 'Creating [$(lrsowner)].[STFindPointByMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindPointByMeasure] 
(
  @p_linestring geometry,
  @p_measure    Float,
  @p_offset     Float = 0.0,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns geometry 
AS
/****m* LRS/STFindPointByMeasure (2012)
 *  NAME
 *    STFindPointByMeasure -- Returns (possibly offset) point geometry at supplied measure along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindPointByMeasure] (
 *               @p_linestring geometry,
 *               @p_measure    Float,
 *               @p_offset     Float = 0.0,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a measure, this function returns a geometry point at that measure.
 *    If a non-zero/null value is suppied for @p_offset, the found point is offset (perpendicular to line)
 *    to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *  NOTES
 *    Supports LineStrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry with measures.
 *    @p_measure       (float) - Measure defining position of point to be located.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in p_units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided measure offset to left or right.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
******/
BEGIN
  DECLARE
    @v_geometry_type        varchar(30),
    @v_dimensions           varchar(4),
    @v_round_xy             integer,
    @v_round_zm             integer,

    @v_bearing_from_start   Float,
    @v_measure_from_start    Float,
	@v_measure               Float,
    @v_measure_ratio         float,
    @v_offset_bearing       Float,
    @v_offset               Float,
    @v_measure_point         geometry,

    /* segment Variables */
    @v_id              integer,
    @v_max_id          integer,
    @v_element_id      integer,
    @v_prev_element_id integer,
    @v_subelement_id   integer,
    @v_segment_id      integer, 
	@v_sZ              float,
	@v_sM              float,
	@v_eM              float,
	@v_z_range         float,
	@v_m_range         float,
    @v_segment_length  float,
    @v_segment_start_length float,
    @v_segment_end_length   float,
    @v_prev_segment    geometry,
    @v_segment         geometry,
    @v_next_segment    geometry,

	@v_deflection_angle float,
	@v_circumference    float,
	@v_radius           float,
	@v_angle            float,
	@v_bearing          float,
	@v_centre_point     geometry;

    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_measure is null )
      Return @p_linestring;

    If ( @p_linestring.HasM <> 1 )
      Return @p_linestring;

    SET @v_round_xy   = ISNULL(@p_round_xy,3);
    SET @v_round_zm   = ISNULL(@p_round_zm,2);
	SET @v_measure    = ROUND(@p_measure,@v_round_zm+1);
	SET @v_offset     = ISNULL(@p_offset,0.0);
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end +
                       + 'M';

    SET @v_geometry_type = @p_linestring.STGeometryType();
    IF ( @v_geometry_type NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return @p_linestring;

    -- Shortcircuit:
    -- If same point as start/end
    -- 
    IF ( @v_offset = 0.0
      and ( @p_measure = @p_linestring.STPointN(1).M 
         or @p_measure = @p_linestring.STPointN(@p_linestring.STNumPoints()).M ) )
    BEGIN
      Return case when @p_measure = @p_linestring.STPointN(1).M
                  then @p_linestring.STPointN(1)
                  else @p_linestring.STPointN(@p_linestring.STNumPoints())
              end;
    END;

    -- Filter to find specific segment containing measure
    --
    SELECT TOP 1
	       @v_id                   = v.id,
		   @v_max_id               = v.max_id,
           @v_geometry_type        = v.geometry_type,
           @v_sZ                   = ROUND(v.sz,@v_round_xy+1),
		   @v_sM                   = ROUND(v.sm,@v_round_xy+1),
		   @v_eM                   = ROUND(v.em,@v_round_xy+1),
           /* Derived values */           
		   @v_m_range              = ROUND(v.measure_range,@v_round_zm),
           @v_segment_length       = ROUND(v.segment_length,@v_round_xy+1),
           @v_segment_start_length = ROUND(v.start_length,@v_round_xy+1),
		   @v_segment_end_length   = ROUND(v.cumulative_length,@v_round_xy+1),
           @v_prev_segment         = v.prev_segment,
           @v_segment              = v.segment,
           @v_next_segment         = v.next_segment
      FROM [$(owner)].[STSegmentize] (
             /* @p_geometry     */ @p_linestring,
             /* @p_filter       */ 'MEASURE',
             /* @p_point        */ NULL,
             /* @p_filter_value */ @p_measure,
             /* @p_start_value  */ NULL,
             /* @p_end_value    */ NULL,
             /* @p_round_xy     */ @v_round_xy,
             /* @p_round_z      */ @v_round_zm,
             /* @p_round_m      */ @v_round_zm
           ) as v;

    IF @@ROWCOUNT = 0
      RETURN NULL;

    -- We have a single row (first filtered segment) and it always contains required length point

    -- Short Circuit: Handle situation where point is at start of first segment
    IF ( @v_measure = @v_sM )
    BEGIN
	  IF ( @v_prev_segment is not null )
	    SET @v_measure_point = [$(cogoowner)].[STFindPointBisector](
		                        @v_prev_segment,
								@v_segment,
								@v_offset,
								@v_round_xy,@v_round_zm,@v_round_zm
                               )
      ELSE
	    SET @v_measure_point = [$(owner)].[STOffsetPoint](
	                             @v_segment,
                                 0.0,
                                 @v_offset
                              );
      RETURN @v_measure_point;
    END;

    -- Short Circuit: Is point at end of last segment?
    IF ( @v_measure = @v_eM )
    BEGIN
	  IF ( @v_next_segment is not null )
	    SET @v_measure_point = [$(cogoowner)].[STFindPointBisector](
		                          @v_segment,
							      @v_next_segment,
								  @v_offset,
								  @v_round_xy,@v_round_zm,@v_round_zm
                               )
      ELSE
	    SET @v_measure_point = [$(owner)].[STOffsetPoint](
	                              @v_segment,
                                  1.0,
                                  @v_offset
                              );
      RETURN @v_measure_point;
    END;

	-- Required point is within current segment.
	-- 
	IF ( @v_segment.STGeometryType() = 'LineString' )
	BEGIN
      SET @v_bearing_from_start = [$(cogoowner)].[STBearingBetweenPoints] (
                                     @v_segment.STStartPoint(),
                                     @v_segment.STEndPoint()
                                  );

      -- Compute point along line by length
      SET @v_measure_ratio   = (@v_measure - @v_sM) / @p_linestring.STEndPoint().M;
      SET @v_measure_point   = geometry::STPointFromText(
                              'POINT(' 
                              + 
                              [$(owner)].[STPointAsText] (
                                /* @p_dimensions */ @v_dimensions,
                                /* @p_X          */ @v_segment.STStartPoint().STX +
                                                   (@v_segment.STEndPoint().STX-@v_segment.STStartPoint().STX)
                                                    * @v_measure_ratio,
                                /* @p_Y          */ @v_segment.STStartPoint().STY +
                                                   (@v_segment.STEndPoint().STY-@v_segment.STStartPoint().STY)
                                                    * @v_measure_ratio,
                                /* @p_Z          */ @v_sZ + (@v_z_range * @v_measure_ratio),
                                /* @p_M          */ @v_sM + (@v_m_range * @v_measure_ratio),
                                /* @p_round_x    */ @v_round_xy,
                                /* @p_round_y    */ @v_round_xy,
                                /* @p_round_z    */ @v_round_zm,
                                /* @p_round_m    */ @v_round_zm
                              )
                              + 
                              ')',
                              @p_linestring.STSrid
                            );

      -- Offset the point if required
      IF (    @v_offset is not null 
          and @v_offset <> 0.0 ) 
      BEGIN
        -- Compute offset bearing
        SET @v_offset_bearing = case when (@v_offset < 0) 
                                     then (@v_bearing_from_start-90.0) 
                                     else (@v_bearing_from_start+90.0) 
                                 end;

        -- Normalise
        SET @v_offset_bearing = [$(cogoowner)].[STNormalizeBearing](@v_offset_bearing);

        -- compute offset point from length point
        SET @v_measure_point = [$(cogoowner)].[STPointFromCOGO] ( 
                                  @v_measure_point,
                                  @v_offset_bearing,
                                  ABS(@v_offset),
                                  @v_round_xy
                              );

        SET @v_measure_point   = geometry::STPointFromText(
                                'POINT(' 
                                + 
                                [$(owner)].[STPointAsText] (
                                  /* @p_dimensions */ @v_dimensions,
                                  /* @p_X          */ @v_measure_point.STStartPoint().STX,
                                  /* @p_Y          */ @v_measure_point.STStartPoint().STY,
                                  /* @p_Z          */ @v_sZ + (@v_z_range * @v_measure_ratio),
                                  /* @p_M          */ @v_sM + (@v_m_range * @v_measure_ratio),
                                  /* @p_round_x    */ @v_round_xy,
                                  /* @p_round_y    */ @v_round_xy,
                                  /* @p_round_z    */ @v_round_zm,
                                  /* @p_round_m    */ @v_round_zm
                                )
                                + 
                                ')',
                                @p_linestring.STSrid
                              );
      END;
	  RETURN @v_measure_point;
    END;

  -- ***************************************************
  -- We now have a CircularString
  -- Compute centre of circle defining CircularString
  --
  SET @v_centre_point = [$(cogoowner)].[STFindCircleFromArc] (@v_segment);

  -- Defines circle?
  IF (  @v_centre_point.STX = -1 
    and @v_centre_point.STY = -1 
    and @v_centre_point.Z   = -1 )
    Return null;

  -- Retrieve radius and remove from centre point
  SET @v_radius = @v_centre_point.Z;
  SET @v_centre_point = geometry::Point(@v_centre_point.STX,@v_centre_point.STY,@v_segment.STSrid);

  -- Compute circumference of circle
  SET @v_circumference = 2.0 * PI() * @v_radius;

  -- Compute the angle subtended by the arc at the centre of the circle
  SET @v_angle         = @v_segment_length / @v_circumference * 360.0;

  -- Compute length ratio to apply to @v_angle to locate point
  SET @v_measure_ratio  = (@v_measure - @v_sM) / @p_linestring.STEndPoint().M;

  -- Apply ratio to angle
  SET @v_angle         = @v_angle * @v_measure_ratio;

  -- Compute bearing from centre to first point of circular arc
  SET @v_bearing       = [$(cogoowner)].[STBearingBetweenPoints](
                             @v_centre_point,
                             @v_segment.STStartPoint()
                         );

  -- Adjust bearing depending on whether CircularString is rotating anticlockwise (-1) or clockwise(1) 
  SET @v_bearing       = @v_bearing + ( @v_angle * [$(cogoowner)].[STisClockwiseArc] (@v_segment));

  -- Normalise bearing
  SET @v_bearing       = [$(cogoowner)].[STNormalizeBearing](@v_bearing);

  -- Compute point
  SET @v_measure_point  = [$(cogoowner)].[STPointFromCOGO](
                             @v_centre_point,
                             @v_Bearing,
                             @v_radius - @v_offset,
                             @p_round_xy
                          );

 -- TOBEDONE: If new point between STPointN(1) and STPointN(2) and M need to be computed differently than assuming all 
 SET @v_measure_point = geometry::STPointFromText(
                         'POINT(' 
                         + 
                         [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_measure_point.STX,
                            /* @p_Y          */ @v_measure_point.STY,
                            /* @p_Z          */ @v_sZ + (@v_z_range * @v_measure_ratio),
                            /* @p_M          */ @v_sM + (@v_m_range * @v_measure_ratio),
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                         )
                         + 
                         ')',
                         @v_segment.STSrid
                       );
  Return @v_measure_point;
END;
GO
