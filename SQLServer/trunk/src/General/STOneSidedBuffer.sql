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
Returns @results table (tag varchar(1000),geom geometry)
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
    @v_dimensions       varchar(4),
    @v_square           int,
    @v_round_xy         int,
    @v_round_zm         int,
    @v_buffer_distance  float = ABS(@p_buffer_distance),
    @v_buffer_increment float,
    @v_radius           float,
    @v_sign             int, /* -1 left/+1 right */
    @v_GeomN            int,
    @v_NumPoints        int,
    @v_minId            int,
    @v_maxId            int,
    @v_bearing          float,
    @v_distance         float,
    @v_which            varchar(1),
    @v_line1            geometry,
    @v_line2            geometry,
    @v_linestring       geometry,
    @v_start_linestring geometry,
    @v_end_linestring   geometry,
    @v_point            geometry,
    @v_epoint           geometry,
    @v_circle           geometry,
    @v_split_geom       geometry,
    @v_side_geom        geometry,
    @v_buffer_ring      geometry,
    @v_shortest_line_to geometry,
    @v_extension_line   geometry,
    @v_buffer           geometry;
  Begin
    If ( @p_linestring is null )
      --Return @p_linestring;
begin insert into @results values('test1',@p_linestring); return; end;

    If ( ISNULL(ABS(@p_buffer_distance),0.0) = 0.0 )
begin insert into @results values('test2',@p_linestring); return; end;

--      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
begin insert into @results values('test3',@p_linestring); return; end;
--      Return @p_linestring;

    SET @v_round_xy   = ISNULL(@p_round_xy,3);
    SET @v_round_zm   = ISNULL(@p_round_zm,2);
    SET @v_square     = case when ISNULL(@p_square,1) >= 1 then 1 else 0 end;
    SET @v_dimensions = 'XY' 
                        + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                        + case when @p_linestring.HasM=1 then 'M' else '' end;
    SET @v_sign       = SIGN(@p_buffer_distance);
    -- SET @v_buffer_distance  = ROUND(ABS(@p_buffer_distance) * 1.1,@v_round_xy+1);
    SET @v_buffer_distance  = ROUND(ABS(@p_buffer_distance),@v_round_xy);
    SET @v_buffer_increment = 1.0/POWER(10,@v_round_xy+1)*2.0;

    -- If @p_linestring is a closed ring, use polygon outer ring processing
    -- STEquals with precision
    --
    IF ( @p_linestring.STStartPoint().STEquals(@p_linestring.STEndPoint())=1
      OR [$(owner)].[STEquals] ( 
             @p_linestring.STStartPoint(),
             @p_linestring.STEndPoint(),
             @v_round_xy,
             @v_round_zm,
             @v_round_zm ) = 1 )
    BEGIN
      -- Try and convert to polygon with single outer ring
      SET @v_wkt  = case when @v_GeometryType = 'LineString'
                         then REPLACE(@p_linestring.AsTextZM(),'LINESTRING (','POLYGON ((') + ')'
                         when @v_geometryType = 'CompoundCurve'
                         then 'CURVEPOLYGON (' + @p_linestring.AsTextZM() + ')'
                         when @v_geometryType = 'CircularString' 
                         then 'CURVEPOLYGON (' + @p_linestring.AsTextZM() + ')'
                    end;

      -- Ring rotation should be considered
      -- +ve Buffer outside, -ve buffer inside, so reverse
      SET @v_split_geom = geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid).MakeValid();
      SET @v_buffer     = @v_split_geom.STBuffer(@v_buffer_distance).STSymDifference(@v_split_geom);
insert into @results values('LinearRing',@v_buffer); 
      Return; -- @v_buffer;
    END;

    -- **********************************************************************************
    -- Get start and end segments that don't disappear.
    SET @v_NumPoints = @v_linestring.STNumPoints();
insert into @results values('NumPopints before '+CAST(@v_numPoints as varchar(50)),NULL); 
    SET @v_linestring  = [$(owner)].[STRemoveOffsetSegments] (
                           @p_linestring,
                           @v_buffer_distance,
                           @v_round_xy, 
                           @v_round_zm 
                         );
insert into @results values('Result of removeOffsetSegments NumPoints'+CAST(@v_linestring.STNumPoints() as varchar(50)),@v_linestring);

    IF ( @v_linestring is null or @v_linestring.STIsEmpty()=1)
    begin insert into @results values('Input linestring has disappeared',@v_linestring); return; end;
       -- return @p_linestring;  -- Both linestrings have disappeared

    IF ( @v_NumPoints = @v_linestring.STNumPoints() )
     SET @v_linestring = @p_linestring;
insert into @results values('Input linestring after RemoveOffsetSegments NumPoints',@v_linestring); 

    SET @v_GeometryType = @v_linestring.STGeometryType();

    -- **********************************************************************************

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
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + case when @v_square = 1 then (@v_sign * 90.0) else 180.0 end
                       );
      SET @v_distance = @v_buffer_distance + @v_buffer_increment;
    END;

    IF ( @v_start_linestring.STGeometryType() = 'CircularString') 
    BEGIN
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_start_linestring );
      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
begin insert into @results values('No Circle found',@v_buffer); return; end;
--        RETURN @v_buffer;
      SET @v_radius = @v_circle.STStartPoint().Z;
      -- Make circle a 2D point (throw away radius)
      -- Keep Z and M of actual start point of linestring
      SET @v_circle = geometry::Point(
                        @v_circle.STStartPoint().STX,
                        @v_circle.STStartPoint().STY,
                        @p_linestring.STSrid
                      );
      -- Line from centre to v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- Bearing has to be computed in reference to the side of the line the polygon is to be created.
      --
      SET @v_which   = [$(owner)].[STWhichSide](@v_start_linestring,@v_circle,@v_round_xy);
      IF ( @v_which = 'L' )
      BEGIN
        SET @v_bearing = case when @v_sign < 0 
                              then [$(cogoowner)].[STBearingBetweenPoints] (
                                      @v_start_linestring.STStartPoint(),
                                      @v_circle
                                   )
                              else [$(cogoowner)].[STBearingBetweenPoints] (
                                      @v_circle,
                                      @v_start_linestring.STStartPoint()
                                   )
                         end;
         SET @v_distance = case when @v_sign < 0 
                                then @v_buffer_distance + @v_buffer_increment
                                else @v_radius + @p_buffer_distance + @v_buffer_increment
                            end;
      END ;
      
      IF ( @v_which = 'R' )
      BEGIN
          SET @v_bearing = case when @v_sign < 0 
                                then [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_circle,
                                        @v_start_linestring.STStartPoint()
                                     )
                                else [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_start_linestring.STStartPoint(),
                                        @v_circle
                                      )
                            end;
         SET @v_distance = case when @v_sign < 0 
                                then @v_radius + @v_buffer_distance + @v_buffer_increment
                                else @v_buffer_distance + @v_buffer_increment
                            end;
      END ;
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + case when @v_square = 1 then 0.0 else (@v_sign * 90.0) end
                       );
    END;

    -- ******************
    -- Common Start Code
    -- ******************

    BEGIN

      -- create initial new extension point using buffer distance + increment
      SET @v_point = [$(cogoowner)].[STPointFromCOGO] ( 
                         @v_start_linestring.STStartPoint(),
                         @v_bearing,
                         @v_distance,
                         @v_round_xy
                     );

      -- Ensure has ZM ordinates of the start linestring's start point
      SET @v_point = geometry::STGeomFromText(
                        'POINT (' + 
                        [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_point.STX,
                            /* @p_Y          */ @v_point.STY,
                            /* @p_Z          */ @v_start_linestring.STStartPoint().Z,
                            /* @p_M          */ @v_start_linestring.STStartPoint().M,
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                        )
                        +
                        ')',
                        @p_linestring.STSrid
                      );

      -- Test calculated point and adjust if does not fall on buffer line 
      -- Test if end point is on/near buffer line (or will return single - intersection - point)
      --
      SET @v_shortest_line_to = [$(owner)].[STRound](
                                   @v_point.ShortestLineTo(@v_buffer_ring),
                                   @v_round_xy,
                                   @v_round_xy,
                                   @v_round_zm,
                                   @v_round_zm
                                );

      IF ( @v_shortest_line_to.STGeometryType() = 'Point' OR @v_shortest_line_to.STIsEmpty() = 1 )
      BEGIN
        SET @v_extension_line = [$(owner)].[STMakeLine] (
                                 @v_point,
                                 @v_start_linestring.STStartPoint(),
                                 @p_round_xy,
                                 @p_round_zm
                              );
      END
      ELSE
      BEGIN
        -- Construct extended line from start point and and end point actually on the buffer
        --
        SET @v_epoint = geometry::STGeomFromText(
                          'POINT (' + 
                          [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_shortest_line_to.STEndPoint().STX,
                            /* @p_Y          */ @v_shortest_line_to.STEndPoint().STY,
                            /* @p_Z          */ @v_start_linestring.STStartPoint().Z,
                            /* @p_M          */ @v_start_linestring.STStartPoint().M,
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                          )
                          +
                          ')',
                          @p_linestring.STSrid
                        );

        SET @v_extension_line = [$(owner)].[STMakeLine] (
                                 @v_epoint,
                                 @v_start_linestring.STStartPoint(),
                                 @p_round_xy,
                                 @p_round_zm
                              );

      END;

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
      SET @v_bearing   = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_end_linestring.STPointN(@v_numPoints-1),
                            @v_end_linestring.STPointN(@v_NumPoints)
                         );

      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + case when @v_square = 1 then (@v_sign * 90.0) else 0.0 end
                       );

      SET @v_distance = @v_buffer_distance + @v_buffer_increment;

    END;

    IF  ( @v_end_linestring.STGeometryType() = 'CircularString' ) 
    BEGIN
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_end_linestring );
      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
begin insert into @results values('No Circle2 found',@v_buffer); return; end;
        --RETURN @v_buffer;
      SET @v_radius = @v_circle.STStartPoint().Z;
      -- Make circle a 2D point (throw away radius)
      -- Keep Z and M of actual start point of linestring
      SET @v_circle = geometry::Point(
                         @v_circle.STStartPoint().STX,
                         @v_circle.STStartPoint().STY,
                         @p_linestring.STSrid
                      );

      -- Line from @v_centre to @v_end_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_which   = [$(owner)].[STWhichSide](@v_end_linestring,@v_circle,@v_round_xy);
      IF ( @v_which = 'L' )
      BEGIN
        SET @v_bearing = case when @v_sign < 0 
                              then [$(cogoowner)].[STBearingBetweenPoints] (
                                      @v_end_linestring.STEndPoint(),
                                      @v_circle
                                   )
                              else [$(cogoowner)].[STBearingBetweenPoints] (
                                      @v_circle,
                                      @v_end_linestring.STEndPoint()
                                   )
                         end;
         SET @v_distance = case when @v_sign < 0 
                                then @v_buffer_distance + @v_buffer_increment
                                else @v_radius + @v_buffer_distance + @v_buffer_increment
                            end;
      END ;
      
      IF ( @v_which = 'R' )
      BEGIN
          SET @v_bearing = case when @v_sign < 0 
                                then [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_circle,
                                        @v_end_linestring.STEndPoint()
                                     )
                                else [$(cogoowner)].[STBearingBetweenPoints] (
                                        @v_end_linestring.STEndPoint(),
                                        @v_circle
                                      )
                            end;
         SET @v_distance = case when @v_sign < 0 
                                then @v_radius + @v_buffer_distance + @v_buffer_increment
                                else @v_buffer_distance + @v_buffer_increment
                            end;
      END ;

      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + case when @v_square = 1 then 0.0 else (@v_sign * 90.0) end
                       );

    END;

    -- ******************
    -- Common processing
    -- ******************

    BEGIN

      -- Create and add new segment to existing linestring...
      --
      -- Compute end point near buffer exterior ring
      --
      SET @v_point = [$(cogoowner)].[STPointFromCOGO] ( 
                          @v_end_linestring.STEndPoint(),
                          @v_bearing,
                          @v_distance,
                          @v_round_xy
                     );

      -- Ensure has all ordinates of end linestring
      SET @v_point = geometry::STGeomFromText(
                        'POINT (' + 
                        [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_point.STX,
                            /* @p_Y          */ @v_point.STY,
                            /* @p_Z          */ @v_end_linestring.STEndPoint().Z,
                            /* @p_M          */ @v_end_linestring.STEndPoint().M,
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                        )
                        +
                        ')',
                        @p_linestring.STSrid
                      );

      -- Test calculated point and adjust if dowes not fall on buffer line 
      -- Test if end point is on/near buffer line (on will return single - intersection - point)
      --
      SET @v_shortest_line_to = [$(owner)].[STRound](
                                   @v_point.ShortestLineTo(@v_buffer_ring),
                                   @v_round_xy,
                                   @v_round_xy,
                                   @v_round_zm,
                                   @v_round_zm
                                );

      IF ( @v_shortest_line_to.STGeometryType() = 'Point'  OR @v_shortest_line_to.STIsEmpty() = 1 )
      BEGIN
        SET @v_extension_line = [$(owner)].[STMakeLine] (
                                 @v_end_linestring.STEndPoint(),
                                 @v_point,
                                 @p_round_xy,
                                 @p_round_zm
                            );
      END
      ELSE
      BEGIN
        -- Construct extended line from start point and and end point actually on the buffer
        --
        SET @v_epoint = geometry::STGeomFromText(
                          'POINT (' + 
                          [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_shortest_line_to.STEndPoint().STX,
                            /* @p_Y          */ @v_shortest_line_to.STEndPoint().STY,
                            /* @p_Z          */ @v_end_linestring.STEndPoint().Z,
                            /* @p_M          */ @v_end_linestring.STEndPoint().M,
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                          )
                          +
                          ')',
                          @p_linestring.STSrid
                        );

        SET @v_extension_line = [$(owner)].[STMakeLine] (
                                  @v_end_linestring.STEndPoint(),
                                  @v_epoint,
                                  @p_round_xy,
                                  @p_round_zm
                               );

      END;
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

insert into @results values([$(owner)].[STDetermine](@v_linestring,@v_buffer),NULL);

insert into @results values('v_linestring.STLength=' + CAST(@v_linestring.STLength() as varchar(100)),@v_linestring);

insert into @results values('Extended linestring Buffered ('+CAST(@v_buffer_increment as varchar(100))+')',@v_linestring.STBuffer(@v_buffer_increment));

    SET @v_split_geom = @v_buffer.STDifference(@v_linestring.STBuffer(@v_buffer_increment));  -- /10.0));

insert into @results values('@v_split_geom ('+CAST(@v_split_geom.STNumGeometries() as varchar(10))+')',@v_split_geom);

IF ( @v_split_geom.STNumGeometries() = 1 )
BEGIN
insert into @results values('@v_split_geom/linestring distance ='+CAST(@v_linestring.STEndPoint().ShortestLineTo(@v_split_geom).STLength() as varchar(100))+')',@v_split_geom);
END;
    -- Find out which of the split left/right polygons is the one we want.
    --
    SET @v_point = [$(owner)].[STOffsetPoint] (
                      @v_start_linestring,
                      0.5,
                      @p_buffer_distance/10.0,
                      @v_round_xy,
                      @v_round_zm,
                      @v_round_zm
                   );
insert into @results values('@v_check_point',@v_point);

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

insert into @results values('@v_side_geom',@v_side_geom);

    -- #########################################################################################
    -- STRound removes @v_buffer_increment sliver trick that would otherwise be left behind in the data.
    SET @v_side_geom = [$(owner)].[STRound] ( 
                           case when @v_side_geom is null then @v_split_geom else @v_side_geom end,
                           @v_round_xy,
                           @v_round_xy,
                           @v_round_zm,
                           @v_round_zm
                       );
--    insert into @results values('End ',@v_side_geom.MakeValid());
 return;
    /*
    Return case when @v_side_geom.STIsValid()=0 
                then @v_side_geom.MakeValid() 
                else @v_side_geom 
            end;
    */
  End;
End;
GO

