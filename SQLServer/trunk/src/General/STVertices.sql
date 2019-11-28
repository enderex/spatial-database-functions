SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner(dbo)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STVertices]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STVertices];
  PRINT 'Dropped [$(owner)].[STVertices] ...';
END;
GO

-- ***************************************************************************

PRINT 'Creating [$(owner)].[STVertices] ...';
GO

CREATE FUNCTION [$(owner)].[STVertices]
(
  @p_geometry geometry 
)
Returns @Points TABLE
(
  uid int,   /* unique id */
  pid int,   /* Point Id */
  mid int,   /* Part Id */
  rid int,   /* Ring Id - Polygon Only */
  x   float,
  y   float,
  z   float,
  m     float,
  point geometry
)
AS
/****f* GEOPROCESSING/STVertices (2008)
 *  NAME
 *   STVertices - Dumps all vertices of supplied geometry object to ordered array.
 *  SYNOPSIS
 *   Function [$(owner)].[STVertices] (
 *       @p_geometry  geometry 
 *    )
 *    Returns @Points Table (
 *      uid   int,
 *      pid   int,
 *      mid   int,
 *      x     float,  
 *      y     float,
 *      z     float,
 *      m     float,
 *      point geometry
 *    )  
 *  EXAMPLE
 *
 *    SELECT e.[uid],e.[mid],e.[rid],e.[pid],
 *           e.[x],e.[y],e.[z],e.[m],e.[point].STAsText() as point
 *      FROM [$(owner)].[STVertices] (
 *             geometry::STGeomFromText(
 *               'MULTIPOLYGON( ((200 200, 400 200, 400 400, 200 400, 200 200)),
 *                                ((0 0, 100 0, 100 100, 0 100, 0 0),(40 40,60 40,60 60,40 60,40 40)) )',0)) as e
 *    GO
 *    
 *    uid mid rid pid   x   y    z    m point
 *    --- --- --- --- --- --- ---- ---- ---------------
 *    1   1   1   1   200 200 NULL NULL POINT (200 200)
 *    2   1   1   2   400 200 NULL NULL POINT (400 200)
 *    3   1   1   3   400 400 NULL NULL POINT (400 400)
 *    4   1   1   4   200 400 NULL NULL POINT (200 400)
 *    5   1   1   5   200 200 NULL NULL POINT (200 200)
 *    6   2   1   1     0   0 NULL NULL POINT (0 0)
 *    7   2   1   2   100   0 NULL NULL POINT (100 0)
 *    8   2   1   3   100 100 NULL NULL POINT (100 100)
 *    9   2   1   4     0 100 NULL NULL POINT (0 100)
 *    10  2   1   5     0   0 NULL NULL POINT (0 0)
 *    11  2   2   1    40  40 NULL NULL POINT (40 40)
 *    12  2   2   2    60  40 NULL NULL POINT (60 40)
 *    12  2   2   3    60  60 NULL NULL POINT (60 60)
 *    14  2   2   4    40  60 NULL NULL POINT (40 60)
 *    15  2   2   5    40  40 NULL NULL POINT (40 40)
 *    
 *  DESCRIPTION
 *    This function extracts the fundamental points that describe a geometry object.
 *    The points are returning in the order they appear in the geometry object.
 *  INPUTS
 *    @p_geometry (geometry) - Any non-point geometry object
 *  RESULT
 *    Table (Array) of Points :
 *     uid        (int) - Point identifier unique across the whole geometry object.
 *     pid        (int) - Point identifier with element/subelement (1 to Number of Points in element).
 *     mid        (int) - Unique identifier that describes the geometry object's multipart elements (eg linestring in MultiLineString).
 *     rid        (int) - SubElement or Ring identifier.
 *     x        (float) - Point X Ordinate 
 *     y        (float) - Point Y Ordinate 
 *     z        (float) - Point Z Ordinate 
 *     m        (float) - Point M Ordinate
 *     point (geometry) - Point as geometry
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2008 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(1000),
    @ringn          int,
    @geomn          int,
    @pointn         int,
    @uniqn          int,
    @geom           geometry;
  Begin
    If ( @p_geometry is NULL ) 
      return;

    SET @v_GeometryType = @p_geometry.STGeometryType();

    IF ( @v_GeometryType = 'Point' )
    BEGIN
      INSERT INTO @Points ( [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point] ) 
           VALUES ( 1,
                    1,
                    0,
                    0,
                    @p_geometry.STX,
                    @p_geometry.STY, 
                    @p_geometry.Z,
                    @p_geometry.M,
                    @p_geometry 
                  );
      RETURN;
    END;

    IF ( @v_GeometryType = 'MultiPoint' ) 
    BEGIN
      SET @geomn  = 1;
      WHILE ( @geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        INSERT INTO @Points ( [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point] ) 
             VALUES ( @geomn,
                      @geomn,
                      1,
                      0,
                      @p_geometry.STGeometryN(@geomn).STX,
                      @p_geometry.STGeometryN(@geomn).STY, 
                      @p_geometry.STGeometryN(@geomn).Z, 
                      @p_geometry.STGeometryN(@geomn).M,
                      @p_geometry.STGeometryN(@geomn) 
                    );
        SET @geomn = @geomn + 1;
      END; 
      RETURN;
    END;

    IF ( @v_GeometryType = 'LineString' )
    BEGIN
      SET @pointn = 1;
      WHILE ( @pointn <= @p_geometry.STNumPoints() )
      BEGIN
        INSERT INTO @Points ( [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point] ) 
           VALUES ( @pointn,
                    @pointn, 
                    1, 
                    0, 
                    @p_geometry.STPointN(@pointn).STX,
                    @p_geometry.STPointN(@pointn).STY, 
                    @p_geometry.STPointN(@pointn).Z,
                    @p_geometry.STPointN(@pointn).M,
                    @p_geometry.STPointN(@pointn)
                  );
        SET @pointn = @pointn + 1;
      END;  
      RETURN;
    END;
    
    IF ( @v_GeometryType = 'MultiLineString' ) 
    BEGIN
      SET @uniqn = 0;
      SET @geomn = 1;
      WHILE ( @geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @pointn = 1;
        WHILE ( @pointn <= @p_geometry.STGeometryN(@geomn).STNumPoints() )
        BEGIN
          SET @uniqn = @uniqn + 1;
          INSERT INTO @Points ( [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point] ) 
               VALUES ( @uniqn,
                        @pointN, 
                        @geomn,
                        0,
                        @p_geometry.STGeometryN(@geomn).STPointN(@pointn).STX,
                        @p_geometry.STGeometryN(@geomn).STPointN(@pointn).STY,
                        @p_geometry.STGeometryN(@geomn).STPointN(@pointn).Z,
                        @p_geometry.STGeometryN(@geomn).STPointN(@pointn).M,
                        @p_geometry.STGeometryN(@geomn).STPointN(@pointn)
                      );
          SET @pointn = @pointn + 1;
        END; 
        SET @geomn = @geomn + 1;
      END; 
      RETURN;
    END;
    
    IF ( @v_GeometryType = 'Polygon' )
    BEGIN
      SET @uniqn = 0;
      SET @ringn  = 0;
      WHILE ( @ringn < ( 1 + @p_geometry.STNumInteriorRing() ) )
      BEGIN
        IF ( @ringn = 0 )
          SET @geom = @p_geometry.STExteriorRing()
        ELSE
          SET @geom = @p_geometry.STInteriorRingN(@ringn);
        SET @pointn = 1;
        WHILE ( @pointn <= @geom.STNumPoints() )
        BEGIN
          SET @uniqn = @uniqn + 1;
          INSERT INTO @Points ( [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point] ) 
               VALUES ( @uniqn,
                        @pointn,
                        1,
                        @ringn + 1,
                        @geom.STPointN(@pointn).STX,
                        @geom.STPointN(@pointn).STY, 
                        @geom.STPointN(@pointn).Z,
                        @geom.STPointN(@pointn).M,
                        @geom.STPointN(@pointn) 
                      );
          SET @pointn = @pointn + 1;
        END;
        SET @ringn = @ringn + 1;
      END; 
      RETURN;
    END;
    
    IF ( @v_GeometryType = 'MultiPolygon' )
    BEGIN
      SET @uniqn = 0;
      SET @geomn  = 1;
      WHILE ( @geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @ringn  = 0;
        WHILE ( @ringn < ( 1 + @p_geometry.STGeometryN(@geomn).STNumInteriorRing() ) )
        BEGIN
          IF ( @ringn = 0 )
            SET @geom = @p_geometry.STGeometryN(@geomn).STExteriorRing()
          ELSE
            SET @geom = @p_geometry.STGeometryN(@geomn).STInteriorRingN(@ringn);
          SET @pointn = 1;
          WHILE ( @pointn <= @geom.STNumPoints() )
          BEGIN
            SET @uniqn = @uniqn + 1;
            INSERT INTO @Points ( [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point] ) 
                 VALUES ( @uniqn,
                          @pointn,
                          @geomn,
                          @ringn + 1,
                          @geom.STPointN(@pointn).STX,
                          @geom.STPointN(@pointn).STY, 
                          @geom.STPointN(@pointn).Z,
                          @geom.STPointN(@pointn).M,
                          @geom.STPointN(@pointn)
                        );
            SET @pointn = @pointn + 1;
          END;
          SET @ringn = @ringn + 1;
        END; 
        SET @geomn = @geomn + 1;
      END; 
      RETURN;
    END;
    
    IF ( @v_GeometryType = 'GeometryCollection' )
    BEGIN
      INSERT INTO @Points ( [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point] )
           SELECT row_number() over (order by a.IntValue,[rid],[pid]),
                  d.[pid],
                  a.IntValue,
                  d.[rid],
                  d.[x],d.[y],d.[z],d.[m],d.[point]
             FROM [$(owner)].[Generate_Series] (1, @p_geometry.STNumGeometries(), 1) as a
                  CROSS APPLY
                  [$(owner)].[STVertices](@p_geometry.STGeometryN(a.IntValue)) as d;
      RETURN;
    END;
  End;
  RETURN;
END
GO

