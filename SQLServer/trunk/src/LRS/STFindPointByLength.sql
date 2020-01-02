SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS(lrs) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindPointByLength]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindPointByLength];
  PRINT 'Dropped [$(lrsowner)].[STFindPointByLength] ... ';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindPointByRatio]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindPointByRatio];
  PRINT 'Dropped [$(lrsowner)].[STFindPointByRatio] ... ';
END;
GO

-- ***************************************************************************************

Print 'Creating [$(lrsowner)].[STFindPointByLength] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindPointByLength] 
(
  @p_linestring   geometry,
  @p_length       Float,
  @p_offset       Float = 0.0,
  @p_radius_check int   = 0,
  @p_round_xy     int   = 3,
  @p_round_zm     int   = 2
)
Returns geometry 
AS
/****f* LRS/STFindPointByLength (2012)
 *  NAME
 *    STFindPointByLength -- Returns (possibly offset) point geometry at supplied distance along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindPointByLength] (
 *               @p_linestring   geometry,
 *               @p_length       Float,
 *               @p_offset       Float = 0.0,
 *               @p_radius_check int   = 0,
 *               @p_round_xy     int   = 3,
 *               @p_round_zm     int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a length (0 to @p_linestring.STLength()), this function returns a geometry point at the position described by that length.
 *
 *    If a non-zero/null value is suppied for @p_offset, the found point is offset (perpendicular to line) to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *
 *    If the offset is greater than the radius of the CircularString, and @p_radius_check is 1, no point is returned, if @p_radius_check is 2 then the centre of the curve is returned, otherwise a point is returned.
 *
 *    The returned point has its ordinate values rounded using the supplied @p_round_xy/@p_round_zm decimal place values.
 *  NOTES
 *    Supports LineStrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry.
 *    @p_length        (float) - Length defining position of point to be located. Valid values between 0.0 and @p_linestring.STLength()
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_radius_check    (int) - If measure point and offset is on same side as centre of circular string and offset > radius: no point is returned if (1), the centre point returned if 2, otherwise the computed point is returned.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided distance from start, offset to left or right.
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
 *      union all 
 *      select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
 *    )
 *    select a.linestring.STGeometryType() as line_type,
 *           a.linestring.HasM as is_measured,
 *           g.intValue as length,
 *           offset.IntValue as offset,
 *           [$(lrsowner)].[STFindPointByLength](a.linestring,g.IntValue,offset.IntValue,3,2).AsTextZM() as fPoint
 *      from data as a
 *           cross apply
 *           [$(owner)].[generate_series](0,a.lineString.STLength(),a.linestring.STLength() / 4.0 ) as g
 *           cross apply
 *           [$(owner)].[generate_series](-1,1,1) as offset
 *    order by line_type, is_measured, length
 *    GO
 *    
 *    line_type      is_measured length offset fPoint
 *    CircularString           1      0     -1 POINT (3.428 7.229 NULL 0)
 *    CircularString           1      0      0 POINT (3 6.325 NULL 0)
 *    CircularString           1      0      1 POINT (2.572 5.421 NULL 0)
 *    CircularString           1      1     -1 POINT (2.364 7.643 NULL 0.99)
 *    CircularString           1      1      0 POINT (2.069 6.687 NULL 0.99)
 *    CircularString           1      1      1 POINT (1.774 5.732 NULL 0.99)
 *    CircularString           1      2     -1 POINT (1.252 7.901 NULL 1.98)
 *    CircularString           1      2      0 POINT (1.096 6.914 NULL 1.98)
 *    CircularString           1      2      1 POINT (0.939 5.926 NULL 1.98)
 *    CircularString           1      3     -1 POINT (0.115 7.999 NULL 2.98)
 *    CircularString           1      3      0 POINT (0.1 6.999 NULL 2.98)
 *    CircularString           1      3      1 POINT (0.086 5.999 NULL 2.98)
 *    CircularString           1      4     -1 POINT (-1.025 7.934 NULL 3.97)
 *    CircularString           1      4      0 POINT (-0.897 6.942 NULL 3.97)
 *    CircularString           1      4      1 POINT (-0.769 5.951 NULL 3.97)
 *    CircularString           1      5     -1 POINT (-2.144 7.707 NULL 4.96)
 *    CircularString           1      5      0 POINT (-1.877 6.744 NULL 4.96)
 *    CircularString           1      5      1 POINT (-1.609 5.78 NULL 4.96)
 *    CircularString           1      6     -1 POINT (-3.22 7.324 NULL 5.95)
 *    CircularString           1      6      0 POINT (-2.818 6.408 NULL 5.95)
 *    CircularString           1      6      1 POINT (-2.415 5.493 NULL 5.95)
 *    CompoundCurve            0      0     -1 POINT (3.429 7.228)
 *    CompoundCurve            0      0      0 POINT (3 6.3246)
 *    CompoundCurve            0      0      1 POINT (2.571 5.421)
 *    CompoundCurve            0      5     -1 POINT (-2.144 7.707)
 *    CompoundCurve            0      5      0 POINT (-1.876 6.744)
 *    CompoundCurve            0      5      1 POINT (-1.608 5.78)
 *    CompoundCurve            0     10     -1 POINT (-0.468 3.321)
 *    CompoundCurve            0     10      0 POINT (-1.372 2.892)
 *    CompoundCurve            0     10      1 POINT (-2.276 2.463)
 *    CompoundCurve            0     15     -1 POINT (-0.133 2.054)
 *    CompoundCurve            0     15      0 POINT (0.771 1.625)
 *    CompoundCurve            0     15      1 POINT (1.675 1.196)
 *    CompoundCurve            0     20     -1 POINT (2.01 6.572)
 *    CompoundCurve            0     20      0 POINT (2.914 6.143)
 *    CompoundCurve            0     20      1 POINT (3.818 5.714)
 *    CompoundCurve            1      0     -1 POINT (3.429 7.228 NULL 0)
 *    CompoundCurve            1      0      0 POINT (3 6.3246 NULL 0)
 *    CompoundCurve            1      0      1 POINT (2.571 5.421 NULL 0)
 *    CompoundCurve            1      5     -1 POINT (-2.144 7.707 NULL 4.96)
 *    CompoundCurve            1      5      0 POINT (-1.876 6.744 NULL 4.96)
 *    CompoundCurve            1      5      1 POINT (-1.608 5.78 NULL 4.96)
 *    CompoundCurve            1     10     -1 POINT (-0.468 3.321 NULL 6.89)
 *    CompoundCurve            1     10      0 POINT (-1.372 2.892 NULL 6.89)
 *    CompoundCurve            1     10      1 POINT (-2.276 2.463 NULL 6.89)
 *    CompoundCurve            1     15     -1 POINT (-0.133 2.054 NULL 11)
 *    CompoundCurve            1     15      0 POINT (0.771 1.625 NULL 11)
 *    CompoundCurve            1     15      1 POINT (1.675 1.196 NULL 11)
 *    CompoundCurve            1     20     -1 POINT (2.01 6.572 NULL 13.5)
 *    CompoundCurve            1     20      0 POINT (2.914 6.143 NULL 13.5)
 *    CompoundCurve            1     20      1 POINT (3.818 5.714 NULL 13.5)
 *    LineString               1      0     -1 POINT (-4.707 -3.293 0 1)
 *    LineString               1      0      0 POINT (-4 -4 0 1)
 *    LineString               1      0      1 POINT (-3.293 -4.707 0 1)
 *    LineString               1      6     -1 POINT (0.343 1 0 5.73)
 *    LineString               1      6      0 POINT (0.343 0 0 5.73)
 *    LineString               1      6      1 POINT (0.343-1 0 5.73)
 *    LineString               1     12     -1 POINT (6.343 1 0 8.07)
 *    LineString               1     12      0 POINT (6.343 0 0 8.07)
 *    LineString               1     12      1 POINT (6.343-1 0 8.07)
 *    LineString               1     18     -1 POINT (9 2.343 0 16.5)
 *    LineString               1     18      0 POINT (10 2.343 0 16.5)
 *    LineString               1     18      1 POINT (11 2.343 0 16.5)
 *    LineString               1     24     -1 POINT (9 8.343 0 18.79)
 *    LineString               1     24      0 POINT (10 8.343 0 18.79)
 *    LineString               1     24      1 POINT (11 8.343 0 18.79)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *    Simon Greener - December 2019 - Added @p_radius_check
******/
BEGIN
  DECLARE
    @v_geometry_type        varchar(30),
    @v_dimensions           varchar(4),
    @v_round_xy             integer,
    @v_round_zm             integer,

    @v_bearing_from_start   Float,
    @v_length_from_start    Float,
    @v_length               Float,
    @v_length_ratio         float,
    @v_offset_bearing       Float,
    @v_offset               Float,
    @v_length_point         geometry,
    @v_clockwise            float,
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
  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_length is null )
      Return @p_linestring;

    SET @v_geometry_type = @p_linestring.STGeometryType();

    IF ( @v_geometry_type NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset   = ISNULL(@p_offset,0.0);
    SET @v_length   = ROUND(ISNULL(@p_length,0.0),@v_round_xy+1);

    -- Shortcircuit:
    -- If same point as start/end and no offset
    -- 
    IF ( @v_offset = 0.0 and ( @v_length = 0.0 or @v_length = ROUND(@p_linestring.STLength(),@v_round_xy+1) ) )
    BEGIN
      Return case when @v_length = 0.0
                  then @p_linestring.STPointN(1)
                  else @p_linestring.STPointN(@p_linestring.STNumPoints())
              end;
    END;

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- Filter to find specific segment containing length position
    --
    SELECT TOP 1
           @v_id                   = v.id,
           @v_max_id               = v.max_id,
           @v_geometry_type        = v.geometry_type,
           @v_sZ                   = ROUND(v.sz,@v_round_xy+1),
           @v_sM                   = ROUND(v.sm,@v_round_xy+1),
           @v_z_range              = v.z_range,
           @v_m_range              = v.measure_range,
           /* Derived values */           
           @v_segment_length       = ROUND(v.segment_length,@v_round_xy+1),
           @v_segment_start_length = ROUND(v.start_length,@v_round_xy+1),
           @v_segment_end_length   = ROUND(v.cumulative_length,@v_round_xy+1),
           @v_prev_segment         = v.prev_segment,
           @v_segment              = v.segment,
           @v_next_segment         = v.next_segment
      FROM [$(owner)].[STSegmentize] (
             /* @p_geometry     */ @p_linestring,
             /* @p_filter       */ 'LENGTH',
             /* @p_point        */ NULL,
             /* @p_filter_value */ @p_length,
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
    IF ( @v_length = @v_segment_start_length )
    BEGIN
      IF ( @v_prev_segment is not null )
        SET @v_length_point = [$(cogoowner)].[STFindPointBisector](
                                @v_prev_segment,
                                @v_segment,
                                @v_offset,
                                @v_round_xy,@v_round_zm,@v_round_zm
                               )
      ELSE
        SET @v_length_point = [$(owner)].[STOffsetPoint](
                                 @v_segment,
                                 0.0,
                                 @v_offset,
                                 @v_round_xy,
                                 @v_round_zm,
                                 @v_round_zm
                              );
      RETURN @v_length_point;
    END;

    -- Short Circuit: Is point at end of last segment?
    IF ( @v_length = @v_segment_end_length )
    BEGIN
      IF ( @v_next_segment is not null )
        SET @v_length_point = [$(cogoowner)].[STFindPointBisector](
                                @v_segment,
                                @v_next_segment,
                                @v_offset,
                                @v_round_xy,@v_round_zm,@v_round_zm
                               )
      ELSE
        SET @v_length_point = [$(owner)].[STOffsetPoint](
                                 @v_segment,
                                 1.0,
                                 @v_offset,
                                 @v_round_xy,
                                 @v_round_zm,
                                 @v_round_zm
                              );
      RETURN @v_length_point;
    END;

    -- ###########################################################################
    -- ############################## LineString #################################
    -- ###########################################################################
    IF ( @v_segment.STGeometryType() = 'LineString' )
    BEGIN
      SET @v_bearing_from_start = [$(cogoowner)].[STBearingBetweenPoints] (
                                     @v_segment.STStartPoint(),
                                     @v_segment.STEndPoint()
                                  );

      -- Compute point along line by length
      SET @v_length_ratio   = (@v_length - @v_segment_start_length) / @v_segment_length;
      SET @v_length_point   = geometry::STPointFromText(
                              'POINT(' 
                              + 
                              [$(owner)].[STPointAsText] (
                                /* @p_dimensions */ @v_dimensions,
                                /* @p_X          */ @v_segment.STStartPoint().STX +
                                                   (@v_segment.STEndPoint().STX-@v_segment.STStartPoint().STX)
                                                    * @v_length_ratio,
                                /* @p_Y          */ @v_segment.STStartPoint().STY +
                                                   (@v_segment.STEndPoint().STY-@v_segment.STStartPoint().STY)
                                                    * @v_length_ratio,
                                /* @p_Z          */ @v_sZ + (@v_z_range * @v_length_ratio),
                                /* @p_M          */ @v_sM + (@v_m_range * @v_length_ratio),
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
      IF ( @v_offset <> 0.0 ) 
      BEGIN
        -- Compute offset bearing
        SET @v_offset_bearing = case when (@v_offset < 0) 
                                     then (@v_bearing_from_start-90.0) 
                                     else (@v_bearing_from_start+90.0) 
                                 end;

        -- Normalise
        SET @v_offset_bearing = [$(cogoowner)].[STNormalizeBearing](@v_offset_bearing);

        -- compute offset point from length point
        SET @v_length_point = [$(cogoowner)].[STPointFromCOGO] ( 
                                 @v_length_point,
                                 @v_offset_bearing,
                                 ABS(@v_offset),
                                 @v_round_xy
                              );

        SET @v_length_point   = geometry::STPointFromText(
                                'POINT(' 
                                + 
                                [$(owner)].[STPointAsText] (
                                  /* @p_dimensions */ @v_dimensions,
                                  /* @p_X          */ @v_length_point.STStartPoint().STX,
                                  /* @p_Y          */ @v_length_point.STStartPoint().STY,
                                  /* @p_Z          */ @v_sZ + (@v_z_range * @v_length_ratio),
                                  /* @p_M          */ @v_sM + (@v_m_range * @v_length_ratio),
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
      RETURN @v_length_point;
    END;

    -- ###########################################################################
    -- ############################## CircularString #############################
    -- ###########################################################################

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
    SET @v_length_ratio  = (@v_length - @v_segment_start_length) / @v_segment_length;

    -- Apply ratio to angle
    SET @v_angle         = @v_angle * @v_length_ratio;

    -- Compute bearing from centre to first point of circular arc
    SET @v_bearing       = [$(cogoowner)].[STBearingBetweenPoints](
                             @v_centre_point,
                             @v_segment.STStartPoint()
                           );

    -- Adjust bearing depending on whether CircularString is rotating anticlockwise (-1) or clockwise(1) 
    SET @v_clockwise     = [$(cogoowner)].[STisClockwiseArc] (@v_segment);
    SET @v_bearing       = @v_bearing + ( @v_angle * @v_clockwise);

    -- Normalise bearing
    SET @v_bearing       = [$(cogoowner)].[STNormalizeBearing](@v_bearing);

    -- Check if offset extends out past circular arc centre.
    -- Return centre if requested otherwise return null
    IF ( ( @v_clockwise = -1 AND @v_offset < 0 )
      OR ( @v_clockwise = 1 AND @v_offset > 0 ) )
    BEGIN
     IF ( @v_radius_check = 1 AND ABS(@v_offset) > @v_radius )
       RETURN NULL ;
     IF ( @v_radius_check = 2 AND ABS(@v_offset) >= @v_radius )
       RETURN @v_centre_point;
    END;
  
    -- Compute point
    SET @v_offset        = @v_radius - (@v_clockwise*@v_offset);
  
    SET @v_length_point  = [$(cogoowner)].[STPointFromCOGO](
                               @v_centre_point,
                               @v_Bearing,
                               @v_offset,
                               @p_round_xy
                             );
  
     -- TOBEDONE: If new point between STPointN(1) and STPointN(2) and M need to be computed differently than assuming all 
     SET @v_length_point = geometry::STPointFromText(
                           'POINT(' 
                           + 
                           [$(owner)].[STPointAsText] (
                              /* @p_dimensions */ @v_dimensions,
                              /* @p_X          */ @v_length_point.STX,
                              /* @p_Y          */ @v_length_point.STY,
                              /* @p_Z          */ @v_sZ + (@v_z_range * @v_length_ratio),
                              /* @p_M          */ @v_sM + (@v_m_range * @v_length_ratio),
                              /* @p_round_x    */ @v_round_xy,
                              /* @p_round_y    */ @v_round_xy,
                              /* @p_round_z    */ @v_round_zm,
                              /* @p_round_m    */ @v_round_zm
                           )
                           + 
                           ')',
                           @v_segment.STSrid
                         );
    Return @v_length_point;
  END;  
END;
GO

Print 'Creating [$(lrsowner)].[STFindPointByRatio] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindPointByRatio] 
(
  @p_linestring   geometry,
  @p_ratio        Float,
  @p_offset       Float = 0.0,
  @p_radius_check bit   = 1,
  @p_round_xy     int   = 3,
  @p_round_zm     int   = 2
)
Returns geometry 
AS
/****f* LRS/STFindPointByRatio (2012)
 *  NAME
 *    STFindPointByRatio -- Returns (possibly offset) point geometry at supplied length ratio along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindPointByRatio] (
 *               @p_linestring geometry,
 *               @p_ratio      Float,
 *               @p_offset     Float = 0.0,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a ratio (0 to 1.0), this function returns a geometry point at the position described by that ratio.
 *
 *    Ratio is combined with length, so @p_ratio of 1.0 is equivalent to @p_linestring.STLength() ie @p_linestring.STEndPoint().
 *
 *    For example, @p_ratio value of 0.5 returns point at exact midpoint of linestring (ct centroid).
 *
 *    If a non-zero/null value is suppied for @p_offset, the found point is offset (perpendicular to line) to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *
 *    The returned point has its ordinate values rounded using the supplied @p_round_xy/@p_round_zm decimal place values.
 *  NOTES
 *    Supports LineStrings with CircularString elements.
 *    Wrapper over STFindPointByLength
 *  INPUTS
 *    @p_linestring (geometry) - Linestring (including CircularString) geometry.
 *    @p_ratio         (float) - Length ratio between 0.0 and 1.0. If Null, @p_linestring is returned.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in STSrid units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided length ratio from start, with optional offset to left or right.
 *  EXAMPLE
 *    -- LineString test.
 *    select f.ratio,
 *           o.IntValue as offset,
 *           [$(lrsowner)].[STFindPointByRatio] (
 *              geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0),
 *              f.ratio,
 *              o.IntValue,
 *              3,
 *              2
 *           ).AsTextZM() as fPoint
 *      from (select 0.01 * CAST(t.IntValue as numeric) as ratio
 *              from [$(owner)].[Generate_Series](1,100,10) as t
 *              ) as f
 *              cross apply 
 *            [$(owner)].[generate_series](-1,1,1) as o
 *      order by f.ratio
 *    GO
 *
 *    ratio offset fPoint
 *    0.01      -1  POINT (-4.526 -3.112 0 1.05)
 *    0.01       0  POINT (-3.819 -3.819 0 1.05)
 *    0.01       1  POINT (-3.112 -4.526 0 1.05)
 *    0.11      -1  POINT (-2.711 -1.297 0 1.51)
 *    0.11       0  POINT (-2.004 -2.004 0 1.51)
 *    0.11       1  POINT (-1.297 -2.711 0 1.51)
 *    0.21      -1  POINT (-0.897 0.517 0 1.97)
 *    0.21       0  POINT (-0.19 -0.19 0 1.97)
 *    0.21       1  POINT (0.517 -0.897 0 1.97)
 *    0.31      -1  POINT (2.297 1 0 6.5)
 *    0.31       0  POINT (2.297 0 0 6.5)
 *    0.31       1  POINT (2.297 -1 0 6.5)
 *    0.41      -1  POINT (4.862 1 0 7.5)
 *    0.41       0  POINT (4.862 0 0 7.5)
 *    0.41       1  POINT (4.862 -1 0 7.5)
 *    0.51      -1  POINT (7.428 1 0 8.5)
 *    0.51       0  POINT (7.428 0 0 8.5)
 *    0.51       1  POINT (7.428 -1 0 8.5)
 *    0.61      -1  POINT (9.994 1 0 9.5)
 *    0.61       0  POINT (9.994 0 0 9.5)
 *    0.61       1  POINT (9.994 -1 0 9.5)
 *    0.71      -1  POINT (9 2.56 0 16.59)
 *    0.71       0  POINT (10 2.56 0 16.59)
 *    0.71       1  POINT (11 2.56 0 16.59)
 *    0.81      -1  POINT (9 5.125 0 17.57)
 *    0.81       0  POINT (10 5.125 0 17.57)
 *    0.81       1  POINT (11 5.125 0 17.57)
 *    0.91      -1  POINT (9 7.691 0 18.54)
 *    0.91       0  POINT (10 7.691 0 18.54)
 *    0.91       1  POINT (11 7.691 0 18.54)
 *    
 *    -- Circular Curve test.
 *    select f.ratio,
 *           o.IntValue as offset,
 *           [$(lrsowner)].[STFindPointByRatio] (
 *              geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
 *              f.ratio,
 *              o.IntValue,
 *              3,
 *              2
 *           ).AsTextZM() as fPoint
 *      from (select 0.01 * CAST(t.IntValue as numeric) as ratio
 *              from [$(owner)].[Generate_Series](1,100,10) as t
 *           ) as f
 *           cross apply 
 *           [$(owner)].[generate_series](-1,1,1) as o
 *      order by f.ratio
 *    GO
 *    
 *    ratio offset fPoint
 *    0.01      -1  POINT (3.219 7.324)
 *    0.01       0  POINT (2.816 6.409)
 *    0.01       1  POINT (2.414 5.493)
 *    0.11      -1  POINT (1.001 7.937)
 *    0.11       0  POINT (0.876 6.945)
 *    0.11       1  POINT (0.751 5.953)
 *    0.21      -1  POINT (-1.299 7.894)
 *    0.21       0  POINT (-1.137 6.907)
 *    0.21       1  POINT (-0.974 5.92)
 *    0.31      -1  POINT (-2.07 6.698)
 *    0.31       0  POINT (-2.974 6.269)
 *    0.31       1  POINT (-3.878 5.84)
 *    0.41      -1  POINT (-1.204 4.873)
 *    0.41       0  POINT (-2.108 4.444)
 *    0.41       1  POINT (-3.012 4.015)
 *    0.51      -1  POINT (-0.338 3.048)
 *    0.51       0  POINT (-1.242 2.619)
 *    0.51       1  POINT (-2.146 2.19)
 *    0.61      -1  POINT (0.528 1.223)
 *    0.61       0  POINT (-0.376 0.794)
 *    0.61       1  POINT (-1.28 0.365)
 *    0.71      -1  POINT (-0.415 1.46)
 *    0.71       0  POINT (0.489 1.031)
 *    0.71       1  POINT (1.393 0.602)
 *    0.81      -1  POINT (0.451 3.285)
 *    0.81       0  POINT (1.355 2.856)
 *    0.81       1  POINT (2.259 2.427)
 *    0.91      -1  POINT (1.317 5.111)
 *    0.91       0  POINT (2.221 4.682)
 *    0.91       1  POINT (3.125 4.253)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_geometry_type nvarchar(max),
    @v_length        float;
  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_ratio is null )
      Return @p_linestring;

    If ( @p_ratio not between 0.0 and 1.0 ) 
      Return @p_linestring;

    SET @v_geometry_type = @p_linestring.STGeometryType();

    IF ( @v_geometry_type NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return @p_linestring;

    -- Compute length using ratio
    SET @v_length = @p_linestring.STLength() * @p_ratio;

    -- Now call STFindPointByLength
    Return [$(lrsowner)].[STFindPointByLength](
                    @p_linestring,
                    @v_length,
                    @p_offset,
                    @p_radius_check,
                    @p_round_xy,
                    @p_round_zm
                 );
  END; 
END;
GO

