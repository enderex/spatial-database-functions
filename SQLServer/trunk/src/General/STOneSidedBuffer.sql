SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STOneSidedBuffer]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STOneSidedBuffer];
  Print 'Dropped [$(owner)].[STOneSidedBuffer] ...';
END;
GO

Print 'Creating [$(owner)].[STOneSidedBuffer] ...';
GO

CREATE FUNCTION [$(owner)].[STOneSidedBuffer]
(
  @p_linestring      geometry,
  @p_buffer_distance Float,   /* -ve is left and +ve is right */
  @p_square          int = 1, /* 1 means square ends, 0 means round ends */
  @p_round_xy        int = 3,
  @p_round_zm        int = 2
)
Returns geometry
AS
/****m* GEOPROCESSING/STOneSidedBuffer (2012)
 *  NAME
 *    STOneSidedBuffer -- Creates a square buffer to left or right of a linestring.
 *  SYNOPSIS
 *    Function STOneSidedBuffer (
 *                @p_linestring      geometry,
 *                @p_buffer_distance Float, 
 *                @p_square          int = 1, 
 *                @p_round_xy        int = 3,
 *                @p_round_zm        int = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a square buffer to left or right of a linestring.
 *    To create a buffer to the LEFT of the linestring (direction start to end) supply a negative p_buffer_distance; 
 *    a +ve value will create a buffer on the right side of the linestring.
 *    Square ends can be created by supplying a positive value to @p_square parameter. 
 *    A value of 0 will create a rounded end at the start or end point.
 *    Where the linestring either crosses itself or starts and ends at the same point, the result may not be as expected.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision.
 *    Support for Z and M ordinates is experimental: where supported the final geometry has its ZM ordinates rounded to @p_round_zm of precision.
 *  NOTES
 *    Supports circular strings and compoundCurves.
 *    Is a 2D function, so any Z and M ordinates are lost.
 *    Only supports single linestrings like LineString, CircularString and CompoundCurve.
 *    Is an input linestring is not Simple (geomSTIsSimple()=0) the results will most likely be wrong.
 *    Complex linestrings and large offset distances will most likely not return a clean result due to the nature of the algorithm
 *  TOBEDONE
 *    Better handling of non Simple linestrings.
 *    Create implementation based on linear offsets.
 *  INPUTS
 *    @p_linestring (geometry) - Must be a linestring geometry.
 *    @p_distance   (float)    - if < 0 then left side buffer; if > 0 then right sided buffer.
 *    @p_square     (int)      - 0 = no (round mitre); 1 = yes (square mitre)
 *    @p_round_xy   (int)      - Rounding factor for XY ordinates.
 *    @p_round_zm   (int)      - Rounding factor for ZM ordinates.
 *  RESULT
 *    polygon       (geometry) - Result of one sided buffering of a linestring.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding (Oracle).
 *    Simon Greener - Nov 2017 - Original coding for SQL Server.
 *    Simon Greener - Oct 2019 - Improvements to handle disppearing segments.
 *  COPYRIGHT
 *    (c) 2012-2019 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
******/
BEGIN
  DECLARE
    @v_wkt              varchar(max),
    @v_GeometryType     varchar(100),
    @v_srid             int,
    @v_square           int,
    @v_round_xy         int,
    @v_round_zm         int,

    @v_buffer_distance  float = ABS(@p_buffer_distance),
    @v_buffer_increment float,
    @v_line_extension_distance float,

    @v_radius           float,
    @v_sign             int, /* -1 left/+1 right */
    @v_isCCW            int,
    @v_ccw_linestring   int,
    @v_GeomN            int,
    @v_numGeoms         int,
    @v_NumPoints        int,
    @v_minId            int,
    @v_maxId            int,
    @v_bearing          float,
    @v_distance         float,
    @v_which            varchar(1),

    @v_line_remove      geometry,
    @v_linestring       geometry,
    @v_start_linestring geometry,
    @v_end_linestring   geometry,
    @v_point            geometry,
    @v_circle           geometry,
    @v_split_geom       geometry,
    @v_side_geom        geometry,
    @v_buffer_ring      geometry,
    @v_shortest_line_to geometry,
    @v_extension_line   geometry,
    @v_buffer           geometry;

  If ( @p_linestring is null )
    Return @p_linestring;

  If ( ISNULL(ABS(@p_buffer_distance),0.0) = 0.0 )
    Return @p_linestring;

  SET @v_GeometryType = @p_linestring.STGeometryType();

  -- MultiLineString Supported by alternate processing.
  IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
    Return @p_linestring;

  SET @v_srid    = @p_linestring.STSrid;
  SET @v_square  = case when ISNULL(@p_square,1) >= 1 then 1 else 0 end;
  SET @v_sign    = SIGN(@p_buffer_distance);

  SET @v_round_xy                = ISNULL(@p_round_xy,3);
  SET @v_round_zm                = ISNULL(@p_round_zm,2);
  SET @v_buffer_distance         = ABS(@p_buffer_distance);
  SET @v_buffer_increment        = 1.0/POWER(10,@v_round_xy-1);
  SET @v_line_extension_distance = 1.0/POWER(10,@v_round_xy+1) * 2.0;

  -- We only support 2D 
  SET @v_linestring = [$(owner)].[STRound](
                         case when [$(owner)].[STCoordDim](@p_linestring.STStartPoint()) > 2
                              then [$(owner)].[STTo2D](@p_linestring)
                              else @p_linestring
                          end,
                         @v_round_xy-1,
                         @v_round_xy-1,
                         @v_round_zm-1,
                         @v_round_zm-1
                      );

  -- #############################################################################################

  -- LinearRing
  --   Take another route to the side buffer
  --
  IF ( @v_linestring.STStartPoint().STEquals(@v_linestring.STEndPoint())=1
      OR [$(owner)].[STEquals] ( 
             @v_linestring.STPointN(1),
             @v_linestring.STPointN(@v_linestring.STNumPoints()),
             @v_round_xy,
             @v_round_zm,
             @v_round_zm ) = 1 )
  BEGIN
    SET @v_buffer     = @v_linestring.STBuffer(ABS(@v_buffer_distance));
    SET @v_split_geom = @v_buffer.STDifference(@v_linestring.STBuffer(@v_buffer_increment));

    IF ( @v_split_geom.STNumGeometries() <= 1 )
      return @v_split_geom;

    -- Find out which of the split left/right polygons is the one we want.
    --
    SET @v_start_linestring = [$(owner)].[STMakeLine] ( @v_linestring.STPointN(1),@v_linestring.STPointN(2),@v_round_xy,@v_round_zm);

    SET @v_point = [$(owner)].[STOffsetPoint] (
                      @v_start_linestring,
                      0.1,
                      @p_buffer_distance/10.0,
                      @v_round_xy,
                      @v_round_zm,
                      @v_round_zm
                   );

    SET @v_GeomN = 1;
    WHILE ( @v_GeomN <= @v_split_geom.STNumGeometries() )
    BEGIN
      IF ( @v_split_geom.STGeometryN(@v_GeomN).STContains(@v_point) = 1 )
      BEGIN
        SET @v_side_geom = @v_split_geom.STGeometryN(@v_GeomN);
        BREAK;
      END;
      SET @v_GeomN = @v_GeomN + 1;
    END;

    -- STRound removes @v_buffer_increment sliver trick that would otherwise be left behind in the data.
    SET @v_side_geom = [$(owner)].[STRound] ( 
                         case when @v_side_geom is null then @v_split_geom else @v_side_geom end,
                         @v_round_xy,
                         @v_round_xy,
                         @v_round_zm,
                         @v_round_zm
                     );
    Return  @v_side_geom;
  END;

  -- #######################################################################################

  -- Get linestring with disappearing start/segments removed.
  --
  SET @v_NumPoints = @v_linestring.STNumPoints();

  SET @v_line_remove = [$(owner)].[STRemoveOffsetSegments] (
                           @v_linestring,
                           @p_buffer_distance,
                           @v_round_xy, 
                           @v_round_zm 
                         );
  IF ( @v_line_remove is null OR @v_line_remove.STIsEmpty() = 1)
    return @p_linestring;  -- Both linestrings have disappeared

  IF ( @v_line_remove.STGeometryType() = 'GeometryCollection' )
    return @p_linestring;  -- Both linestrings have disappeared

  IF ( @v_NumPoints <> @v_line_remove.STNumPoints() )
    SET @v_linestring = @v_line_remove;

  SET @v_GeometryType = @v_linestring.STGeometryType();

  -- #######################################################################################

  SET @v_buffer      = [$(owner)].[STRound](
                          @v_linestring.STBuffer(@v_buffer_distance),
                          @v_round_xy,
                          @v_round_xy,
                          @v_round_zm,
                          @v_round_zm
                       );

  SET @v_buffer_ring = @v_buffer.STExteriorRing();

  IF ( @v_GeometryType = 'CompoundCurve' )
  BEGIN
    SET @v_start_linestring = @v_linestring.STCurveN(1);
    SET @v_end_linestring   = @v_linestring.STCurveN(@v_linestring.STNumCurves());
  END
  ELSE
  BEGIN
    IF ( @v_GeometryType = 'CircularString' )
    BEGIN
      SET @v_start_linestring = [$(owner)].[STCircularStringN](@v_linestring,1);
      SET @v_end_linestring   = [$(owner)].[STCircularStringN](
                                    @v_linestring,
                                    [$(owner)].[STNumCircularStrings](@v_linestring)
                                );
    END
    ElSE
    BEGIN
      SET @v_start_linestring = [$(owner)].[STMakeLine](
                                    @v_linestring.STPointN(1),
                                    @v_linestring.STPointN(2),
                                    @v_round_xy,@v_round_zm
                                );
      SET @v_end_linestring   = case when @v_linestring.STNumPoints() = 2
                                     then @v_linestring
                                     else [$(owner)].[STMakeLine](
                                             @v_linestring.STPointN(@v_linestring.STNumPoints()-1),
                                             @v_linestring.STPointN(@v_linestring.STNumPoints()),
                                             @v_round_xy,@v_round_zm
                                          )
                                 end;
    END;
  END;

  -- #######################################################################################

  -- Create splitting lines at either end at 90 degrees to line direction if square else straight extension.
  -- 

  -- ******************** START OF LINE PROCESSING *************************

  -- Create one sided with round fillet first
  -- Leave Square till later.
  --
  IF ( @v_start_linestring.STGeometryType() = 'LineString' ) 
  BEGIN
    -- Extend original line at start on right or left side of line segment 
    -- depending on sign of offset at 90 degrees to direction of segment
    -- 
    SET @v_bearing = [$(cogoowner)].[STBearingAlongLine](@v_start_linestring);
    SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (@v_bearing + case when @v_square = 1 then (@v_sign * 90.0) else 180.0 end);
    SET @v_distance = @v_buffer_distance + @v_line_extension_distance;
  END;

  IF ( @v_start_linestring.STGeometryType() = 'CircularString' ) 
  BEGIN
    IF ( @v_square = 1 )
    BEGIN     
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_start_linestring );

      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
        Return @v_buffer;

      SET @v_radius = @v_circle.STStartPoint().Z;

      -- Make circle a 2D point (throw away radius)
      -- Keep Z and M of actual start point of linestring
      SET @v_circle = geometry::Point(
                        @v_circle.STStartPoint().STX,
                        @v_circle.STStartPoint().STY,
                        @v_srid
                      );
      -- Line from centre to v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- Bearing has to be computed in reference to the side of the line the polygon is to be created.
      --
      SET @v_which   = [$(owner)].[STWhichSide](@v_start_linestring,@v_circle,@v_round_xy);
      IF ( @v_which = 'L' )
      BEGIN
        SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (
                           case when @v_sign < 0 
                                then [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_start_linestring.STStartPoint(),
                                        @v_circle
                                     )
                                else [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_circle,
                                        @v_start_linestring.STStartPoint()
                                     )
                           end
                          );
        SET @v_distance = case when @v_sign < 0 
                               then @v_buffer_distance + @v_line_extension_distance
                               else @v_radius + @p_buffer_distance + @v_line_extension_distance
                           end;
      END ;
      IF ( @v_which = 'R' )
      BEGIN
        SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (
                           case when @v_sign < 0 
                                then [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_circle,
                                        @v_start_linestring.STStartPoint()
                                     )
                                else [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_start_linestring.STStartPoint(),
                                        @v_circle
                                      )
                            end
                         );
       SET @v_distance = case when @v_sign < 0 
                              then @v_radius + @v_buffer_distance + @v_line_extension_distance
                              else @v_buffer_distance + @v_line_extension_distance
                          end;
      END
    END
    ELSE
    BEGIN -- @v_square = 1
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (
                         [$(cogoowner)].[STBearingBetweenPoints](
                           [$(cogoowner)].[STComputeTangentPoint] (
                              @v_start_linestring,
                              'START',
                              @v_round_xy
                           ),
                           @v_start_linestring.STStartPoint()
                         )
                       );
      SET @v_distance = @v_buffer_distance + @v_line_extension_distance;
    END;
  END;

  -- ******************
  -- Common Start Code
  -- ******************

  BEGIN
    -- create initial new extension point using buffer distance + increment
    -- Function rounds ordinates
    SET @v_point = [$(cogoowner)].[STPointFromCOGO] ( 
                       @v_start_linestring.STStartPoint(),
                       @v_bearing,
                       @v_distance,
                       @v_round_xy
                   );
    -- STMakeLine rounds ordinates
    SET @v_extension_line = [$(owner)].[STMakeLine] (
                               @v_point,
                               @v_start_linestring.STStartPoint(),
                               @p_round_xy,
                               @p_round_zm
                            );

    -- Create extended linestring by appending extension line to @v_linestring
    SET @v_linestring = [$(owner)].[STAppend] (
                            @v_extension_line,
                            @v_linestring,
                            @p_round_xy,
                            @p_round_zm
                         );
  END;

  -- ******************** END OF START LINE PROCESSING *************************
  -- ###########################################################################
  -- ******************** START OF END LINE PROCESSING *************************

  -- LineString processing first.
  --
  IF  ( @v_end_linestring.STGeometryType() = 'LineString' )  
  BEGIN
    -- Now Extend at end
    -- 
    SET @v_NumPoints = @v_end_linestring.STNumPoints();
    SET @v_bearing   = [$(cogoowner)].[STBearingAlongLine](@v_end_linestring);
    SET @v_bearing   = [$(cogoowner)].[STNormalizeBearing] ( @v_bearing + case when @v_square = 1 then (@v_sign * 90.0) else 0.0 end);
    SET @v_distance  = @v_buffer_distance + @v_line_extension_distance;
  END;

  IF  ( @v_end_linestring.STGeometryType() = 'CircularString' ) 
  BEGIN
    IF ( @v_square = 1 )
    BEGIN     
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_end_linestring );

      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
        Return @v_buffer;

      SET @v_radius = @v_circle.STStartPoint().Z;

      -- Make circle a 2D point (throw away radius)
      -- Keep Z and M of actual start point of linestring
      SET @v_circle = geometry::Point(
                         @v_circle.STStartPoint().STX,
                         @v_circle.STStartPoint().STY,
                         @v_srid
                      );

      -- Line from @v_centre to @v_end_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_which   = [$(owner)].[STWhichSide](@v_end_linestring,@v_circle,@v_round_xy);
      IF ( @v_which = 'L' )
      BEGIN
        SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (
                           case when @v_sign < 0 
                                then [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_end_linestring.STEndPoint(),
                                        @v_circle
                                     )
                                else [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_circle,
                                        @v_end_linestring.STEndPoint()
                                     )
                            end
                           );
         SET @v_distance = case when @v_sign < 0 
                                then @v_buffer_distance + @v_line_extension_distance
                                else @v_radius + @v_buffer_distance + @v_line_extension_distance
                            end;
      END ;
      IF ( @v_which = 'R' )
      BEGIN
        SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (
                           case when @v_sign < 0 
                                then [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_circle,
                                        @v_end_linestring.STEndPoint()
                                     )
                                else [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_end_linestring.STEndPoint(),
                                        @v_circle
                                      )
                            end
                           );
         SET @v_distance = case when @v_sign < 0 
                                then @v_radius + @v_buffer_distance + @v_line_extension_distance
                                else @v_buffer_distance + @v_line_extension_distance
                            end;
      END
    END
    ELSE
    BEGIN -- @v_square = 1
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (
                         [$(cogoowner)].[STBearingBetweenPoints](
                           [$(cogoowner)].[STComputeTangentPoint] (
                              @v_end_linestring,
                              'END',
                              @v_round_xy
                           ),
                           @v_end_linestring.STEndPoint()
                         )
                       );
      SET @v_distance = @v_buffer_distance + @v_line_extension_distance;
    END;
  END;

  -- ******************
  -- Common processing
  -- ******************

  BEGIN
    -- Create and add new segment to existing linestring...

    -- Compute end point near buffer exterior ring
    -- Function rounds ordinates
    SET @v_point = [$(cogoowner)].[STPointFromCOGO] ( 
                        @v_end_linestring.STEndPoint(),
                        @v_bearing,
                        @v_distance,
                        @v_round_xy
                   );

    -- Function rounds ordinates
    SET @v_extension_line = [$(owner)].[STMakeLine] (
                               @v_end_linestring.STEndPoint(),
                               @v_point,
                               @p_round_xy,
                               @p_round_zm
                            );
    -- Create extended linestring by appending extension line to @v_linestring
    SET @v_linestring = [$(owner)].[STAppend] (
                          @v_linestring,
                          @v_extension_line,
                          @p_round_xy,
                          @p_round_zm
                        );
  END;

  -- #########################################################################################
  -- #########################################################################################
  -- Now, split buffer with modified linestring (using buffer trick) to generate two polygons
  --

  SET @v_split_geom = @v_buffer.STDifference(@v_linestring.STBuffer(@v_buffer_increment)); 

  -- Find out which of the split left/right polygons is the one we want.
  --
  SET @v_point = [$(owner)].[STOffsetPoint] (
                    @v_start_linestring,
                    0.5,
                    @p_buffer_distance * 0.1,
                    @v_round_xy,
                    @v_round_zm,
                    @v_round_zm
                 );

  SET @v_GeomN = 1;
  SET @v_numGeoms = @v_split_geom.STNumGeometries();
  WHILE ( @v_GeomN <= @v_numGeoms )
  BEGIN
    IF ( @v_split_geom.STGeometryN(@v_GeomN).STContains(@v_point) = 1 )
    BEGIN
      SET @v_side_geom = @v_split_geom.STGeometryN(@v_GeomN);
      BREAK;
    END;
    SET @v_GeomN = @v_GeomN + 1;
  END;

  -- #########################################################################################

  -- STRound removes @v_buffer_increment sliver trick that would otherwise be left behind in the data.
  --
  SET @v_side_geom = [$(owner)].[STRound] ( 
                         case when @v_side_geom is null then @v_split_geom else @v_side_geom end,
                         @v_round_xy,
                         @v_round_xy,
                         @v_round_zm,
                         @v_round_zm
                     );
  Return case when @v_side_geom.STIsValid()=0 
              then @v_side_geom.MakeValid() 
              else @v_side_geom 
          end;
End;
GO

