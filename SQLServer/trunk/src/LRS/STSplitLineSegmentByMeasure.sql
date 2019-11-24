SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '************************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplitLineSegmentByMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(lrsowner)].[STSplitLineSegmentByMeasure];
  PRINT 'Dropped [$(lrsowner)].[STSplitLineSegmentByMeasure] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STSplitLineSegmentByMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSplitLineSegmentByMeasure] 
(
  @p_linestring    geometry,
  @p_start_measure float,
  @p_end_measure   float = null,
  @p_offset        float = 0.0,
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
Returns geometry 
As
/****f* LRS/STSplitLineSegmentByMeasure (2012)
 *  NAME
 *    STSplitLineSegmentByMeasure -- Extracts, and possibly offets, that part of the supplied (single) LineString identified by the @p_start_measure and @p_end_measure parameters.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STSplitLineSegmentByMeasure] (
 *               @p_linestring    geometry,
 *               @p_start_measure Float,
 *               @p_end_measure   Float = null,
 *               @p_offset        Float = 0.0,
 *               @p_round_xy      int   = 3,
 *               @p_round_zm      int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given start and end measures, this function extracts a new LineString segment from the input @p_linestring.
 *    If a non-zero value is supplied for @p_offset, the extracted LineString is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *  NOTES
 *    Supports a single (2-point) LineString element only.
 *    Currently only supports Increasing measures.
 *  INPUTS
 *    @p_linestring   (geometry) - A single, 3 point, CircularString.
 *    @p_start_measure   (float) - Measure defining start point of located geometry.
 *    @p_end_measure     (float) - Measure defining end point of located geometry.
 *    @p_offset          (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy          (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm          (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    CircularString  (geometry) - New CircularString between start/end measure with optional offset.
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
 *    )
 *    select [lrs].[STSplitCircularStringByMeasure](a.linestring,0.5,2.0,0.0,3,2).AsTextZM() as split
 *      from data as a;
 *    
 *    split
 *    CIRCULARSTRING (2.537 6.524 NULL 0.5, 1.819 6.76 NULL 1.25, 1.08 6.916 NULL 2)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_wkt                varchar(max),
    @v_Dimensions         varchar(4),
    @v_round_xy           int,
    @v_round_zm           int,
    @v_start_measure      float,
    @v_end_measure        float,
    @v_measure_range      float,
    @v_z_range            float,
    @v_bearing_from_start float,
    @v_offset             float,
    @v_start_point        geometry,
    @v_end_point          geometry;
  Begin
    IF ( @p_linestring is null )
      Return NULL;
    IF ( @p_linestring.STGeometryType() <> 'LineString' )
      Return NULL;
    IF ( @p_linestring.STNumPoints() <> 2 )  -- We only handle 2 point linestrings
      Return NULL;
    IF ( @p_linestring.HasM = 0 ) -- Not a measured segment
      Return NULL;
    IF ( @p_start_measure is null and @p_end_measure is null )
      Return @p_linestring;

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset   = ISNULL(@p_offset,0.0);

    -- ****************************************
    -- Normalize up measures ....
    SET @v_start_measure = case when @p_start_measure is null 
                                then @p_linestring.STStartPoint().M
                                else @p_start_measure
                            end;
    SET @v_end_measure   = case when @p_end_measure is null 
                                then @p_linestring.STEndPoint().M
                                else case when @p_end_measure > @p_linestring.STEndPoint().M
                                          then @p_linestring.STEndPoint().M
                                          else @p_end_measure
                                      end
                            end;
    -- ****************************************

    -- Check if zero measure range  
    --
    IF ( ROUND(@v_start_measure,@v_round_zm) = ROUND(@v_end_measure,@v_round_zm) )
    BEGIN
      Return [$(lrsowner)].[STFindPointByMeasure] (
                /* @p_linestring */ @p_linestring,
                /* @p_measure    */ @v_start_measure,
                /* @p_offset     */ @v_offset,
                /* @p_round_xy   */ @v_round_xy,
                /* @p_round_zm   */ @v_round_zm
             );
    END;

    -- Compute Z/M values via simple ratio based on measure ranges...
    SET @v_measure_range = @p_linestring.STEndPoint().M - @p_linestring.STStartPoint().M;
    SET @v_z_range       = @p_linestring.STEndPoint().Z - @p_linestring.STStartPoint().Z;
    -- Compute start and end points from distances...
    -- (Common bearing)
    SET @v_bearing_from_start = [$(cogoowner)].[STBearingBetweenPoints] (
                                   @p_linestring.STStartPoint(),
                                   @p_linestring.STEndPoint()
                                );

    -- Start point will be at v_start_measure from first point...
    -- 
    IF ( ROUND(@v_start_measure,@v_round_zm) = ROUND(@p_linestring.STStartPoint().M,@v_round_zm) )
    BEGIN
      -- Ensure point ordinates are rounded 
      SET @v_start_point = geometry::STGeomFromText(
                              'POINT ('
                              +
                              [$(owner)].[STPointAsText] (
                                 @v_dimensions,
                                 @p_linestring.STStartPoint().STX,
                                 @p_linestring.STStartPoint().STY,
                                 @p_linestring.STStartPoint().Z,
                                 @p_linestring.STStartPoint().M,
                                 @v_round_xy,
                                 @v_round_xy,
                                 @v_round_zm,
                                 @v_round_zm
                              )
                              +
                              ')',
                              @p_linestring.STSrid
                           );
    END
    ELSE
    BEGIN
      -- Compute new XY coordinate by bearing/distance
      --
      SET @v_start_point = [$(cogoowner)].[STPointFromCOGO] ( 
                              @p_linestring.STStartPoint(),
                              @v_bearing_from_start,
                              @v_start_measure,
                              @v_round_xy
                           );
      -- Add Z/M to start point
      SET @v_start_point = geometry::STGeomFromText(
                              'POINT ('
                              +
                              [$(owner)].[STPointAsText] (
                                 @v_dimensions,
                                 @v_start_point.STX,
                                 @v_start_point.STY,
                                 @p_linestring.STStartPoint().Z + ( @v_z_range * ( (@v_start_measure - @p_linestring.STStartPoint().M) / @v_measure_range) ),
                                 @v_start_measure,
                                 @v_round_xy,
                                 @v_round_xy,
                                 @v_round_zm,
                                 @v_round_zm
                              )
                              +
                              ')',
                              @p_linestring.STSrid
                           );
    END;

    -- If start=end we have a single point
    -- IF ( @v_start_measure = @v_end_measure ) Return @v_start_point;

    -- Now compute End Point
    --
    IF ( ROUND(@v_end_measure,@v_round_zm) = ROUND(@p_linestring.STEndPoint().M,@v_round_zm) )
    BEGIN
      -- Ensure point ordinates are rounded 
      SET @v_end_point = geometry::STGeomFromText(
                           'POINT ('
                           +
                           [$(owner)].[STPointAsText] (
                              @v_dimensions,
                              @p_linestring.STEndPoint().STX,
                              @p_linestring.STEndPoint().STY,
                              @p_linestring.STEndPoint().Z,
                              @p_linestring.STEndPoint().M,
                              @v_round_xy,
                              @v_round_xy,
                              @v_round_zm,
                              @v_round_zm
                            )
                            +
                            ')',
                            @p_linestring.STSrid
                         );

    END
    ELSE
    BEGIN
      -- Compute new XY coordinate by bearing/distance
      --
      SET @v_end_point = [$(cogoowner)].[STPointFromCOGO] ( 
                             @p_linestring.STStartPoint(),
                             @v_bearing_from_start,
                             @v_end_measure,
                             @v_round_xy
                         );
      -- Add Z/M to start point
      SET @v_end_point = geometry::STGeomFromText(
                             'POINT ('
                             +
                             [$(owner)].[STPointAsText] (
                                @v_dimensions,
                                @v_end_point.STX,
                                @v_end_point.STY,
                                @p_linestring.STStartPoint().Z + ( @v_z_range * ( (@v_end_measure - @p_linestring.STStartPoint().M) / @v_measure_range) ),
                                @v_end_measure,
                                @v_round_xy,
                                @v_round_xy,
                                @v_round_zm,
                                @v_round_zm
                             )
                             +
                             ')',
                             @p_linestring.STSrid
                         );
    END;

    -- Now construct, possibly offset, and return new LineString
    -- 
    Return case when (@v_offset = 0.0)
                then [$(owner)].[STMakeLine] ( 
                        @v_start_point, 
                        @v_end_point,
                        @v_round_xy,
                        @v_round_zm 
                     )
                else [$(owner)].[STOffsetSegment] (
                        /* @p_linestring */ [$(owner)].[STMakeLine] (
                                               @v_start_point, 
                                               @v_end_point,
                                               @v_round_xy,
                                               @v_round_zm
                                            ),
                        /* @p_offset     */ @v_offset,
                        /* @p_round_xy   */ @v_round_xy,
                        /* @p_round_zm   */ @v_round_zm 
                    )
            end;
  End;
End
GO

Print 'Testing [$(lrsowner)].[STSplitLineSegmentByMeasure] ...';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
)
select a.linestring as linestring
  from data as a
union all
select [$(lrsowner)].[STSplitCircularStringByMeasure](a.linestring,0.5,2.0,0.0,3,2).STBuffer(0.4) as split
  from data as a;
-- **************

with data as (
  select geometry::STGeomFromText('LINESTRING(0 0 NULL 1, 10 10 NULL 15.142135623731)',0) as lString
)
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3) as start_measure, 
       round(d.lString.STLength(),3) as end_measure, 
       CAST([$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
          d.lString, 
          0.0, 
          round(d.lString.STLength(),3),
          0.0,3,2 ).AsTextZM() as varchar(80)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3)       as start_measure, 
       round(d.lString.STLength() / 3.0,3) as   end_measure,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
         d.lString, 
         0.0, 
         round(d.lString.STLength() / 3.0,3),
         0.0,3,2 ).AsTextZM()  as varchar(80)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0,3)       as start_measure, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as   end_measure,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
         d.lString, 
         round(d.lString.STLength() / 3.0, 3),
         round(d.lString.STLength() / 3.0 * 2.0,3),
         0.0,3,2 ).AsTextZM()  as varchar(80)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as start_measure, 
       round(d.lString.STLength()+1.0,3)         as end_measure,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
         d.lString, 
         d.lString.STLength() / 3.0 * 2.0, 
         round(d.lString.STLength()+1.0,3), 
         0.0,3,2 ).AsTextZM() as varchar(80)) as subString FROM data as d;
GO

