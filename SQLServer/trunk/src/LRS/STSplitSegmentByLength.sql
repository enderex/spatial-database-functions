SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))' ;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplitSegmentByLength]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSplitSegmentByLength];
  PRINT 'Dropped [$(lrsowner)].[STSplitSegmentByLength] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STSplitSegmentByLength] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSplitSegmentByLength] 
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
/****f* LRS/STSplitSegmentByLength (2012)
 *  NAME
 *    STSplitSegmentByLength -- Extracts, and possibly offets, that part of the supplied (single) LineString identified by the @p_start_length and @p_end_length parameters.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STSplitStringByLength] (
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
    @v_round_xy           int,
    @v_round_zm           int,
    @v_offset             float,
    @v_start_length       float,
    @v_mid_length         float,
    @v_end_length         float,
    @v_temp               Float,
    @v_range              Float,
    @v_z                  Float,
    @v_m                  Float,
    @v_bearing_from_start float,
    @v_angle              Float,
    @v_circle             geometry,
    @v_start_point        geometry,
    @v_mid_point          geometry,
    @v_end_point          geometry;
  Begin
    IF ( @p_linestring is null )
      Return NULL;
    IF ( @p_linestring.STGeometryType() NOT IN ('LineString','CircularString' ) )
      Return @p_linestring;
    -- We only process a single linestring segment
    IF ( @p_linestring.STGeometryType() = 'LineString' AND @p_linestring.STNumPoints() <> 2 )
      Return @p_linestring;
    -- ... Or a single CircularString
    IF ( @p_linestring.STGeometryType() = 'CircularString' AND [$(owner)].[STNumCircularStrings](@p_linestring) > 1 )
      Return @p_linestring;

    IF ( @p_start_length is null and @p_end_length is null )
      Return @p_linestring;

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;
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

  IF ( @p_linestring.STGeometryType() = 'Linestring' ) 
  BEGIN
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
  END
  ELSE
  BEGIN
    -- Processing CircularString

    IF ( @v_start_length > @p_linestring.STLength() )
      Return NULL;

    -- Get Circle Centre and Radius
    SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @p_linestring );

    -- Start point will be at v_start_length from first point...
    -- 
    SET @v_start_point = [$(lrsowner)].[STFindPointByLength] (
                             /* @p_linestring */ @p_linestring,
                             /* @p_length     */ @v_start_length,
                             /* @p_offset     */ @v_offset,
                             /* @p_round_xy   */ @v_round_xy,
                             /* @p_round_zm   */ @v_round_zm   
                         );

    -- If start=end we have a single point
    --
    IF ( @v_start_length = @v_end_length ) 
      Return @v_start_point;

    -- Now compute End Point
    --
    SET @v_end_point  = [$(lrsowner)].[STFindPointByLength] (
                           /* @p_linestring */ @p_linestring,
                           /* @p_length       */ @v_end_length,
                           /* @p_offset       */ @v_offset,
                           /* @p_round_xy     */ @v_round_xy,
                           /* @p_round_zm     */ @v_round_zm   
                       );

    -- We need to compute a mid point between the two start/end points
    -- Try and reuse existing mid point

    -- Compute subtended angle between start point and existing mid point of arc
    --
    SET @v_angle      = [$(cogoowner)].[STDegrees] (
                          [$(cogoowner)].[STSubtendedAngle] (
                           /* @p_startX  */ @p_linestring.STStartPoint().STX,
                           /* @p_startY  */ @p_linestring.STStartPoint().STY, 
                           /* @p_centreX */ @v_circle.STX,
                           /* @p_centreY */ @v_circle.STY,
                           /* @p_endX    */ @p_linestring.STPointN(2).STX,
                           /* @p_endY    */ @p_linestring.STPointN(2).STY
                         )
                        );

    -- Compute distance from start point to mid point.
    SET @v_mid_length = ABS( [$(cogoowner)].[STComputeArcLength] ( 
                              /* Radius */ @v_circle.Z,
                              /* Angle  */ @v_angle
                             )
                        );

    -- If v_mid_length is between v_start_length and v_end_length then we can reuse the existing point.
    IF ( @v_mid_length BETWEEN @v_start_length
                           AND @v_end_length )
    BEGIN
      SET @v_mid_point = @p_linestring.STPointN(2);
    END
    ELSE
    BEGIN
      -- Compute new point at mid way between start and end points
      SET @v_mid_length = @v_start_length + ((@v_end_length - @v_start_length) / 2.0);
      SET @v_mid_point  =  [$(lrsowner)].[STFindPointByLength] (
                             /* @p_linestring */ @p_linestring,
                             /* @p_length       */ @v_mid_length,
                             /* @p_offset       */ @v_offset,
                             /* @p_round_xy     */ @v_round_xy,
                             /* @p_round_zm     */ @v_round_zm
                         );
    END;

    -- Now construct and return new CircularArc
    -- 
    SET @v_wkt = 'CIRCULARSTRING(' 
                 +
                 [$(owner)].[STPointAsText] (
                     /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                     /* @p_X          */ @v_start_point.STX,
                     /* @p_Y          */ @v_start_point.STY,
                     /* @p_Z          */ @v_start_point.Z,
                     /* @p_M          */ @v_start_point.M,
                     /* @p_round_x    */ @v_round_xy,
                     /* @p_round_y    */ @v_round_xy,
                     /* @p_round_z    */ @v_round_zm,
                     /* @p_round_m    */ @v_round_zm
                 ) 
                 +
                 ', '
                 +
                 [$(owner)].[STPointAsText] (
                     /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                     /* @p_X          */ @v_mid_point.STX,
                     /* @p_Y          */ @v_mid_point.STY,
                     /* @p_Z          */ @v_mid_point.Z,
                     /* @p_M          */ @v_mid_point.M,
                     /* @p_round_x    */ @v_round_xy,
                     /* @p_round_y    */ @v_round_xy,
                     /* @p_round_z    */ @v_round_zm,
                     /* @p_round_m    */ @v_round_zm
                 ) 
                 +
                 ', '
                 +
                 [$(owner)].[STPointAsText] (
                     /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                     /* @p_X          */ @v_end_point.STX,
                     /* @p_Y          */ @v_end_point.STY,
                     /* @p_Z          */ @v_end_point.Z,
                     /* @p_M          */ @v_end_point.M,
                     /* @p_round_x    */ @v_round_xy,
                     /* @p_round_y    */ @v_round_xy,
                     /* @p_round_z    */ @v_round_zm,
                     /* @p_round_m    */ @v_round_zm
                 ) 
                 +
                 ')';
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
End;
GO


