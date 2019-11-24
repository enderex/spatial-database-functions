SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STDensify]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STDensify];
  Print 'Dropped [$(owner)].[STDensify] ...';
END;
GO

Print 'Creating [$(owner)].[STDensify] ...';
GO

CREATE FUNCTION [$(owner)].[STDensify] (
  @p_geometry geometry,
  @p_distance float,
  @p_round_xy int = 10,
  @p_round_zm int = 10
)
RETURNS geometry
As
/****f* EDITOR/STDensify (2012)
  *  NAME
  *    STDensify -- Implements a basic geometry densification algorithm.
  *  SYNOPSIS
  *    Function [$(owner)].[STDensify](
  *               @p_geometry geometry,
  *               @p_distance Float,
  *               @p_round_xy int = 10,
  *               @p_round_zm int = 10
  *             )
  *      Returns geometry
  *  DESCRIPTION
  *    This function add vertices to an existing vertex-to-vertex described (m)linestring or (m)polygon sdo_geometry.
  *    New vertices are added in such a way as to maintain existing vertices, that is, no existing vertices are removed.
  *    Densification occurs on a single vertex-to-vertex segment basis.
  *    If segment length is < p_distance no vertices are added.
  *    The implementation does not guarantee that the added vertices will be exactly p_distance apart; mostly they will be < @p_distance..
  *    The implementation honours 3D and 4D shapes and averages these dimension values for the new vertices.
  *    The function does not support compound objects or objects with circles, or described by arcs.
  *    Any non (m)polygon/(m)linestring shape is simply returned as it is.
  *  ARGUMENTS
  *    @p_geometry (geometry) - (M)Linestring or (m) polygon.
  *    @p_distance    (Float) - The desired optimal distance between added vertices.
  *    @p_round_xy      (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
  *    @p_round_zm      (int) - Decimal degrees of precision to which ZM ordinates are compared.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Densified geometry.
  *  EXAMPLE
  *    -- Densify 2D line into 4 segments
  *    with data as (
  *    select geometry::STGeomFromText('LINESTRING(0 0,10 10)',0) as geom
  *    )
  *    select [dbo].[STDensify](a.geom,a.geom.STLength()/4.0,3,2).AsTextZM() as dGeom
  *      from data as a;
  *
  *    dGeom
  *    LINESTRING (0 0, 2.5 2.5, 5 5, 7.5 7.5, 10 10)
  *
  *    -- Distance between all vertices is < 4.0
  *    select [dbo].[STDensify](geometry::STGeomFromText('LINESTRING (5 5, 5 7, 7 7, 7 5, 5 5)',0),4.0,3,2).AsTextZM() as dGeom;
  *
  *    dGeom
  *    LINESTRING (5 5, 5 7, 7 7, 7 5, 5 5)
  *
  *    -- Simple Straight line.
  *    select [$(owner)].[STDensify] (geometry::STGeomFromText('LINESTRING(100 100,900 900.0)',0),125.0,3,2).AsTextZM() as dGeom;
  *
  *    DGeom
  *    LINESTRING (100 100, 188.889 188.889, 277.778 277.778, 366.667 366.667, 455.556 455.556, 544.444 544.444, 633.333 633.333, 722.222 722.222, 811.111 811.111, 900 900)
  *
  *    -- LineString with Z
  *    select [dbo].[STDensify] (geometry::STGeomFromText('LINESTRING(100 100 1.0,900 900.0 9.0)',0),125.0,3,2).AsTextZM() as dGeom;
  *    
  *    dGeom
  *    LINESTRING (100 100 1, 180 180 1.8, 260 260 2.6, 340 340 3.4, 420 420 4.2, 500 500 5, 580 580 5.8, 660 660 6.6, 740 740 7.4, 820 820 8.2, 900 900 9)
  *
  *    -- LineStrings with ZM
  *    select [dbo].[STDensify] (geometry::STGeomFromText('LINESTRING(100.0 100.0 -4.56 0.99, 110.0 110.0 -6.73 1.1)',0),2.5,3,2).AsTextZM() as dGeom;
  *    
  *    dGeom
  *    LINESTRING (100 100 -4.56 0.99, 101.667 101.667 -4.92 1.01, 103.333 103.333 -5.28 1.03, 105 105 -5.64 1.04, 106.667 106.667 -6.01 1.06, 108.333 108.333 -6.37 1.08, 110 110 -6.73 1.1)
  *
  *    GEOM
  *      LINESTRING (1100.765 964.286, 1107.568 939.343, 1114.371 914.399, 1121.173 889.456, 1127.976 864.513, 1134.779 839.569, 1141.582 814.626, 1148.384 789.683, 1155.187 764.739, 1161.99 739.796, 1139.881 723.923, 
  *                  1117.772 708.05, 1095.663 692.177, 1073.554 676.304, 1051.446 660.431, 1029.337 644.558, 1007.228 628.685, 985.119 612.812, 963.01 596.939, 941.032 610.675, 919.054 624.411, 897.076 638.148,
  *                  875.098 651.884, 853.12 665.62, 831.142 679.356, 809.164 693.093, 787.186 706.829, 765.208 720.565, 743.23 734.301, 721.252 748.038, 699.274 761.774, 677.296 775.51, 653.203 787.131, 629.11 
  *                  798.753, 605.017 810.374, 580.924 821.995, 556.831 833.617, 532.738 845.238, 508.645 856.859, 484.552 868.481, 460.459 880.102, 434.63 869.26, 408.801 858.418, 382.972 847.576, 357.143 
  *                  836.735, 331.314 825.893, 305.485 815.051, 279.656 804.209, 253.827 793.367, 242.53 770.043, 231.232 746.72, 219.935 723.396, 208.637 700.073, 197.34 676.749, 186.042 653.426, 174.745 
  *                  630.102, 185.459 603.571, 196.173 577.041, 206.888 550.51, 217.602 523.98, 228.316 497.449, 253.543 500.85, 278.77 504.252, 303.996 507.653, 329.223 511.054, 354.45 514.456, 379.677 
  *                  517.857, 404.903 521.258, 430.13 524.66, 455.357 528.061, 479.244 520.64, 503.131 513.219, 527.017 505.798, 550.904 498.377, 574.791 490.956, 598.678 483.534, 622.565 476.113, 646.452 468.692, 
  *                  670.338 461.271, 694.225 453.85, 718.112 446.429, 717.262 420.493, 716.411 394.558, 715.561 368.622, 714.711 342.687, 713.86 316.751, 713.01 290.816, 698.66 270.089, 684.311 249.362, 
  *                  669.962 228.635, 655.612 207.908, 641.263 187.181, 626.913 166.454, 612.564 145.727, 598.214 125, 573.271 120.181, 548.327 115.363, 523.384 110.544, 498.441 105.726, 473.497 100.907, 
  *                  448.554 96.089, 423.611 91.27, 398.667 86.452, 373.724 81.633, 351.858 94.935, 329.992 108.236, 308.126 121.538, 286.261 134.84, 264.395 148.142, 242.529 161.443, 220.663 174.745, 
  *                  198.797 188.047, 176.931 201.348, 155.065 214.65, 133.2 227.952, 111.334 241.254, 89.468 254.555, 67.602 267.857)
  *
  *    -- MultiLineString.
  *    select [dbo].[STDensify](geometry::STGeomFromText('MULTILINESTRING ((0 0, 5 5, 10 10),(20 20, 25 25, 30 30))',0),2.1,3,2).AsTextZM() as dGeom;
  *
  *    dGeom
  *    MULTILINESTRING ((0 0, 1.25 1.25, 2.5 2.5, 3.75 3.75, 5 5, 6.25 6.25, 7.5 7.5, 8.75 8.75, 10 10), (20 20, 21.25 21.25, 22.5 22.5, 23.75 23.75, 25 25, 26.25 26.25, 27.5 27.5, 28.75 28.75, 30 30))
  *
  *    -- Polygon 
  *    select [dbo].[STDensify](
  *                  geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),
  *                  4.0,
  *                  3,2
  *           ).AsTextZM() as dGeom;
  *    
  *    dGeom
  *    POLYGON ((0 0, 4 0, 8 0, 12 0, 16 0, 20 0, 20 4, 20 8, 20 12, 20 16, 20 20, 16 20, 12 20, 8 20, 4 20, 0 20, 0 16, 0 12, 0 8, 0 4, 0 0), (10 10, 10 11, 11 11, 11 10, 10 10), (5 5, 5 7, 7 7, 7 5, 5 5))
  *
  *    -- MultiPolygon
  *    select [dbo].[STDensify](
  *                  geometry::STGeomFromText('MULTIPOLYGON(((100 100,110 100,110 110,100 110,100 100)),((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)))',0),
  *                  4.0,
  *                  3,2
  *           ).AsTextZM() as dGeom;
  *    
  *    dGeom
  *    MULTIPOLYGON (((100 100, 103.333 100, 106.667 100, 110 100, 110 103.333, 110 106.667, 110 110, 106.667 110, 103.333 110, 100 110, 100 106.667, 100 103.333, 100 100)), 
  *                  ((0 0, 4 0, 8 0, 12 0, 16 0, 20 0, 20 4, 20 8, 20 12, 20 16, 20 20, 16 20, 12 20, 8 20, 4 20, 0 20, 0 16, 0 12, 0 8, 0 4, 0 0), (10 10, 10 11, 11 11, 11 10, 10 10), (5 5, 5 7, 7 7, 7 5, 5 5)))
  *    
  *  NOTES
  *    Only supports stroked (m)linestrings and (m)polygon rings.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June  2006 - Original coding in Oracle.
  *    Simon Greener - April 2019 - Port to SQL Server Spatial
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType   varchar(50),
    @v_dimensions     varchar(4),
    @v_wkt            varchar(max),
    @v_dim            int,
    @i                int,
    @j                int,
    @geom             geometry,
    @v_line           geometry,
    @v_prev_point     geometry,
    @v_point          geometry,
    @v_dense_point    geometry,
    @v_length         Float,
    @v_vector_length  Float,
    @v_segment_length Float,
    @v_diff_x         Float,
    @v_diff_y         Float,
    @v_diff_z         Float,
    @v_diff_m         Float,
    @v_ratio          Float,
    @v_geom_n         int,
    @p_sub_geom       int,
    @v_sub_n          int,
    @v_num_segments   int,
    @v_round_xy       int,
    @v_round_zm       int;
  Begin
    If ( @p_geometry is null )
      Return @p_geometry;

    SET @v_geometryType = @p_geometry.STGeometryType();
    If ( @v_geometryType Not In ('LineString','MultiLineString','Polygon','MultiPolygon') )
      Return @p_geometry;

    -- We don't support Densification of Circular Curves
    IF ( CHARINDEX('CURVE',   @p_geometry.AsTextZM()) > 0 or 
         CHARINDEX('CIRCULAR',@p_geometry.AsTextZM()) > 0 )
      Return @p_geometry;

    SET @v_round_xy   = ISNULL(@p_round_xy,10);
    SET @v_round_zm   = ISNULL(@p_round_zm,10);
    SET @v_dim        = [$(owner)].[STCoordDim](@p_geometry);
    SET @v_dimensions = 'XY' 
                        + case when @p_geometry.HasZ=1 then 'Z' else '' end 
                        + case when @p_geometry.HasM=1 then 'M' else '' end;

    SET @v_length = @p_geometry.STLength();
    IF ( @v_Length <= @p_distance ) 
      Return @p_geometry;

    IF ( @v_GeometryType = 'LineString' ) 
    BEGIN
      SET @v_prev_point = @p_geometry.STPointN(1);
      SET @v_ratio      = 0.0;
      SET @i            = 2;
      While @i <= @p_geometry.STNumPoints() 
      Begin
        SET @v_point         = @p_geometry.STPointN(@i);
        SET @v_vector_length = @v_prev_point.STDistance(@v_point);
        -- Is a point required to be inserted ?
        SET @v_num_segments = CEILING(@v_vector_length / @p_distance);
        If ( @v_num_segments > 0 and (@p_distance < @v_vector_length)) 
        Begin
          SET @v_segment_length = @v_vector_length / CAST(@v_num_segments as Float);
          SET @v_ratio   = @v_segment_length / @v_vector_length;
          SET @v_diff_x  = (@v_point.STX-@v_prev_point.STX) * @v_ratio;
          SET @v_diff_y  = (@v_point.STY-@v_prev_point.STY) * @v_ratio;
          IF ( CHARINDEX('Z',@v_dimensions) > 0 )
            SET @v_diff_z  = (@v_point.Z-@v_prev_point.Z) * @v_ratio;
          IF ( CHARINDEX('M',@v_dimensions) > 0 )
            SET @v_diff_m  = (@v_point.M-@v_prev_point.M) * @v_ratio;
          SET @j = 1;
          WHILE @j <= @v_num_segments 
          BEGIN
            SET @v_dense_point = [$(owner)].[STMakePoint] (
                                    ROUND(@v_prev_point.STX + (@v_diff_x * @j),@v_round_xy),
                                    ROUND(@v_prev_point.STY + (@v_diff_y * @j),@v_round_xy),
                                    CASE WHEN CHARINDEX('Z',@v_dimensions) > 0 THEN ROUND(@v_prev_point.Z + (@v_diff_z * @j),@v_round_zm) ELSE NULL END,
                                    CASE WHEN CHARINDEX('M',@v_dimensions) > 0 THEN ROUND(@v_prev_point.M + (@v_diff_m * @j),@v_round_zm) ELSE NULL END,
                                    @p_geometry.STSrid
                                 );
            SET @v_line = CASE WHEN @v_line is null 
                               THEN [$(owner)].[STMakeLine] (
                                       @v_prev_point,
                                       @v_dense_point,
                                       @v_round_xy,
                                       @v_round_zm
                                    )
                               ELSE [$(owner)].[STInsertN] (
                                       @v_line,
                                       @v_dense_point,
                                       -1,
                                       @v_round_xy,
                                       @v_round_zm
                                     )
                            END;
            SET @j = @j + 1;
          END;
        END
        ELSE
        BEGIN
          -- Add Point 
          SET @v_line = CASE WHEN @v_line is null 
                             THEN [$(owner)].[STMakeLine] (
                                     @v_prev_point,
                                     @v_point,
                                     @v_round_xy,
                                     @v_round_zm
                                  )
                              ELSE [$(owner)].[STInsertN](
                                     @v_line,
                                     @v_point,
                                     -1,
                                     @v_round_xy,
                                     @v_round_zm
                                   )
                         END;
        END;
        SET @i = @i + 1;
        SET @v_prev_point = @v_point;
      END;
      Return @v_line;
    End /* LineString */
    Else
    Begin

      IF ( @v_GeometryType IN ('MultiLineString') ) 
      BEGIN
        SET @v_geom_n = 1;
        WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
        BEGIN
          SET @v_line = [$(owner)].[STDensify] (
                           @p_geometry.STGeometryN(@v_geom_n),
                           @p_distance,
                           @v_round_xy,
                           @v_round_zm
                        ); 
          SET @v_wkt = CASE WHEN @v_geom_n = 1 
                            THEN @v_line.AsTextZM()
                            ELSE CONCAT(@v_wkt,',',@v_line.AsTextZM())
                        END;
          SET @v_geom_n = @v_geom_n + 1;
        END; 
        SET @v_wkt = CONCAT('MULTILINESTRING(',REPLACE(@v_wkt,'LINESTRING',''),')');
        RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
      END; -- IF ( @v_GeometryType IN ('MultiLineString') ) 
      
      IF ( @v_GeometryType IN ('Polygon') )
      BEGIN
        SET @v_sub_n  = 0;
        WHILE ( @v_sub_n < ( 1 + @p_geometry.STNumInteriorRing() ) )
        BEGIN
          SET @geom = CASE WHEN @v_sub_n = 0 
                           THEN @p_geometry.STExteriorRing()          -- Exterior Ring
                           ELSE @p_geometry.STInteriorRingN(@v_sub_n) -- Interior Ring
                       END;
          SET @v_line = [$(owner)].[STDensify] (
                           @geom,
                           @p_distance,
                           @v_round_xy,
                           @v_round_zm
                        ); 
          SET @v_wkt = CASE WHEN @v_sub_n = 0
                            THEN @v_line.AsTextZM()                    -- Exterior Ring
                            ELSE CONCAT(@v_wkt,',',@v_line.AsTextZM()) -- Interior Ring
                        END;
          SET @v_sub_n = @v_sub_n + 1;
        END; -- WHILE ( @v_sub_n < ( 1 + @p_geometry.STNumInteriorRing() ) )
        SET @v_wkt = CONCAT(
                       'POLYGON(',
                       REPLACE(@v_wkt,'LINESTRING',''),
                       ')'
                     );
        RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
      END; -- IF ( @v_GeometryType IN ('Polygon') )
      
      IF ( @v_GeometryType = 'MultiPolygon' )
      BEGIN
        SET @v_geom_n = 1;
        WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
        BEGIN
          SET @geom = [$(owner)].[STDensify] (
                           @p_geometry.STGeometryN(@v_geom_n),
                           @p_distance,
                           @v_round_xy,
                           @v_round_zm
                      ); 
          SET @v_wkt = CASE WHEN @v_geom_n = 1 
                            THEN @geom.AsTextZM()
                            ELSE CONCAT(@v_wkt,',',@geom.AsTextZM())
                        END;
          SET @v_geom_n = @v_geom_n + 1;
        END; 
        SET @v_wkt = CONCAT('MULTIPOLYGON(',REPLACE(@v_wkt,'POLYGON',''),')');
        RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
      END;   -- IF ( @v_GeometryType = 'MultiPolygon' )
    End;     -- IF ( @v_GeometryType = 'LineString' ) 
    Return @p_geometry;
  End;
End;
GO

-- Densify 2D line into 4 segments
with data as (
select geometry::STGeomFromText('LINESTRING(0 0,10 10)',0) as geom
)
select [$(owner)].[STDensify](a.geom,a.geom.STLength()/4.0,3,2).AsTextZM() as dGeom
  from data as a;
GO

select [$(owner)].[STDensify](geometry::STGeomFromText('LINESTRING(0 0,5 5,10 10)',0),2.1,3,2).AsTextZM();
GO

-- Distance between all vertices is < 4.0 (returns same geometry)
select [$(owner)].[STDensify](geometry::STGeomFromText('LINESTRING (5 5, 5 7, 7 7, 7 5, 5 5)',0),4.0,3,2).AsTextZM() as dGeom;
GO

-- LineString with Z
select [$(owner)].[STDensify] (geometry::STGeomFromText('LINESTRING(100 100 1.0,900 900.0 9.0)',0),125.0,3,2).AsTextZM() as dGeom;
GO

-- LineStrings with ZM
select [$(owner)].[STDensify] (geometry::STGeomFromText('LINESTRING(100.0 100.0 -4.56 0.99, 110.0 110.0 -6.73 1.1)',0),2.5,3,2).AsTextZM() as dGeom;
GO

-- MultiLineStrings.
select [$(owner)].[STDensify](geometry::STGeomFromText('MULTILINESTRING ((0 0, 5 5, 10 10),(20 20, 25 25, 30 30))',0),2.1,3,2).AsTextZM() as dGeom;
GO

-- Polygon 
select [$(owner)].[STDensify](
              geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),
              4.0,
              3,2
       ).AsTextZM() as dGeom;
GO

-- MultiPolygon
select [$(owner)].[STDensify](
              geometry::STGeomFromText('MULTIPOLYGON(((100 100,110 100,110 110,100 110,100 100)),((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)))',0),
              4.0,
              3,2
       ).AsTextZM() as dGeom;
GO

