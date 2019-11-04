USE [$(usedbname)]
GO

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
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry with measures.
 *    @p_start_measure (float) - Measure defining start point of located geometry.
 *    @p_end_measure   (float) - Measure defining end point of located geometry.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    line          (geometry) - Line between start/end measure with offset.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
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
    IF ( @v_GeometryType NOT IN ('LineString',
                             'MultiLineString' ) )
      Return @p_linestring;

    -- Only support increasing measured linestrings (at moment)...
    IF ( [$(lrsowner)].[STIsMeasureDecreasing](@p_linestring) = 'TRUE' )
      RETURN NULL;

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
                              /* @p_linestring */ @p_linestring,
                              /* @p_measure    */ @v_start_measure,
                              /* @p_offset     */ @v_offset,
                              /* @p_round_xy   */ @v_round_xy,
                              /* @p_round_zm   */ @v_round_zm
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
            min(v.id) over (partition by v.multi_tag) as first_id,
            max(v.id) over (partition by v.multi_tag) as last_id,
            v.length,
            v.startLength,
            v.measureRange,
            v.geom
       FROM [$(lrsowner)].[STFilterLineSegmentByMeasure] (
                @p_linestring,
                @v_start_measure,
                @v_end_measure,
                @v_round_xy,
                @v_round_zm
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
       -- Processing depends on whether linestring or circular arc segment
       --
       IF ( @v_segment_geom.STGeometryType() = 'LineString' ) 
       BEGIN
          SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitLineSegmentByMeasure] (
                    /* @p_linestring     */ @v_segment_geom,
                    /* @p_start_measure  */ @v_start_measure,
                    /* @p_end_measure    */ @v_end_measure,
                    /* @p_offset         */ @v_offset,
                    /* @p_round_xy       */ @v_round_xy,
                    /* @p_round_zm       */ @v_round_zm
                 );
       END
       ELSE -- IF ( @v_segment_geom.STGeometryType() = 'LineString' ) ... ELSE 
       BEGIN
          SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitCircularStringByMeasure] (
                    /* @p_linestring     */ @v_segment_geom,
                    /* @p_start_measure  */ @v_start_measure,
                    /* @p_end_measure    */ @v_end_measure,
                    /* @p_offset         */ @v_offset,
                    /* @p_round_xy       */ @v_round_xy,
                    /* @p_round_zm       */ @v_round_zm
                 );
       END; -- End of CircularString Processing of Start Point
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
                                        /* @p_round_xy   */ @v_round_xy,
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
       IF ( @v_segment_geom.STGeometryType() = 'LineString' ) 
       BEGIN
          SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitLineSegmentByMeasure] (
                    /* @p_linestring    */ @v_segment_geom,
                    /* @p_start_measure */ @v_segment_geom.STStartPoint().M,
                    /* @p_end_measure   */ @v_end_measure,
                    /* @p_offset        */ @v_offset,
                    /* @p_round_xy      */ @v_round_xy,
                    /* @p_round_zm      */ @v_round_zm
                 );
       END
       ELSE -- IF ( @v_segment_geom.STGeometryType() = 'LineString' ) ... ELSE 
       BEGIN
          SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitCircularStringByMeasure] (
                    /* @p_linestring    */ @v_segment_geom,
                    /* @p_start_measure */ @v_segment_geom.STStartPoint().M,
                    /* @p_end_measure   */ @v_end_measure,
                    /* @p_offset        */ @v_offset,
                    /* @p_round_xy      */ @v_round_xy,
                    /* @p_round_zm      */ @v_round_zm
                 );
       END; -- End of CircularString Processing of Start Point
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
               else case when ( ( @v_return_geom.STGeometryType() = 'CircularString' and @v_return_geom.STNumCurves() = 1 )
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
End
GO

PRINT 'Testing....';
GO

PRINT 'STFindSegmentByMeasureRange -> LineString ...';
PRINT 'LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
Select locateType, 
       sm,em,
       case when f.measureSegment is not null 
            then f.measureSegment.AsTextZM() 
            else null 
        end as measureSegment 
  from (
select 'SM 1.0/EM 1.0 => Start Point' as locateType,1.0 as sm,1.0 as em,  [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,1.0,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM 1.0/EM NULL => Whole Linestring',1.0,null,                     [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,1.0,null,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 1 => Start Point',null,1.0,                            [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,null,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 5.6 => Return 1s Segment',null,5.6,                    [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,null,5.6,0.0,3,2) as measureSegment from data as a
union all
select 'SM 5.6/EM 5.6 => 1st Segment EP or 2nd SP',5.6,5.6,               [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.6,5.6,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 5.0 Within First Segment => New Segment',2.0,5.0,       [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2.0,5.0,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 6.0 => Two New Segments',2.0,6.0,                       [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2,6,0,3,2) as measureSegment from data as a
union all
select 'SM 1.1/EM 25.4 => New 1st Segment, 2nd, New 3rd Segment',1.1,25.1,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,1.1,25.1,0,3,2) as measureSegment from data as a
union all
select 'SM 0.1/EM 30.0 => whole linestring',0.1,30.0,                     [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,0.1,30.0,0,3,2) as measureSegment from data as a
) as f;
GO

PRINT 'STFindSegmentByMeasureRange -> MultiLineString ...';
PRINT 'MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6),(10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))';
GO

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',0) as linestring
)
Select locateType, 
       sm,em,
       case when f.measureSegment is not null 
            then f.measureSegment.AsTextZM() 
            else null 
        end as measureSegment 
  from (
select 'SM before SPM/EM < EPM 1st Segment' as locateType,0 as sm,5.0 as em,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,0.0,5.0,0,3,2) as measureSegment from data as a
union all
select 'SM SPM 2nd Segment / EM NULL => ',                       15.61,null,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,15.61,null,0,3,2) as measureSegment from data as a
union all
select 'SM = SPM/EM EPM Second Segment',                         15.61,25.4,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,15.61,25.4,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM Between 1st and 2nd segments',                    2.0,6.0,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2.0,6.0,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 26.0 (Cross 1st/3rd segments)',                  2.0,26.0,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2.0,26.0,0,3,2) as measureSegment from data as a
union all 
select 'SM 5.6 = EPM 1st Segment/EM 16.61 (2nd Line, 2nd Seg)',   5.6,16.61,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.6,16.61,0.0,3,2) as fsegment from data as a
union all
select 'SM 5.6 = EPM 1st Seg/EM 15.61 (1st Pnt, 2nd Seg) => point only',5.6,15.61,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.6,15.61,0.0,3,2) as fsegment from data as a
union all
select 'SM/EM falls in gap between two segments',                 5.6,15.60,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.61,15.60,0.0,3,2) as fsegment from data as a
) as f;
GO

QUIT
GO    
