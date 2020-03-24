SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '*********************************************************************';
PRINT 'Database Schema Variables are: lrsOwner($(lrsowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindSegmentByMeasureRange]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindSegmentByMeasureRange];
  PRINT 'Dropped [$(lrsowner)].[STFindSegmentByMeasureRange]';
END;
GO

Print 'Creating [$(lrsowner)].[STFindSegmentByMeasureRange] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindSegmentByMeasureRange]
(
  @p_linestring    geometry,
  @p_start_measure Float,
  @p_end_measure   Float = null,
  @p_offset        Float = 0.0,
  @p_radius_check  int   = 1,
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
returns geometry 
as
/****f* LRS/STFindSegmentByMeasureRange (2012)
 *  NAME
 *    STFindSegmentByMeasureRange -- Extracts, and possibly offet, linestring using supplied start and end measures and @p_offset value.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindSegmentByMeasureRange] (
 *               @p_linestring    geometry,
 *               @p_start_measure Float,
 *               @p_end_measure   Float = null,
 *               @p_offset        Float = 0,
 *               @p_radius_check  int   = 1,
 *               @p_round_xy      int   = 3,
 *               @p_round_zm      int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a start and end measure, this function extracts the line segment defined between them (a point if start=end).
 *
 *    If a non-zero value is suppied for @p_offset, the extracted line is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *
 *    Computes Z and M values if exist on @p_linestring.
 *
 *    If a genenerated point is on the side of the centre of a CircularString ie offset > radius: 
 *        0 returns the offset point regardless.
 *        1 causes NULL to be returned; 
 *        2 returns centre point; 
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry with measures.
 *    @p_start_measure (float) - Measure defining start point of located geometry.
 *    @p_end_measure   (float) - Measure defining end point of located geometry.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_radius_check    (int) - 0 returns the offset point regardless; 1 causes NULL to be returned; 2 returns centre point; 
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    line          (geometry) - Line between start/end measure with offset.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *    Simon Greener - December 2019 - Coalesced circularString and Linestring code under one function; Added @p_radius_check.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_GeometryType        varchar(100),
    @v_Dimensions          varchar(4),
    @v_offset              float,
    @v_round_xy            int,
    @v_round_zm            int,
    /* Measure Variables */
    @v_start_measure       float,
    @v_end_measure         float,
    /* Processing Variables */
    @v_new_segment_geom    geometry,
    @v_return_geom         geometry,
    /* Filtered Segment Variables */
    @v_id                  int,
    @v_first_id            int,
    @v_last_id             int,
    @v_segmentLength       float,
    @v_LengthFromStart     float,
    @v_segmentMeasureRange float,
    @v_segment_geom        geometry;

  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_linestring.HasM <> 1 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','CircularString','CompoundCurve','MultiLineString' ) )
      Return @p_linestring;

    SET @v_round_xy      = ISNULL(@p_round_xy,3);
    SET @v_round_zm      = ISNULL(@p_round_zm,2);
    SET @v_offset        = 0.0; -- Offset done by STOffsetLine at end of function if @p_offset <> 0.0
    SET @v_start_measure = case when @p_start_measure is null then @p_linestring.STStartPoint().M else @p_start_measure end;
    SET @v_end_measure   = case when @p_end_measure   is null then @p_linestring.STEndPoint().M   else @p_end_measure   end;

    -- Check if measure range covers complete linestring 
    If (   @v_start_measure <= @p_linestring.STPointN(1).M
       AND @v_end_measure   >= @p_linestring.STPointN(@p_linestring.STNumPoints()).M )
      Return @p_linestring;

    -- Check if zero measure range  
    If ( @v_start_measure = @v_end_measure )
      Return [$(lrsowner)].[STFindPointByMeasure] (
                              /* @p_linestring  */ @p_linestring,
                              /* @p_measure     */ @v_start_measure,
                              /* @p_offset      */ @v_offset,
                              /* @p_radius_check*/ @p_radius_check,
                              /* @p_round_xy    */ @v_round_xy,
                              /* @p_round_zm    */ @v_round_zm
                           );

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end +
                       + 'M';

    -- process measures against FilteredSegments ...
    --
    DECLARE cFilteredSegments 
     CURSOR FAST_FORWARD 
        FOR
      SELECT v.id,
             v.min_id as first_id,
             v.max_id as last_id,
             /* Derived values */           
             ROUND(v.segment_length,@v_round_xy+1) as length,
             ROUND(v.start_length,  @v_round_xy+1) as startLength,
             ROUND(v.measure_range, @v_round_zm+1) as measureRange,
             v.segment      as geom
        FROM [$(owner)].[STSegmentize] (
               /* @p_geometry     */ @p_linestring,
               /* @p_filter       */ 'MEASURE_RANGE',
               /* @p_point        */ NULL,
               /* @p_filter_value */ NULL,
               /* @p_start_value  */ @v_start_measure,
               /* @p_end_value    */ @v_end_measure,
               /* @p_round_xy     */ @p_round_xy,
               /* @p_round_z      */ @v_round_zm,
               /* @p_round_m      */ @v_round_zm
             ) as v
       ORDER BY v.id;

   OPEN cFilteredSegments;

   FETCH NEXT 
    FROM cFilteredSegments 
    INTO @v_id,
         @v_first_id,
         @v_last_id,
         @v_segmentLength,
         @v_LengthFromStart,
         @v_segmentMeasureRange,
         @v_segment_geom;

   -- Check if any filtered segments were returned.
   -- 
   IF ( @@FETCH_STATUS <> 0 ) 
   BEGIN
     -- Nothing to do.
     CLOSE      cFilteredSegments;
     DEALLOCATE cFilteredSegments;
     RETURN NULL; 
   END;

   WHILE ( @@FETCH_STATUS = 0 )
   BEGIN

     -- Process length value against each segment
     --

     -- Start length is always related to the first segment
     --
     IF ( @v_id = @v_first_id ) /* first segment test */
     BEGIN
       SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitSegmentByMeasure] (
                    /* @p_linestring   */ @v_segment_geom,
                    /* @p_start_measure*/ @v_start_measure,
                    /* @p_end_measure  */ @v_end_measure,
                    /* @p_offset       */ @v_offset,
                    /* @p_radius_check */ @p_radius_check,
                    /* @p_round_xy     */ @v_round_xy,
                    /* @p_round_zm     */ @v_round_zm
                 );

       IF ( @v_new_segment_geom is not null 
        AND @v_new_segment_geom.STGeometryType() in ('Point','LineString','CircularString') ) 
       BEGIN
         SET @v_return_geom = @v_new_segment_geom;
         -- If we only have one segment, we can break out of the loop
         IF ( @v_id = @v_last_id ) /* EP is within this segment */
         BEGIN
           BREAK;
         END;
       END
       ELSE
       BEGIN
        SET @v_new_segment_geom = NULL;
       END;
     END; -- IF ( @v_id = @v_first_id ) 

     /* *********************************************************** */
     -- All of segment is within length range
     -- Add whole segment.
     --
     IF ( @v_id > @v_first_id 
      and @v_id < @v_last_id ) 
     BEGIN
       -- Add this segment to output linestring.
       SET @v_return_geom = case when @v_return_geom is null
                                 then [$(owner)].[STRound] (
                                        /* @p_linestring */ @v_segment_geom,
                                        /* @p_round_x    */ @v_round_xy,
                                        /* @p_round_y    */ @v_round_xy,
                                        /* @p_round_z    */ @v_round_zm,
                                        /* @p_round_m    */ @v_round_zm
                                      )
                                 else [$(owner)].[STAppend] (
                                       /* @p_linestring1 */ @v_return_geom,
                                       /* @p_linestring1 */ @v_segment_geom,
                                       /* @p_round_xy    */ @v_round_xy,
                                       /* @p_round_xy    */ @v_round_zm
                                      )
                             end;
     END; -- IF ( @v_id < @v_last_id )

     /* *********************************************************** */
     -- Process end length within this segment
     --
     IF ( @v_id = @v_last_id ) 
     BEGIN
       -- Must round ordinates to ensure start/end coordinate points match 
       SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitSegmentByMeasure] (
                    /* @p_linestring    */ @v_segment_geom,
                    /* @p_start_measure */ @v_segment_geom.STStartPoint().M,
                    /* @p_end_measure   */ @v_end_measure,
                    /* @p_offset        */ @v_offset,
                    /* @p_radius_check  */ @p_radius_check,
                    /* @p_round_xy      */ @v_round_xy,
                    /* @p_round_zm      */ @v_round_zm
                 );
       IF ( @v_new_segment_geom.STGeometryType() in ('LineString','CircularString') ) 
       BEGIN
         -- Add segment to return geom
         SET @v_return_geom = case when @v_return_geom is null
                                   then @v_new_segment_geom
                                   else [$(owner)].[STAppend] (
                                          /* @p_linestring1 */ @v_return_geom,
                                          /* @p_linestring1 */ @v_new_segment_geom,
                                          /* @p_round_xy    */ @v_round_xy,
                                          /* @p_round_xy    */ @v_round_zm
                                        )
                               end;
       END;
     END; -- IF ( @v_id = @v_last_id )

     FETCH NEXT 
      FROM cFilteredSegments 
      INTO @v_id,
           @v_first_id,
           @v_last_id,
           @v_segmentLength,
           @v_LengthFromStart,
           @v_segmentMeasureRange,
           @v_segment_geom;

   END; -- WHILE ( @@FETCH_STATUS = 0 )

   CLOSE      cFilteredSegments;
   DEALLOCATE cFilteredSegments;

   SET @v_offset = ISNULL(@p_offset,0.0); 
   -- Implement shortcut for parallel if single CircularString or LineString
   Return case when @v_offset = 0.0 
               then @v_return_geom 
               else case when ( ( @v_return_geom.STGeometryType() = 'CircularString' and [$(owner)].[STNumCircularStrings](@v_return_geom) = 1)
                             OR ( @v_return_geom.STGeometryType() = 'LineString'     and @v_return_geom.STNumPoints() = 2 ) )
                         then [$(owner)].[STOffsetSegment] (
                                /* @p_linestring */ @v_return_geom,
                                /* @p_offset     */ @v_offset,
                                /* @p_round_xy   */ @v_round_xy,
                                /* @p_round_zm   */ @v_round_zm
                              )
                         else [$(owner)].[STOffsetLine] (
                                /* @p_linestring */ @v_return_geom,
                                /* @p_offset     */ @v_offset,
                                /* @p_round_xy   */ @v_round_xy,
                                /* @p_round_zm   */ @v_round_zm
                              )
                     end
           end;

  END;
End;
GO
