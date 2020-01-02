SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS(lrs) Owner($(owner))';
GO

PRINT 'Deleting [$(lrsowner)].[STFindPointsByDeltaMeasure] ...'
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindPointsByDeltaMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION IF EXISTS [$(lrsowner)].[STFindPointsByDeltaMeasure];
  PRINT 'Dropped [$(lrsowner)].[STFindPointsByDeltaMeasure] ... ';
END;
GO

PRINT 'Creating [$(lrsowner)].[STFindPointsByDeltaMeasure] ...'
GO

CREATE FUNCTION [$(lrsowner)].[STFindPointsByDeltaMeasure] 
(
  @p_linestring    geometry,
  @p_measure_delta Float,
  @p_offsets       varchar(1000),
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
Returns geometry 
AS
/****m* LRS/STFindPointsByDeltaMeasure (2012)
 *  NAME
 *    STFindPointsByDeltaMeasure -- Returns (possibly offset) point geometry at supplied measure along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindPointsByDeltaMeasure] (
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
    @v_wkt                varchar(max),
    @v_geometry_type      varchar(30),
    @v_dimensions         varchar(4),
    @v_round_xy           integer,
    @v_round_zm           integer,

    @v_offset             Float,
    @v_Offsets            varchar(1000),
    @v_NumOffsets         integer,
    @v_OffsetN            integer,
	@v_measure            Float,
	@v_measure_delta      Float,

	@v_i                  integer,
	@v_num_points         integer,
    @v_measure_point      geometry,

    /* segment Variables */
    @v_id               integer,
    @v_element_id       integer,
    @v_prev_element_id  integer,
    @v_subelement_id    integer,
    @v_segment_id       integer, 
	@v_sM               float,
	@v_eM               float,
	@v_z_range          float,
	@v_m_range          float,
    @v_prev_segment     geometry,
    @v_segment          geometry,
    @v_next_segment     geometry,

	@v_deflection_angle float,
	@v_circumference    float,
	@v_radius           float,
	@v_angle            float,
	@v_bearing          float,
	@v_centre_point     geometry;

  If ( @p_linestring is null )
    Return @p_linestring;

  If ( @p_measure_delta is null )
    Return @p_linestring;

  If ( @p_linestring.HasM <> 1 )
    Return @p_linestring;

  SET @v_round_xy      = ISNULL(@p_round_xy,3);
  SET @v_round_zm      = ISNULL(@p_round_zm,2);
  SET @v_measure_delta = ROUND(@p_measure_delta,@v_round_zm+1);
  SET @v_dimensions    = 'XY' 
                         + case when @p_linestring.HasZ=1 then 'Z' else '' end +
                         + 'M';

  SET @v_geometry_type = @p_linestring.STGeometryType();
  IF ( @v_geometry_type NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
    Return @p_linestring;

  -- Filter to process all segments
  --
  DECLARE cFilteredSegments 
   CURSOR FAST_FORWARD 
      FOR
   SELECT v.id,
		  ROUND(v.sm,@v_round_xy+1),
		  ROUND(v.em,@v_round_xy+1),
          ROUND(v.measure_range,@v_round_zm),
          v.prev_segment,
          v.segment,
          v.next_segment
     FROM [$(owner)].[STSegmentize] (
             /* @p_geometry     */ @p_linestring,
             /* @p_filter       */ 'ALL',
             /* @p_point        */ NULL,
             /* @p_filter_value */ NULL,
             /* @p_start_value  */ NULL,
             /* @p_end_value    */ NULL,
             /* @p_round_xy     */ @v_round_xy,
             /* @p_round_z      */ @v_round_zm,
             /* @p_round_m      */ @v_round_zm
          ) as v;

   OPEN cFilteredSegments;

  FETCH NEXT 
   FROM cFilteredSegments 
   INTO @v_id,
        @v_sM,
        @v_eM,
        @v_m_range,
        @v_prev_segment,
        @v_segment,
        @v_next_segment;

  -- Check if any filtered segments were returned.
  -- 
  IF ( @@FETCH_STATUS <> 0 ) 
  BEGIN
    -- Nothing to do.
    CLOSE      cFilteredSegments;
    DEALLOCATE cFilteredSegments;
    RETURN NULL; 
  END;

  -- Always use first point
  SET @v_wkt     = '(' + [$(owner)].[STPointGeomAsText](@v_segment.STPointN(1),@v_round_xy,@v_round_zm,@v_round_zm) + '),';
  SET @v_measure = @v_segment.STStartPoint().M;
  WHILE ( @@FETCH_STATUS = 0 )
  BEGIN

    -- How many points do we need to create within this segment that will be offset?
	SET @v_i = 1
	SET @v_num_points = CEILING( (@v_eM - @v_measure) / @v_measure_delta); 
	WHILE (@v_i <= @v_num_points )
	BEGIN
      -- Loop over all offsets for this measure point
      SET @v_offsetN    = 1;
      SET @v_Offsets    = REPLACE(ISNULL(@p_offsets,'0'),' ','');
      SET @v_NumOffsets = LEN(@v_Offsets) - (LEN(REPLACE(@v_offsets,',',''))) + 1;

      WHILE ( @v_OffsetN <= @v_NumOffsets )
      BEGIN
        SET @v_offset  = CAST(case when @v_offsetN = @v_NumOffsets 
                                   then @v_offsets
                                   else SUBSTRING(@v_offsets,1,CHARINDEX(',',@v_offsets,1)-1)
                               end as float);
	    SET @v_offsets = SUBSTRING(@v_offsets,CHARINDEX(',',@v_offsets,1)+1,LEN(@v_offsets));
        SET @v_measure_point = [$(lrsowner)].[STFindPointByMeasure](@v_segment,@v_measure,@v_offset,2,@v_round_xy,@v_round_zm);
        SET @v_wkt          += '(' + [$(owner)].[STPointGeomAsText](@v_measure_point,@v_round_xy,@v_round_zm,@v_round_zm) + '),';
        SET @v_OffsetN      += 1;
	  END;
      SET @v_i              += 1;                -- Next point
	  SET @v_measure        += @v_measure_delta; -- Compute next measure 
    END; -- WHILE (@v_i <= @v_num_points )

    -- Deal with inflection point between two linestrings
    IF ( @v_next_segment is not null )
	BEGIN
	  SET @v_deflection_angle = [$(cogoowner)].[STFindDeflectionAngle](@v_segment,@v_next_segment);
	  IF ( ROUND(@v_deflection_angle,6) <> 0.0 )
	  BEGIN
        SET @v_offsetN = 1;
        SET @v_Offsets = REPLACE(ISNULL(@p_offsets,'0'),' ','');
        WHILE ( @v_OffsetN <= @v_NumOffsets )
        BEGIN
          SET @v_offset  = CAST(case when @v_offsetN = @v_NumOffsets 
                                     then @v_offsets
                                     else SUBSTRING(@v_offsets,1,CHARINDEX(',',@v_offsets,1)-1)
                                 end as float);
	      SET @v_offsets = SUBSTRING(@v_offsets,CHARINDEX(',',@v_offsets,1)+1,LEN(@v_offsets));
		  SET @v_measure_point =      [$(cogoowner)].[STFindPointBisector](@v_segment,@v_next_segment,@v_offset,@v_round_xy,@v_round_zm,@v_round_zm);
	      SET @v_wkt          += '(' + [$(owner)].[STPointGeomAsText]  (@v_measure_point,@v_round_xy,@v_round_zm,@v_round_zm) + '),';
          SET @v_OffsetN      += 1;
		END;
	  END;
	END;

    FETCH NEXT 
     FROM cFilteredSegments 
     INTO @v_id,
          @v_sM,
          @v_eM,
          @v_m_range,
          @v_prev_segment,
          @v_segment,
          @v_next_segment;

  END; -- WHILE ( @@FETCH_STATUS = 0 )


  CLOSE      cFilteredSegments;
  DEALLOCATE cFilteredSegments;

  IF ( @v_measure > @p_linestring.STEndPoint().M )
  BEGIN
    SET @v_measure_point = [$(owner)].[STOffsetPoint](@v_segment,1.0,@v_offset,@v_round_xy,@v_round_zm,@v_round_zm);
    SET @v_wkt          += '(' + [$(owner)].[STPointGeomAsText](@v_measure_point,@v_round_xy,@v_round_zm,@v_round_zm) + '),';
  END;
  -- Get rid of trailing comma and add closing bracket
  SET @v_wkt = 'MULTIPOINT(' + SUBSTRING(@v_wkt,1,LEN(@v_wkt)-1) + ')';
  Return geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid);
END;
GO

