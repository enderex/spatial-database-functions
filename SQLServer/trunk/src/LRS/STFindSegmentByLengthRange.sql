SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '************************************************************************************';
PRINT 'Database Schema Variables are: Cogo=$(cogoowner), LRS=$(lrsowner) Owner=$(owner)';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindSegmentByLengthRange]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(lrsowner)].[STFindSegmentByLengthRange];
  PRINT 'Dropped [$(lrsowner)].[STFindSegmentByLengthRange] ...';
END;
GO

-- **********************************************************

PRINT 'Creating [$(lrsowner)].[STFindSegmentByLengthRange] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindSegmentByLengthRange]
(
  @p_linestring   geometry,
  @p_start_length Float,
  @p_end_length   Float = null,
  @p_offset       Float = 0,
  @p_round_xy     int   = 3,
  @p_round_zm     int   = 2
)
returns geometry 
as
/****m* LRS/STFindSegmentByLengthRange (2012)
 *  NAME
 *    STFindSegmentByLengthRange -- Extracts, and possibly offet, linestring using supplied start and end lengths and @p_offset value.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindSegmentByLengthRange] (
 *               @p_linestring   geometry,
 *               @p_start_length Float,
 *               @p_end_length   Float = null,
 *               @p_offset       Float = 0,
 *               @p_round_xy     int   = 3,
 *               @p_round_zm     int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a start and end length, this function extracts the line segment defined between them (a point if start=end).
 *    If a non-zero value is suppied for @p_offset, the extracted line is then offset to the left (if @p_offset < 0) or
 *    to the right (if @p_offset > 0).
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry.
 *    @p_start_measure (float) - Measure defining start point of located geometry.
 *    @p_end_measure   (float) - Measure defining end point of located geometry.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in p_units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    line          (geometry) - Line between start/end measure with offset.
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('MULTILINESTRING ((-4 -4 NULL 0, 0 0 NULL 5.657), (10 0 NULL 5.657, 10 10 NULL 15.657), (11 11 NULL 15.657, 12 12 NULL 17.071))',0) as linestring
 *    )
 *    select a.linestring.STGeometryType() as geom_type,
 *           CAST(g.IntValue+1 as numeric) / 2.0 as start_length,
 *           g.intValue+1.0                      as end_length,
 *           [$(lrsowner)].[STFindSegmentByLengthRange](
 *                    a.linestring,
 *                    CAST(g.IntValue   as numeric) / 2.0,
 *                    CAST(g.IntValue+1 as numeric),
 *                    0.0,
 *                    3,2
 *           ).AsTextZM() as fsegment
 *      from data as a
 *           cross apply
 *           generate_series(0,
 *                           round(a.lineString.STLength(),0),
 *                           round(a.lineString.STLength(),0)/8.0 ) as g
 *     order by geom_type, start_length
 *    GO
 *    
 *    geom_type       start_length end_length fsegment
 *    CompoundCurve    0.5          1.0       CIRCULARSTRING (2.069 6.687, 0 7, 3 6.325)
 *    CompoundCurve    1.5          3.0       CIRCULARSTRING (0.1 6.999, 0 7, 2.069 6.687)
 *    CompoundCurve    2.5          5.0       CIRCULARSTRING (-1.876 6.744, 0 7, 1.096 6.914)
 *    CompoundCurve    3.5          7.0       COMPOUNDCURVE ((-2.657 5.603, -3 6.325), CIRCULARSTRING (-3 6.325, 0 7, 0.1 6.999))
 *    CompoundCurve    4.5          9.0       COMPOUNDCURVE (CIRCULARSTRING (-0.897 6.942, 0 7, -3 6.325), (-3 6.325, -1.8 3.796))
 *    CompoundCurve    5.5         11.0       COMPOUNDCURVE (CIRCULARSTRING (-1.876 6.744, 0 7, -3 6.325), (-3 6.325, -0.943 1.989))
 *    CompoundCurve    6.5         13.0       COMPOUNDCURVE (CIRCULARSTRING (-2.817 6.408, 0 7, -3 6.325), (-3 6.325, -0.086 0.182))
 *    CompoundCurve    7.5         15.0       LINESTRING (0.771 1.625, 0 0, -2.657 5.603)
 *    CompoundCurve    8.5         17.0       LINESTRING (1.628 3.432, 0 0, -2.229 4.699)
 *    CompoundCurve    9.5         19.0       LINESTRING (2.485 5.239, 0 0, -1.8 3.796)
 *    CompoundCurve   10.5         21.0       LINESTRING (3 6.325, 0 0, -1.372 2.892)
 *    LineString       0.5          1.0       LINESTRING (-3.293 -3.293 0 1.81, -4 -4 0 1)
 *    LineString       2.0          4.0       LINESTRING (-1.172 -1.172 0 4.25, -2.939 -2.939 0 2.22)
 *    LineString       3.5          7.0       LINESTRING (1.343 0 0 6.94, 0 0 0 5.6, -1.879 -1.879 0 3.44)
 *    LineString       5.0         10.0       LINESTRING (4.343 0 0 9.95, 0 0 0 5.6, -0.818 -0.818 0 4.66)
 *    LineString       6.5         13.0       LINESTRING (7.343 0 0 12.95, 0.343 0 0 5.94)
 *    LineString       8.0         16.0       LINESTRING (10 0.343 0 15.95, 10 0 0 15.61, 1.843 0 0 7.44)
 *    LineString       9.5         19.0       LINESTRING (10 3.343 0 18.88, 10 0 0 15.61, 3.343 0 0 8.95)
 *    LineString      11.0         22.0       LINESTRING (10 6.343 0 21.82, 10 0 0 15.61, 4.843 0 0 10.45)
 *    LineString      12.5         25.0       LINESTRING (10 9.343 0 24.76, 10 0 0 15.61, 6.343 0 0 11.95)
 *    MultiLineString  0.5          1.0       LINESTRING (-3.293 -3.293 NULL 1, -4 -4 NULL 0)
 *    MultiLineString  1.5          3.0       LINESTRING (-1.879 -1.879 NULL 3, -3.293 -3.293 NULL 1)
 *    MultiLineString  2.5          5.0       LINESTRING (-0.464 -0.464 NULL 5, -2.586 -2.586 NULL 2)
 *    MultiLineString  3.5          7.0       MULTILINESTRING ((10 1.343 NULL 7, 10 0 NULL 5.66), (0 0 NULL 5.66, -1.879 -1.879 NULL 3))
 *    MultiLineString  4.5          9.0       MULTILINESTRING ((10 3.343 NULL 9, 10 0 NULL 5.66), (0 0 NULL 5.66, -1.172 -1.172 NULL 4))
 *    MultiLineString  5.5         11.0       MULTILINESTRING ((10 5.343 NULL 11, 10 0 NULL 5.66), (0 0 NULL 5.66, -0.464 -0.464 NULL 5))
 *    MultiLineString  6.5         13.0       LINESTRING (10 7.343 NULL 13, 10 0.343 NULL 6)
 *    MultiLineString  7.5         15.0       LINESTRING (10 9.343 NULL 15, 10 1.343 NULL 7)
 *    MultiLineString  8.5         17.0       MULTILINESTRING ((11.95 11.95 NULL 17, 11 11 NULL 15.66), (10 10 NULL 15.66, 10 2.343 NULL 8))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
******/
begin
  DECLARE
    @v_GeometryType     varchar(100),
    @v_Dimensions       varchar(4),

    /* Parameters */
    @v_start_length     float,
    @v_end_length       float,
    @v_end_distance     Float,
    @v_offset           float = 0.0,
    @v_round_xy         int,
    @v_round_zm         int,

    @v_new_segment_geom geometry,
    @v_return_geom      geometry,

    /* Filtered Segment Variables */
    @v_id               int,
    @v_first_id         int,
    @v_last_id          int,
    @v_segmentLength    float,
    @v_LengthFromStart  float,
    @v_segment_geom     geometry;

  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    -- Function only processes linear geometries
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType 
         NOT IN (
           'MultiLineString',
           'CompoundCurve',
           'LineString',
           'CircularString'
         ) 
    )
    BEGIN
      Return @p_linestring;
    END;

    SET @v_round_xy     = ISNULL(@p_round_xy,3);
    SET @v_round_zm     = ISNULL(@p_round_zm,2);
    SET @v_offset       = 0.0; -- Offset done by STOffsetLine at end of function if @p_offset <> 0.0
    SET @v_start_length = ROUND(
                            case when ISNULL(@p_start_length,-1)<=-1 then 0.0
                                 else @p_start_length 
                             end,
                            @v_round_xy
                          );
    SET @v_end_length   = ROUND(
                            case when ISNULL(@p_end_length,-1)<=-1 then @p_linestring.STLength() 
                                 when @p_end_length >= @p_linestring.STLength() then @p_linestring.STLength()
                                 else @p_end_length
                             end,
                             @v_round_xy
                          );

    -- Check if length range covers complete linestring 
    If (   @v_start_length = 0.0
       AND @v_end_length   = @p_linestring.STLength() )
      Return @p_linestring;

    -- Check if zero length range (ie point solution)
    If ( @v_start_length = @v_end_length )
      Return [$(lrsowner)].[STFindPointByLength] (
                              /* @p_linestring */ @p_linestring,
                              /* @p_length     */ @v_start_length,
                              /* @p_offset     */ @v_offset,
                              /* @p_round_xy   */ @v_round_xy,
                              /* @p_round_zm   */ @v_round_zm
                           );

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- Process measures against FilteredSegments ...
    --
    DECLARE cFilteredSegments 
     CURSOR FAST_FORWARD 
        FOR
     SELECT v.id, 
            min(v.id) over (partition by v.multi_tag) as first_id,
            max(v.id) over (partition by v.multi_tag) as last_id,
            v.length,
            v.startLength,
            v.geom
       FROM [$(lrsowner)].[STFilterLineSegmentByLength] ( 
                @p_linestring,
                @v_start_length,
                @v_end_length,
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
                 [$(lrsowner)].[STSplitLineSegmentByLength] (
                    /* @p_linestring     */ @v_segment_geom,
                    /* @p_start_distance */ @v_start_length - @v_LengthFromStart,
                    /* @p_end_distance   */ @v_end_length   - @v_LengthFromStart,
                    /* @p_offset         */ @v_offset,
                    /* @p_round_xy       */ @v_round_xy,
                    /* @p_round_zm       */ @v_round_zm
                 );
       END
       ELSE -- CircularString
       BEGIN
          SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitCircularStringByLength] (
                    /* @p_linestring     */ @v_segment_geom,
                    /* @p_start_distance */ @v_start_length - @v_LengthFromStart,
                    /* @p_end_distance   */ @v_end_length   - @v_LengthFromStart,
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
                                        /* @p_linestring2 */ @v_segment_geom,
                                        /* @p_round_xy    */ @v_round_xy,
                                        /* @p_round_zm    */ @v_round_zm
                                      )
                             end;
     END; -- IF ( @v_id < @v_last_id )

     /* *********************************************************** */
     -- Process end length within this segment
     -- Ensure not single point.
     SET @v_end_distance = @v_end_length - @v_LengthFromStart;
     IF ( @v_id = @v_last_id 
      AND ROUND(@v_end_distance,@v_round_xy) <> 0.0 )
     BEGIN
       -- Must round ordinates to ensure start/end coordinate points match 
       IF ( @v_segment_geom.STGeometryType() = 'LineString' ) 
       BEGIN
          SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitLineSegmentByLength] (
                    /* @p_linestring     */ @v_segment_geom,
                    /* @p_start_distance */ 0.0,
                    /* @p_end_distance   */ @v_end_distance,
                    /* @p_offset         */ @v_offset,
                    /* @p_round_xy       */ @v_round_xy,
                    /* @p_round_zm       */ @v_round_zm
                 );
       END
       ELSE -- IF ( @v_segment_geom.STGeometryType() = 'LineString' ) ... ELSE 
       BEGIN
          SET @v_new_segment_geom = 
                 [$(lrsowner)].[STSplitCircularStringByLength] (
                    /* @p_linestring     */ @v_segment_geom,
                    /* @p_start_distance */ 0.0,
                    /* @p_end_distance   */ @v_end_distance,
                    /* @p_offset         */ @v_offset,
                    /* @p_round_xy       */ @v_round_xy,
                    /* @p_round_zm       */ @v_round_zm
                 );
       END; -- End of CircularString Processing of Start Point

       IF ( @v_new_segment_geom.STGeometryType() in ('Point','LineString','CircularString') ) 
       BEGIN
         -- Add segment to return geom
         SET @v_return_geom = case when @v_return_geom is null
                                   then @v_new_segment_geom
                                   else [$(owner)].[STAppend](
                                          /* @p_linestring1 */ @v_return_geom,
                                          /* @p_linestring2 */ @v_new_segment_geom,
                                          /* @p_round_xy    */ @v_round_xy,
                                          /* @p_round_zm    */ @v_round_zm
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
           @v_segment_geom;

   END; -- WHILE ( @@FETCH_STATUS = 0 )

   CLOSE      cFilteredSegments;
   DEALLOCATE cFilteredSegments;

   SET @v_offset = ISNULL(@p_offset,0.0); 
   IF ( @v_offset = 0.0 )
     Return @v_return_geom;
   
   -- Implement shortcut for parallel if single CircularString or LineString
   SET @v_return_geom = 
          case when ( ( @v_return_geom.STGeometryType() = 'CircularString' and @v_return_geom.STNumCurves() = 1 )
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
                 end;
    Return @v_return_geom;
  END;
End
GO

-- **************************************************************************************************

Print 'Testing [$(lrsowner)].[STFindSegmentByLengthRange] ...';
GO

with mLine as (
  SELECT geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0) as mLinestring
)
select 'ORGNL' as tSource, e.mLineString from mLine as e
union all
SELECT 'SGMNT', [$(lrsowner)].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0, 0.0, 3, 2).STBuffer(0.3) as Lengths2SegmentNoOffset FROM mLine as e
-- union all
-- SELECT 'RIGHT', [$(lrsowner)].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0, 1.0, 3, 2).STBuffer(0.3) as Lengths2SegmentNoOffset FROM mLine as e
-- union all
-- SELECT 'LEFT',  [$(lrsowner)].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0,-1.0, 3, 2).STBuffer(0.3) as Lengths2SegmentNoOffset FROM mLine as e
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
Select locateType, segmentByLength.AsTextZM() as segmentByLength from (
select 'SM 1-> EM NULL->25.4 => While Linestring' as locateType,   [$(lrsowner)].[STFindSegmentByLengthRange](linestring,1,null,0,3,2) as segmentByLength from data as a
union all
select 'SM NULL->1, EM 1 => Start Point' as locateType,            [$(lrsowner)].[STFindSegmentByLengthRange](linestring,null,1,0,3,2) as segmentByLength from data as a
union all
select 'SM == EM 1 => Start Point' as locateType,                  [$(lrsowner)].[STFindSegmentByLengthRange](linestring,1,1,0,3,2) as segmentByLength from data as a
union all
select 'SM NULL, EM 5.6 => Return 1s Segment' as locateType,       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,null,5.6,0.0,3,2) as segmentByLength from data as a
union all
select 'SM / EM 5.6 => 1st Segment End Point' as locateType,       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,5.6,5.6,0,3,2) as segmentByLength from data as a
union all
select 'SM / EM Within First Segment => New Segment',              [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2.0,5.0,0,3,2) as segmentByLength from data as a
union all
select 'SM 2.0, EM 6.0 => two new segments',                       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2,6,0,3,2) as segmentByLength from data as a
union all
select 'SM 1.1, EM 25.4 => new 1st segment, current 2nd, new 3rd', [$(lrsowner)].[STFindSegmentByLengthRange](linestring,1.1,25.1,0,3,2) as segmentByLength from data as a
union all
select 'SM Before SPM, EM after EPM=> whole linestring',           [$(lrsowner)].[STFindSegmentByLengthRange](linestring,0.1,30.0,0,3,2) as segmentByLength from data as a 
) as f;
GO

-- MultiLineString....

--select [$(lrsowner)].STAddMeasure(geometry::STGeomFromText('MULTILINESTRING((-4 -4, 0  0), (10  0, 10 10),(11 11, 12 12 ))',0),
--       0.0,null,3,3).AsTextZM() as segmentByLength;
-- go

with data as (
select geometry::STGeomFromText('MULTILINESTRING ((-4 -4 NULL 0, 0 0 NULL 5.657), (10 0 NULL 5.657, 10 10 NULL 15.657), (11 11 NULL 15.657, 12 12 NULL 17.071))',0) as linestring
)
Select locateType, f.segmentByLength.AsTextZM() as segmentByLength from (
select 'Original Linestring'                  as locateType,       linestring as segmentByLength from data as a
union all
select 'SL before SP and EL after EP of Line' as locateType,       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,0,30.0,0,3,2) as segmentByLength from data as a
union all
select 'SL = SP 2nd Segment / End Rest of Line' as locateType,     [$(lrsowner)].[STFindSegmentByLengthRange](linestring,15.61,null,0,3,2) as segmentByLength from data as a
union all
select 'SL = SP / EL 2nd Point in Second Segment' as locateType,   [$(lrsowner)].[STFindSegmentByLengthRange](linestring,15.61,25.4,0,3,2) as segmentByLength from data as a
union all
select 'EL Falls between 1st and 2nd segments',                    [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2,6,0,3,2) as segmentByLength from data as a
union all
select 'Range Crosses 1st and 3rd segments',                       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2,26,0,3,2) as segmentByLength from data as a
union all
select 'SL = EP First Segment with EL next segment',               [$(lrsowner)].[STFindSegmentByLengthRange](linestring,5.6,16.61,0.0,3,2) as fsegment from data as a
union all
select 'SL/EL falls in gap between two segments',                  [$(lrsowner)].[STFindSegmentByLengthRange](linestring,5.6,15.61,0.0,3,2) as fsegment from data as a
) as f;
GO

with data as (
  select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
  union all
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
  union all
  select geometry::STGeomFromText('MULTILINESTRING ((-4 -4 NULL 0, 0 0 NULL 5.657), (10 0 NULL 5.657, 10 10 NULL 15.657), (11 11 NULL 15.657, 12 12 NULL 17.071))',0) as linestring
)
select 'Original'              as geom_type,
       0.0                     as start_length, 
       a.lineString.STLength() as end_length, 
       linestring
  from data as a
union all
select a.linestring.STGeometryType()       as geom_type,
       CAST(g.IntValue+1 as numeric) / 2.0 as start_length,
       g.intValue+1.0                      as end_length,
       [$(lrsowner)].[STFindSegmentByLengthRange] (
           a.linestring,
           CAST(g.IntValue   as numeric) / 2.0,
           CAST(g.IntValue+1 as numeric),
           0.0,
           3,2
       ) as fsegment
  from data as a
       cross apply
       generate_series(0,
                       round(a.lineString.STLength(),0),
                       round(a.lineString.STLength(),0)/8.0 ) as g
 order by geom_type, start_length
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
select 0.0            as start_length,
       g.intValue+1.0 as end_length,
       [$(lrsowner)].[STFindSegmentByLengthRange](a.linestring,0.0,g.IntValue+1,0.0,3,2).AsTextZM() as fsegment
  from data as a
       cross apply
       generate_series(0,
                       round(a.lineString.STLength(),0),
                       round(a.lineString.STLength()/4.0,0)
                      ) as g;
GO

/*
with data as (
select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3))',0) as cString
)
select 0.0  as start_length,
       21.0 as end_length,
       [$(lrsowner)].[STFindSegmentByLengthRange] (
           a.cString,
           0.0,
           21.0,
           0.0,
           3,2) as fsegment
  from data as a
GO
*/

