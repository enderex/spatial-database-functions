SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))' ;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplitLineSegmentByLength]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSplitLineSegmentByLength];
  PRINT 'Dropped [$(lrsowner)].[STSplitLineSegmentByLength] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STSplitLineSegmentByLength] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSplitLineSegmentByLength] 
(
  @p_linestring   geometry,
  @p_start_length float,
  @p_end_length   float = null,
  @p_offset       float = 0.0,
  @p_round_xy     int   = 3,
  @p_round_zm     int   = 2
)
Returns geometry
As
/****f* LRS/STSplitLineSegmentByLength (2012)
 *  NAME
 *    STSplitLineSegmentByLength -- Extracts, and possibly offets, that part of the supplied (single) LineString identified by the @p_start_length and @p_end_length parameters.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STSplitCircularStringByLength] (
 *               @p_linestring   geometry,
 *               @p_start_length Float,
 *               @p_end_length   Float = null,
 *               @p_offset       Float = 0.0,
 *               @p_round_xy     int   = 3,
 *               @p_round_zm     int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given start and end lengths, this function extracts a new LineString segment from the input @p_linestring.
 *    If a non-zero value is supplied for @p_offset, the extracted LineString is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *  NOTES
 *    Supports a single (2-point) LineString element only.
 *  INPUTS
 *    @p_linestring  (geometry) - A single, 2 point, LineString.
 *    @p_start_length   (float) - Measure defining start point of located geometry.
 *    @p_end_length     (float) - Measure defining end point of located geometry.
 *    @p_offset         (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy         (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm         (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    LineString     (geometry) - New Linestring between start/end lengths with optional offset.
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
    @v_start_length       float,
    @v_end_length         float,
    @v_offset             float,
    @v_temp               Float,
    @v_range              Float,
    @v_z                  Float,
    @v_m                  Float,
    @v_round_xy           int,
    @v_round_zm           int,
    @v_bearing_from_start float,
    @v_start_point        geometry,
    @v_end_point          geometry;
  Begin
    IF ( @p_linestring is null )
      Return NULL;
    IF ( @p_linestring.STGeometryType() <> 'LineString' )
      Return NULL;
    IF ( @p_linestring.STNumPoints() <> 2 )
      Return NULL;
    IF ( @p_start_length is null and @p_end_length is null )
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset   = ISNULL(@p_offset,0.0);

    -- *********************************
    -- Normalise start/end lengths to @p_linestring lengths
    --
    SET @v_start_length = ROUND(ISNULL(@p_start_length,0.0),@v_round_xy);
    SET @v_end_length   = ROUND(case when @p_end_length is null 
                                     then @p_linestring.STLength()
                                     else case when @p_end_length > @p_linestring.STLength()
                                               then @p_linestring.STLength()
                                               else @p_end_length
                                           end
                                 end,
                                @v_round_xy
                          );
    -- Ensure distances increment...
    SET @v_temp         = case when @v_start_length < @v_end_length 
                               then @v_start_length
                               else @v_end_length
                          end;
    SET @v_end_length   = case when @v_start_length < @v_end_length 
                               then @v_end_length
                               else @v_start_length
                          end;
    SET @v_start_length = @v_temp;
    -- *********************************

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- Compute start and end points from distances...
    -- (Common bearing)
    SET @v_bearing_from_start = [$(cogoowner)].[STBearingBetweenPoints] (
                                   @p_linestring.STStartPoint(),
                                   @p_linestring.STEndPoint()
                                );

    -- Start point will be at @v_start_length from first point...
    -- 
    IF ( @v_start_length = 0.0 )
    BEGIN
      -- First point is the first point of @p_linestring
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
      -- Compute new Start Point coordinate by bearing/distance
      --
      SET @v_start_point = [$(cogoowner)].[STPointFromCogo] ( 
                              @p_linestring.STStartPoint(),
                              @v_bearing_from_start,
                              @v_start_length,
                              @v_round_xy
                           );
      -- Now compute Z and M
      SET @v_z = null;
      IF ( CHARINDEX('Z',@v_dimensions) > 0 )
      BEGIN
        SET @v_range = (@p_linestring.STEndPoint().Z - @p_linestring.STStartPoint().Z);
        SET @v_Z     = (@p_linestring.STStartPoint().Z
                       + 
                       (@v_range * (@v_start_length / @p_linestring.STLength()) ) );
      END;
      SET @v_m = null;
      IF ( CHARINDEX('M',@v_dimensions) > 0 )
      BEGIN
        SET @v_range = (@p_linestring.STEndPoint().M - @p_linestring.STStartPoint().M);
        SET @v_M     = (@p_linestring.STStartPoint().M 
                       + 
                       (@v_range * (@v_start_length / @p_linestring.STLength()) ) );
      END;
      IF ( CHARINDEX('Z',@v_dimensions) > 0 
        OR CHARINDEX('M',@v_dimensions) > 0 )
      BEGIN
        SET @v_start_point = geometry::STGeomFromText(
                              'POINT ('
                              +
                              [$(owner)].[STPointAsText] (
                                 @v_dimensions,
                                 @v_start_point.STX,
                                 @v_start_point.STY,
                                 @v_Z,
                                 @v_M,
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
    END;

    -- If start=end we have a single point
    --
    IF ( @v_start_length = @v_end_length ) 
      Return @v_start_point;

    -- Now compute End Point
    --
    IF ( @v_end_length >= @p_linestring.STLength() )
    BEGIN
      -- End point is same as @p_linestring end point
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
      SET @v_end_point = [$(cogoowner)].[STPointFromCogo] ( 
                             @p_linestring.STStartPoint(),
                             @v_bearing_from_start,
                             @v_end_length,
                             @v_round_xy
                         );
      SET @v_z = null;
      IF ( CHARINDEX('Z',@v_dimensions) > 0 )
      BEGIN
        SET @v_range = (@p_linestring.STEndPoint().Z - @p_linestring.STStartPoint().Z);
        SET @v_z     = @p_linestring.STStartPoint().Z
                       + 
                       (@v_range * (@v_end_length / @p_linestring.STLength() ));
      END;
      SET @v_m = null;
      IF ( CHARINDEX('M',@v_dimensions) > 0 )
      BEGIN
        SET @v_range = (@p_linestring.STEndPoint().M - @p_linestring.STStartPoint().M);
        SET @v_m     = @p_linestring.STStartPoint().M 
                       + 
                       (@v_range * (@v_end_length / @p_linestring.STLength() ));
      END;
      IF ( CHARINDEX('Z',@v_dimensions) > 0 
        OR CHARINDEX('M',@v_dimensions) > 0 )
      BEGIN
        SET @v_end_point = geometry::STGeomFromText(
                             'POINT ('
                             +
                             [$(owner)].[STPointAsText] (
                                   @v_dimensions,
                                   @v_end_point.STX,
                                   @v_end_point.STY,
                                   @v_Z,
                                   @v_M,
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
    END;

    -- Now construct, possibly offset, and return new LineString
    -- 
    Return case when ( @v_offset = 0.0 )
                then [$(owner)].[STMakeLine] ( 
                        @v_start_point, 
                        @v_end_point,
                        @v_round_xy,
                        @v_round_zm )
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

PRINT 'Testing [$(lrsowner)].[STSplitLineSegmentByLength] ...';
GO

with data as (
  select geometry::STGeomFromText('LINESTRING(0 0 NULL 1, 10 10 NULL 15.142135623731)',0) as lString
)
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3) as start_distance, 
       round(d.lString.STLength(),3) as end_distance, 
       CAST([$(lrsowner)].[STSplitLineSegmentByLength] ( 
          d.lString, 
          0.0, round(d.lString.STLength(),3), 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3)       as start_distance, 
       round(d.lString.STLength() / 3.0,3) as   end_distance,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByLength] ( 
         d.lString, 
         0.0, 
         round(d.lString.STLength() / 3.0,3), 0.0,3,2 ).AsTextZM()  as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0,3)       as start_distance, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as   end_distance,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByLength] ( 
         d.lString, 
         d.lString.STLength() / 3.0, 
         d.lString.STLength() / 3.0 * 2.0, 0.0,3,2 ).AsTextZM()  as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as start_distance, 
       round(d.lString.STLength()+1.0,3)         as end_distance,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByLength] ( 
         d.lString, 
         d.lString.STLength() / 3.0 * 2.0, 
         round(d.lString.STLength()+1.0,3), 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d;
GO

