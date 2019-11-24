SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STDelete]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP  FUNCTION [$(owner)].[STDelete];
  Print 'Dropped [$(owner)].[STDelete] ...';
END;
GO

Print 'Creating STDelete ...';
GO

CREATE FUNCTION [$(owner)].[STDelete]
(
  @p_geometry   geometry,
  @p_point_list varchar(max) = '1',
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns geometry
/****f* EDITOR/STDelete (2008)
 *  NAME
 *    STDelete -- Function which deletes one or more coordinates from the supplied geometry.
 *  SYNOPSIS
 *    Function STDelete (
 *               @p_geometry   geometry,
 *               @p_point_list varchar(max) 
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STDelete(STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2,120 394.23)',0),'2',3,2).STAsText() as deleteGeom; 
 *    # deleteGeom
 *    'LINESTRING(0.1 0.2,120 394.23)'
 *  DESCRIPTION
 *    Function that removes one or more coordinates from the supplied geometry.
 *    The function does not process POINT or GEOMETRYCOLLECTION geometries.
 *    The list of points to be deleted is supplied as a comma separated string of point numbers.
 *    The point numbers are from 1 to the total number of points in a WKT representation of the object.
 *    Point numbers do not refer to specific points within a specific sub-geometry eg point number 1 in the 2nd interiorRing in a polygon object.
 *  INPUTS
 *    @p_geometry     (geometry) - supplied geometry of any type.
 *    @p_point_line    (varchar) - Comma separated list of point numbers from 1 to the total number in a geometry's WKT representation.
 *    @p_round_xy          (int) - Rounding value for XY ordinates.
 *    @p_round_zm          (int) - Rounding value for ZM ordinates.
 *  RESULT
 *    modified geom   (geometry) - With referenced points deleted. 
 *  NOTES
 *    May throw error message STGeomFromText error if point deletion invalidates the geometry.
 *  TODO
 *    Support for CircularString and CompundCurve objects.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
As
Begin
  Declare
     @v_GeometryType      varchar(100),
     @v_wkt               varchar(max),
     @v_dimensions        varchar(4), 
     @v_point_list        varchar(max) = REPLACE(','+ISNULL(@p_point_list,'1')+',',',,',','),
     @v_round_xy          int = ISNULL(@p_round_xy,3),
     @v_round_zm          int = ISNULL(@p_round_zm,2),
     @v_points_to_delete  int,
     @v_pointn            int,
     @v_RingN             int,
     @v_part_pointn       int,
     @v_geomn             int,
     @v_ring_geom         geometry,
     @v_geometry_part     geometry,
     @v_geometry          geometry
  Begin
    If ( @p_geometry is NULL ) 
      RETURN NULL;

    SET @v_GeometryType = @p_geometry.STGeometryType();
    If ( @v_GeometryType IN ('GeometryCollection','Point')) 
      RETURN @p_geometry;

    -- Set flag for STPointFromText
    -- @p_dimensions => XY, XYZ, XYM, XYZM or NULL (XY) 
    SET @v_dimensions = 'XY' 
                       + case when @p_geometry.HasZ=1 then 'Z' else '' end 
                       + case when @p_geometry.HasM=1 then 'M' else '' end;

    If (  ( @v_GeometryType = 'MultiPoint' and @p_geometry.STNumPoints() = 1) 
       or ( @p_geometry.STNumPoints() < @v_points_to_delete) 
       or ( @v_GeometryType = 'LineString' and ABS(@v_points_to_delete - @p_geometry.STNumPoints()) < 2 )
       or ( @v_GeometryType = 'Polygon'    and  @v_points_to_delete <= @p_geometry.STExteriorRing().STNumPoints() 
          and @p_geometry.STExteriorRing().STNumPoints() = 4) )
    BEGIN
       RETURN @p_geometry;
    END;

    -- Check and replace -1 end marker with STNumPoints()
    SET @v_point_list = case when CHARINDEX('-1',@v_point_list,1) <> 0 
                             then REPLACE(@v_point_list,',-1,',','+CAST(@p_geometry.STNumPoints() as varchar(10))+',')
                             else @v_point_list
                         end;

    -- Count points that need deleting...  
    SET @v_points_to_delete = ROUND( (LEN(@v_point_list)-1) - 
                                      LEN(REPLACE(@v_point_list,',',''))
                                    / LEN(','),
                            0);

    If ( @v_GeometryType = 'MultiPoint' )
    BEGIN
      SET @v_geomn = 1;
      SET @v_WKT   = 'MULTIPOINT (';
      WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
      BEGIN
          IF ( CHARINDEX(','+CAST(@v_geomn as varchar(10))+',', @v_point_list,1) = 0 )
          BEGIN
             IF ( RIGHT(@v_wkt,1) = ')' )
             BEGIN
                 SET @v_WKT = @v_WKT + ',';
             END;
             SET @v_WKT = @v_wkt + 
                          '(' 
                          +
                          [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @p_geometry.STGeometryN(@v_geomn).STX,
                            /* @p_Y          */ @p_geometry.STGeometryN(@v_geomn).STY,
                            /* @p_Z          */ @p_geometry.STGeometryN(@v_geomn).Z,
                            /* @p_M          */ @p_geometry.STGeometryN(@v_geomn).M,
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                          )
                          + 
                          ')';
          END;
          SET @v_geomn = @v_geomn + 1;
      END; 
      SET @v_wkt = @v_wkt + ')';
      RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    END;

    If ( @v_GeometryType = 'LineString' )
    BEGIN
      SET @v_pointn = 1;
      SET @v_WKT = 'LINESTRING (';
      WHILE ( @v_pointn <= @p_geometry.STNumPoints() )
      BEGIN
        IF ( CHARINDEX(',' + CAST(@v_pointn as varchar(10)) + ',', @v_point_list,1) = 0 )
        BEGIN
          IF ( RIGHT(@v_wkt,1) != '(' )
          BEGIN
            SET @v_WKT = @v_WKT + ',';
          END;
          SET @v_WKT = @v_wkt 
                       +
                       [$(owner)].[STPointAsText] (
                         /* @p_dimensions */ @v_dimensions,
                         /* @p_X          */ @p_geometry.STPointN(@v_pointn).STX,
                         /* @p_Y          */ @p_geometry.STPointN(@v_pointn).STY, 
                         /* @p_Z          */ @p_geometry.STPointN(@v_pointn).Z, 
                         /* @p_M          */ @p_geometry.STPointN(@v_pointn).M, 
                         /* @p_round_x    */ @v_round_xy,
                         /* @p_round_y    */ @v_round_xy,
                         /* @p_round_z    */ @v_round_zm,
                         /* @p_round_m    */ @v_round_zm
                       );
          END;
          SET @v_pointn = @v_pointn + 1;
      END; 
      SET @v_wkt = @v_wkt + ')';
      RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    END;

    IF ( @v_GeometryType = 'MultiLineString' ) 
    BEGIN
      SET @v_WKT    = 'MULTILINESTRING (';
      SET @v_geomn  = 1;
      SET @v_pointn = 1;
      WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        IF ( @v_GeomN > 1 ) 
          SET @v_wkt = @v_wkt + ',('
        ELSE
          SET @v_WKT = @v_wkt + '(';
        SET @v_geometry_part = @p_geometry.STGeometryN(@v_geomn);
        SET @v_part_pointn   = 1;
        WHILE ( @v_part_pointn <= @v_geometry_part.STNumPoints() )
        BEGIN
          IF ( CHARINDEX(','+CAST(@v_pointn as varchar(10))+',', @v_point_list,1) = 0 )
          BEGIN
            IF ( RIGHT(@v_wkt,1) != '(' )
            BEGIN
              SET @v_WKT = @v_WKT + ',';
            END;
            SET @v_WKT = @v_wkt 
                         +
                         [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_geometry_part.STPointN(@v_part_pointn).STX,
                            /* @p_Y          */ @v_geometry_part.STPointN(@v_part_pointn).STY, 
                            /* @p_Z          */ @v_geometry_part.STPointN(@v_part_pointn).Z, 
                            /* @p_M          */ @v_geometry_part.STPointN(@v_part_pointn).M, 
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                         );
          END;
          SET @v_pointn      = @v_pointn + 1;
          SET @v_part_pointn = @v_part_pointn + 1;
        END; 
        -- Terminate this part
        SET @v_wkt = @v_wkt + ')';
        -- Process next
        SET @v_geomn = @v_geomn + 1;
      END;  -- All geometries...
      -- Terminate whole geometry and return.
      SET @v_wkt = @v_wkt + ')';
      RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    END;

    IF ( @v_GeometryType = 'Polygon' )
    BEGIN
      -- If Delete Point is start or end vertex of a ring the WKT will fail to convert to a polygon.
      SET @v_WKT    = 'POLYGON (';
      SET @v_PointN = 1;
      SET @v_RingN  = 0;
      WHILE ( @v_RingN < ( 1 /* One ExteriorRing */ + @p_geometry.STNumInteriorRing() ) )
      BEGIN
        IF ( @v_RingN = 0 )
          SET @v_ring_geom = @p_geometry.STExteriorRing()
        ELSE
        BEGIN
          SET @v_ring_geom = @p_geometry.STInteriorRingN(@v_RingN);
          SET @v_wkt       = @v_wkt + ',';
        END;
        SET @v_wkt         = @v_wkt + '(';
        SET @v_part_pointn = 1;
        WHILE ( @v_part_pointn <= @v_ring_geom.STNumPoints() )
        BEGIN
          IF ( CHARINDEX(',' + CAST(@v_pointn as varchar(10)) + ',', @v_point_list,1) = 0 )
          BEGIN
            IF ( RIGHT(@v_wkt,1) != '(' )
            BEGIN
              SET @v_WKT = @v_WKT + ',';
            END;
            SET @v_WKT = @v_wkt 
                         +
                         [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_ring_geom.STPointN(@v_part_pointn).STX,
                            /* @p_Y          */ @v_ring_geom.STPointN(@v_part_pointn).STY, 
                            /* @p_Z          */ @v_ring_geom.STPointN(@v_part_pointn).Z, 
                            /* @p_M          */ @v_ring_geom.STPointN(@v_part_pointn).M, 
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                         );
          END;
          SET @v_pointn      = @v_pointn + 1;
          SET @v_part_pointn = @v_part_pointn + 1;
        END;
        -- Terminate this part
        SET @v_wkt = @v_wkt + ')';
        -- Process next ring
        SET @v_RingN = @v_RingN + 1;
      END;  -- All Rings...
      -- Terminate whole geometry and return.
      SET @v_wkt = @v_wkt + ')';
      RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    END;  -- IF Polygon

    IF ( @v_GeometryType = 'MultiPolygon' )
    BEGIN
      -- If Delete Point is start or end vertex of any ring the WKT will fail to convert to a polygon.
      SET @v_WKT    = 'MULTIPOLYGON ((';
      SET @v_PointN = 1;
      SET @v_GeomN  = 1;
      WHILE ( @v_GeomN <= @p_geometry.STNumGeometries() )
      BEGIN
        IF (@v_GeomN>1) SET @v_wkt = @v_wkt + ',(';
        SET @v_geometry_part = @p_geometry.STGeometryN(@v_GeomN);
        SET @v_RingN  = 0;
        WHILE ( @v_RingN < ( 1 /* ExteriorRing */ + @v_geometry_part.STNumInteriorRing() ) )
        BEGIN
          IF ( @v_RingN = 0 )
            SET @v_ring_geom = @v_geometry_part.STExteriorRing()
          ELSE
          BEGIN
            SET @v_ring_geom = @v_geometry_part.STInteriorRingN(@v_RingN);
            SET @v_wkt       = @v_wkt + ',';
          END;
          SET @v_wkt         = @v_wkt + '(';
          SET @v_part_pointn = 1;
          WHILE ( @v_part_pointn <= @v_ring_geom.STNumPoints() )
          BEGIN
            IF ( CHARINDEX(','+CAST(@v_pointn as varchar(10))+',', @v_point_list,1) = 0 )
            BEGIN
              IF ( RIGHT(@v_wkt,1) != '(' )
              BEGIN
                SET @v_WKT = @v_WKT + ',';
              END;
              SET @v_WKT = @v_wkt 
                         +
                         [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_ring_geom.STPointN(@v_part_pointn).STX,
                            /* @p_Y          */ @v_ring_geom.STPointN(@v_part_pointn).STY, 
                            /* @p_Z          */ @v_ring_geom.STPointN(@v_part_pointn).Z, 
                            /* @p_M          */ @v_ring_geom.STPointN(@v_part_pointn).M, 
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                         );
            END;
            SET @v_pointn      = @v_pointn + 1;
            SET @v_part_pointn = @v_part_pointn + 1;
          END;
          -- Terminate this part
          SET @v_wkt = @v_wkt + ')';
          -- Process next ring
          SET @v_RingN = @v_RingN + 1;
        END;  -- All Rings...
        SET @v_wkt   = @v_wkt + ')';
        SET @v_GeomN = @v_GeomN + 1;
      END; -- Terminate this part of the multi geometry
      -- Terminate whole geometry and return.
      SET @v_wkt = @v_wkt + ')';
      RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    END;  -- IF MultiPolygon
    RETURN @p_geometry;
  End;
End
GO

Print 'Testing [$(owner)].[STDelete] ...';
GO

Select 'LineString - Last Point' as msg, 
       [$(owner)].[STDelete](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),'-1',3,2).AsTextZM() as WKT 
GO

select 'MULTIPOLYGON Single Point - OK' as msg, 
       [$(owner)].[STDelete] (
         geometry::STGeomFromText('MULTIPOLYGON (((0 0, 5 0, 10 0, 5 5, 0 0)),((20 20, 25 20, 30 20, 25 30, 20 20),(22 22, 25 26, 28 22, 22 22)))',0),
         '2',3,2).AsTextZM() as WKT
GO

/*
select 'MULTIPOLYGON Two Points - Fail' as msg, 
       [$(owner)].[STDelete](
         geometry::STGeomFromText('MULTIPOLYGON (((0 0, 5 0, 10 0, 5 5, 0 0)),((20 20, 25 20, 30 20, 25 30, 20 20),(22 22, 25 26, 28 22, 22 22)))',0),
         '2,3',3,2) as t
GO
*/

