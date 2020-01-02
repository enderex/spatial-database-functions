SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplitSegmentByMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSplitSegmentByMeasure];
  PRINT 'Dropped [$(lrsowner)].[STSplitSegmentByMeasure] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STSplitSegmentByMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSplitSegmentByMeasure] 
(
  @p_linestring  geometry,
  @p_start_measure float,
  @p_end_measure   float,
  @p_offset        float = 0.0,
  @p_radius_check  int   = 0,
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
Returns geometry
As
/****f* LRS/STSplitSegmentByMeasure (2012)
 *  NAME
 *    STSplitSegmentByMeasure -- Extracts, and possibly offets, that part of the supplied (single) CircularString identified by the @p_start_measure and @p_end_measure parameters.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STSplitSegmentByMeasure] (
 *               @p_linestring  geometry,
 *               @p_start_measure Float,
 *               @p_end_measure   Float = null,
 *               @p_offset        Float = 0.0,
 *               @p_radius_check  int   = 0,
 *               @p_round_xy      int   = 3,
 *               @p_round_zm      int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given start and end measures, this function extracts a new CircularString segment from the @p_linestring.
 *    If a non-zero value is suppied for @p_offset, the extracted circularSting is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *    If the circularString offset causes the CircularString to disappear, NULL is returned.
 *  NOTES
 *    Supports a single (3-point) CircularString element only.
 *    Currently only supports Increasing measures.
 *  INPUTS
 *    @p_linestring (geometry) - A single, 3 point, CircularString.
 *    @p_start_measure   (float) - Measure defining start point of located geometry.
 *    @p_end_measure     (float) - Measure defining end point of located geometry.
 *    @p_offset          (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_radius_check      (int) - If 1/2, checks offset on circular arc; If point would disappear it is kept or thrown away if 1, centre returned if 2.
 *    @p_round_xy          (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm          (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    CircularString  (geometry) - New CircularString between start/end measure with optional offset.
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
    @v_geometry_type      varchar(100),
    @v_round_xy           int,
    @v_round_zm           int,

    @v_start_measure      float,
    @v_mid_measure        float,
    @v_end_measure        float,
    @v_measure_range      float,
    @v_z_range            float,
    @v_bearing_from_start float,
    @v_offset             float,
    @v_start_point        geometry,
    @v_circle             geometry,
    @v_mid_point          geometry,
    @v_end_point          geometry,
    @v_return_geom        geometry;

    IF ( @p_linestring is null )
      Return NULL;
    SET @v_geometry_type = @p_linestring.STGeometryType();
    IF ( @v_Geometry_Type NOT IN ('LineString','CircularString') )
      Return @p_linestring;
    IF ( @v_Geometry_Type = 'LineString' AND @p_linestring.STNumPoints() <> 2 )  -- We only handle 2 point linestrings
      Return @p_linestring;
    IF ( @v_Geometry_Type = 'CircularString' AND [$(owner)].[STNumCircularStrings](@p_linestring) > 1 ) -- We only process a single CircularString
      Return @p_linestring;

    IF ( @p_linestring.HasM = 0 )                             -- And we only process measured CircularStrings
      Return @p_linestring;
    IF ( @p_start_measure is null and @p_end_measure is null )
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset   = ISNULL(@p_offset,0.0);

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;


    -- ****************************************
    -- Normalize up measures ....
    SET @v_start_measure = case when @p_start_measure is null 
                                then @p_linestring.STStartPoint().M
                                else case when @p_start_measure < @p_linestring.STStartPoint().M
                                          then @p_linestring.STStartPoint().M
                                          else @p_start_measure
                                      end
                            end;
    SET @v_end_measure   = case when @p_end_measure is null 
                                then @p_linestring.STEndPoint().M
                                else case when @p_end_measure > @p_linestring.STEndPoint().M
                                          then @p_linestring.STEndPoint().M
                                          else @p_end_measure
                                      end
                            end;
    -- ****************************************

    -- Start point will be at v_start_measure from first point...
    -- 
    SET @v_start_point = [$(lrsowner)].[STFindPointByMeasure] (
                             /* @p_linestring   */ @p_linestring,
                             /* @p_measure      */ @v_start_measure,
                             /* @p_offset       */ @v_offset,
                             /* @p_radius_check */ @p_radius_check,
                             /* @p_round_xy     */ @v_round_xy,
                             /* @p_round_zm     */ @v_round_zm   
                         );

    -- If start=end we have a single point
    --
    IF ( ROUND(@v_start_measure,@v_round_zm) = ROUND(@v_end_measure,@v_round_zm) ) 
      Return @v_start_point;

  IF ( @v_Geometry_Type = 'LineString' ) 
  BEGIN
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
    SET @v_return_geom = 
	       case when (@v_offset = 0.0)
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
  END
  ELSE
  BEGIN
    -- Get Circle Centre and Radius
    SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @p_linestring );

    -- Compute Mid Point ...
    -- If v_mid_measure is between v_start_measure and v_end_measure then we will reuse existing point.
    --
    IF ( @p_linestring.STPointN(2).M BETWEEN @v_start_measure AND @v_end_measure )
    BEGIN
      SET @v_mid_point = @p_linestring.STPointN(2);
    END
    ELSE
    BEGIN
      SET @v_mid_measure = @v_start_measure + ( (@v_end_measure - @v_start_measure) / 2.0 );
      -- Compute new point at mid way between distances
      SET @v_mid_point =  [$(lrsowner)].[STFindPointByMeasure] (
                             /* @p_linestring   */ @p_linestring,
                             /* @p_measure      */ @v_mid_measure,
                             /* @p_offset       */ @v_offset,
                             /* @p_radius_check */ @p_radius_check,
                             /* @p_round_xy     */ @v_round_xy,
                             /* @p_round_zm     */ @v_round_zm   
                         );
    END;

    -- Now compute End Point
    --
    SET @v_end_point = [$(lrsowner)].[STFindPointByMeasure] (
                           /* @p_linestring   */ @p_linestring,
                           /* @p_measure      */ @v_end_measure,
                           /* @p_offset       */ @v_offset,
                           /* @p_radius_check */ @p_radius_check,
                           /* @p_round_xy     */ @v_round_xy,
                           /* @p_round_zm     */ @v_round_zm   
                       );

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

    -- Now construct, possibly offset, and return new LineString
    -- 
    IF ( @v_offset = 0.0 )
      SET @v_return_geom = geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid)
    ELSE
      SET @v_return_geom = [$(lrsowner)].[STOffsetSegment] (
                              /* @p_linestring */ geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid),
                              /* @p_offset     */ @v_offset,
                              /* @p_round_xy   */ @v_round_xy,
                              /* @p_round_zm   */ @v_round_zm 
                            );
  END;
  Return @v_return_geom;
End;
GO
 

