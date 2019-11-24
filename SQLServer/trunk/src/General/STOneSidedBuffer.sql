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
/****f* GEOPROCESSING/STOneSidedBuffer (2012)
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
    @v_square           int = case when ISNULL(@p_square,1) >= 1 then 1 else 0 end,
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
    @v_linestring       geometry,
    @v_start_linestring geometry,
    @v_end_linestring   geometry,
    @v_circular_string  geometry,
    @v_point            geometry,
    @v_circle           geometry,
    @v_split_geom       geometry,
    @v_side_geom        geometry,
    @v_buffer_ring      geometry,
    @v_shortest_line_to geometry,
    @v_extension_line   geometry,
    @v_buffer           geometry;
  Begin
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( ISNULL(ABS(@p_buffer_distance),0.0) = 0.0 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- Create buffer around linestring.
    SET @v_sign             = SIGN(@p_buffer_distance);
    -- SET @v_buffer_distance  = ROUND(ABS(@p_buffer_distance) * 1.1,@v_round_xy+1);
    SET @v_buffer_distance  = ROUND(ABS(@p_buffer_distance),@v_round_xy+1);
    SET @v_buffer_increment = ROUND(1.0/POWER(10,@v_round_xy+1)*5.0,@v_round_xy+1);

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
      IF ( @v_GeometryType = 'LineString' )
        SET @v_wkt    = REPLACE(@p_linestring.AsTextZM(),'LINESTRING (','POLYGON ((') + ')'
      ELSE IF @v_geometryType = 'CompoundCurve'
        SET @v_wkt    = 'CURVEPOLYGON (' + @p_linestring.AsTextZM() + ')'
      ELSE IF @v_geometryType = 'CircularString' 
        SET @v_wkt    = 'CURVEPOLYGON (' + @p_linestring.AsTextZM() + ')';
      -- Ring rotation should be considered
      -- +ve Buffer outside, -ve buffer inside, so reverse
      SET @v_split_geom = geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid).MakeValid();
      SET @v_buffer = @v_split_geom.STBuffer(-1.0 * @p_buffer_distance).STSymDifference(@v_split_geom);
      Return @v_buffer;
    END;

    -- **********************************************************************************
    -- Get start and end segments that don't disappear.
    SET @v_buffer      = @p_linestring.STBuffer(ABS(@p_buffer_distance));
    SET @v_buffer_ring = @v_buffer.STExteriorRing();
    SET @v_linestring  = [$(owner)].[STRemoveOffsetSegments] (
                           @p_linestring,
                           @p_buffer_distance,
                           @v_round_xy, 
                           @v_round_zm 
                         );
    IF ( @v_linestring is null or @v_linestring.STIsEmpty()=1)
       return @p_linestring;

    SET @v_GeometryType = @v_linestring.STGeometryType();

    -- **********************************************************************************

    -- Rebuffer those that don't disappear
    SET @v_buffer      = @p_linestring.STBuffer(ABS(@p_buffer_distance));
    SET @v_buffer_ring = @v_buffer.STExteriorRing();

    IF ( @v_GeometryType    = 'CompoundCurve' )
    BEGIN
      SET @v_start_linestring = @v_linestring.STCurveN(1);
      SET @v_end_linestring   = @v_linestring.STCurveN(@v_linestring.STNumCurves());
    END
    ELSE
    BEGIN
      SET @v_start_linestring = @v_linestring;
      SET @v_end_linestring   = @v_linestring;
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
      SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_start_linestring.STPointN(1),
                            @v_start_linestring.STPointN(2)
                         );
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + case when @v_square = 1 then (@v_sign * 90.0) else 180.0 end
                       );
      -- create initial new extension line using buffer distance + increment
      SET @v_extension_line = [$(owner)].[STMakeLine] (
                                 @v_start_linestring.STPointN(1),
                                 [$(cogoowner)].[STPointFromCOGO] ( 
                                    @v_start_linestring.STPointN(1),
                                    @v_bearing,
                                    @v_buffer_distance + @v_buffer_increment,
                                    @v_round_xy+1
                                 ),
                                 @p_round_xy,
                                 @p_round_zm
                              );
      IF ( @v_extension_line is null ) 
      BEGIN
        SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] (
                              @v_linestring,
                              @v_bearing,
                              @v_buffer_distance + @v_buffer_increment,
                              'START', /* POINT */
                              /* @p_round    */ @v_round_xy+1,
                              /* @p_round_zm */ @v_round_zm 
                            );
      END
      ELSE
      BEGIN
        -- Create extended linestring...
        -- Test if end point is on/near buffer line (on will return single - intersection - point)
        SET @v_shortest_line_to = @v_extension_line.STEndPoint().ShortestLineTo(@v_buffer_ring);
        IF ( @v_shortest_line_to.STGeometryType() <> 'Point')
        BEGIN
          -- Modify extended line
          --   Replace end of @v_extension_line with end point of @v_shortest_line_to
          --   NOTE: Direction may still not be correct but it should be close
          SET @v_extension_line = [$(owner)].[STMakeLine] (
                                    @v_extension_line.STPointN(1),
                                    @v_shortest_line_to.STEndPoint(),
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
    END;

    IF ( @v_start_linestring.STGeometryType() = 'CircularString') 
    BEGIN
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_start_linestring );
      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
        RETURN @v_buffer;
      SET @v_radius = @v_circle.STStartPoint().Z;
      -- Make circle a 2D point (throw away radius)
      SET @v_circle = geometry::Point(
                        @v_circle.STStartPoint().STX,
                        @v_circle.STStartPoint().STY,
                        @p_linestring.STSrid
                       );
      -- Line from centre to v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_circular_string.STStartPoint(),
                            @v_circle
                         );
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + case when @v_square = 1 then 0.0 else (@v_sign * 90.0) end
                       );
      -- Add new segment to existing linestring...
      SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] ( 
                             @v_linestring,
                             @v_bearing,
                             (@v_radius + @p_buffer_distance + (@v_sign * @v_buffer_increment)),
                             'START', 
                             @v_round_xy+1,
                             @v_round_zm
                          );
    END;

    -- ******************** END OF START LINE PROCESSING *************************

    -- Now compute for END LINE
    --
    IF ( @v_end_linestring.STGeometryType() = 'LineString')  
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
      -- create initial new extension line using buffer distance + increment
      SET @v_extension_line = [$(owner)].[STMakeLine] (
                                 @v_end_linestring.STEndPoint(),
                                 [$(cogoowner)].[STPointFromCOGO] ( 
                                    @v_end_linestring.STEndPoint(),
                                    @v_bearing,
                                    @v_buffer_distance + @v_buffer_increment,
                                    @v_round_xy+1
                                 ),
                                 @p_round_xy,
                                 @p_round_zm
                              );
      IF ( @v_extension_line is null ) 
      BEGIN
        SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] (
                              @v_linestring,
                              @v_bearing,
                              @v_buffer_distance + @v_buffer_increment,
                              'START', /* POINT */
                              /* @p_round    */ @v_round_xy+1,
                              /* @p_round_zm */ @v_round_zm 
                            );
      END
      ELSE
      BEGIN
        -- Create extended linestring...
        -- Test if end point is on/near buffer line (on will return single - intersection - point)
        SET @v_shortest_line_to = @v_extension_line.STEndPoint().ShortestLineTo(@v_buffer_ring);
        IF ( @v_shortest_line_to.STGeometryType() <> 'Point')
        BEGIN
          -- Modify extended line
          --   Replace end of @v_extension_line with end point of @v_shortest_line_to
          --   NOTE: Direction may still not be correct but it should be close
          SET @v_extension_line = [$(owner)].[STMakeLine] (
                                    @v_extension_line.STPointN(1),
                                    @v_shortest_line_to.STEndPoint(),
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
    END;

    IF ( @v_end_linestring.STGeometryType() = 'CircularString' ) 
    BEGIN
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_end_linestring );
      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
        RETURN @v_buffer;
      SET @v_radius = @v_circle.STStartPoint().Z;
      -- Make circle a 2D point (throw away radius)
      SET @v_circle = geometry::Point(
                        @v_circle.STStartPoint().STX,
                        @v_circle.STStartPoint().STY,
                        @p_linestring.STSrid
                       );
      -- Line from centre to v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_circular_string.STPointN(1),
                            @v_circle
                         );
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + case when @v_square = 1 then 0.0 else (@v_sign * 90.0) end
                       );
      -- Create and Add new segment to existing linestring...
      SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] ( 
                             @v_linestring,
                             @v_bearing,
                             (@v_radius + @p_buffer_distance + (@v_sign * @v_buffer_increment)),
                             'END', 
                             @v_round_xy+1,
                             @v_round_zm
                          );
    END;

    -- #########################################################################################
    -- #########################################################################################
    -- Now, split buffer with modified linestring (using buffer trick) to generate two polygons
    --

    SET @v_split_geom = @v_buffer.STDifference(@v_linestring.STBuffer(@v_buffer_increment));  -- /10.0));

    -- Find out which of the split left/right polygons is the one we want.
    --
    SET @v_GeomN = 1;
    WHILE ( @v_GeomN <= @v_split_geom.STNumGeometries() )
    BEGIN
      -- Create point on correct side of line at 1/2 buffer distance.
      SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_linestring.STPointN(1),
                            @v_linestring.STPointN(2)
                         );
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         @v_bearing + (@v_sign * 45.0)
                       );
      SET @v_point   = [$(cogoowner)].[STPointFromCOGO] ( 
                          @v_linestring.STPointN(1),
                          @v_bearing,
                          case when @p_linestring.STLength() < @v_buffer_distance 
                               then @p_linestring.STLength()
                               else @v_buffer_distance
                           end / 2.0,
                          @v_round_xy
                       );
      IF ( @v_split_geom.STGeometryN(@v_GeomN).STContains(@v_point) = 1 )
      BEGIN
        SET @v_side_geom = @v_split_geom.STGeometryN(@v_GeomN);
        BREAK;
      END;
      SET @v_GeomN = @v_GeomN + 1;
    END;

    -- #########################################################################################
    -- STRound removes 0.00001 sliver trick that would otherwise be left behind in the data.
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
End;
GO

Print '****************************';
Print 'Test STOneSidedBuffer ...';
GO

with data as (
select 'Ordinary 2 Point Linestring' as test, geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) as linestring
union all
select 'Self Joining Linestring'     as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0)',0) as linestring
union all
select 'Ends within buffer distance' as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0.3)',0) as linestring
)
select d.linestring.STAsText() as sqBuff from data as d
union all
select [$(owner)].[STOneSidedBuffer](d.linestring,/*BuffDist*/0.5,/*@p_square*/1,2,1).STAsText() as sqBuff from data as d;
GO

select geometry::STGeomFromText('LINESTRING(0 0, 10 0, 10 10, 0 10,0 0)',0) as geom
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),-1.0,1,3,2)
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),1.0,0,3,2);
GO

-- Nearly closed
select geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0).STBuffer(0.01) as rGeom
union all
select [$(owner)].[STOneSidedBuffer] (geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0),-0.5,1,3,1)
.STAsText() as pGeom;
GO


