SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: COGO=$(cogoowner) owner=$(owner)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STDumpPoints]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STDumpPoints];
  PRINT 'Dropped [$(owner)].[STDumpPoints] ...';
END;
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STDump]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STDump];
  PRINT 'Dropped [$(owner)].[STDump] ...';
END;
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STDumpRings]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STDumpRings];
  PRINT 'Dropped [$(owner)].[STDumpRings] ...';
END;
GO

-- ***************************************************************************

PRINT 'Creating [$(owner)].[STDumpPoints] ...';
GO

CREATE FUNCTION [$(owner)].[STDumpPoints]
(
  @p_geometry geometry
)
Returns @Points TABLE
(
  uid   int,   /* Unique Point Id For Whole Geometry */
  pid   int,   /* Point Id within Part */
  mid   int,   /* Part Id */
  rid   int,   /* Ring Id - Polygon Only */
  x     float,
  y     float,
  z     float,
  m     float,
  point geometry
)
AS
/****f* GEOPROCESSING/STDumpPoints (2008)
 *  NAME
 *   STDumpPoints - Dumps all vertices of supplied geometry object to ordered array.
 *  SYNOPSIS
 *   Function [$(owner)].[STDumpPoints] (
 *       @p_geometry  geometry 
 *    )
 *    Returns @Points Table (
 *      uid   int,
 *      pid   int,
 *      mid   int,
 *      rid   int,
 *      x     float,  
 *      y     float,
 *      z     float,
 *      m     float,
 *      point geometry
 *    )  
 *  EXAMPLE
 *    -- Points from multipolygon
 *    SELECT e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
 *      FROM [$(owner)].[STDumpPoints] (
 *             geometry::STGeomFromText(
 *               'MULTIPOLYGON( ((200 200, 400 200, 400 400, 200 400, 200 200)),
 *                              ((0 0, 100 0, 100 100, 0 100, 0 0),(40 40,60 40,60 60,40 60,40 40)) )',0)
 *           ) as e
 *    GO
 *    uid mid rid pid   x   y    z    m
 *      1   1   1   1 200 200 NULL NULL
 *      2   1   1   2 400 200 NULL NULL
 *      3   1   1   3 400 400 NULL NULL
 *      4   1   1   4 200 400 NULL NULL
 *      5   1   1   5 200 200 NULL NULL
 *      6   2   1   1   0   0 NULL NULL
 *      7   2   1   2 100   0 NULL NULL
 *      8   2   1   3 100 100 NULL NULL
 *      9   2   1   4   0 100 NULL NULL
 *     10   2   1   5   0   0 NULL NULL
 *     11   2   2   1  40  40 NULL NULL
 *     12   2   2   2  60  40 NULL NULL
 *     13   2   2   3  60  60 NULL NULL
 *     14   2   2   4  40  60 NULL NULL
 *     15   2   2   5  40  40 NULL NULL
 *  DESCRIPTION
 *    This function extracts the fundamental points that describe a geometry object.
 *  NOTES
 *    This is a wrapper function over STVertices
 *  INPUTS
 *    @p_geometry (geometry) - Any non-point geometry object
 *  RESULT
 *    Table (Array) of Points :
 *     uid (int)   - Unique Point identifier across whole geometry
 *     pid (int)   - Point identifier with element/subelement (1 to Number of Points in element).
 *     mid (int)   - Unique identifier that describes the geometry object's elements (eg linestring in MultiLineString).
 *     rid (int)   - SubElement or Ring identifier.
 *     x   (float) - Start Point X Ordinate 
 *     y   (float) - Start Point Y Ordinate 
 *     z   (float) - Start Point Z Ordinate 
 *     m   (float) - Start Point M Ordinate
 *     point (geometry) - x,y,z,m as geometry
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2008 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
   INSERT INTO @Points ( 
          [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point]
   )
   SELECT [uid],[pid],[mid],[rid],[x],[y],[z],[m],[point]
     FROM [$(owner)].[STVertices](@p_geometry);
   RETURN;
End;
Go

-- *******************************************************************************************

PRINT 'Creating [$(owner)].[STDump] ...';
GO

CREATE FUNCTION [$(owner)].[STDump]
(
  @p_geometry geometry
)
Returns @geometries TABLE 
(
  id   integer,
  geom geometry
)  
AS
/****f* GEOPROCESSING/STDump (2012)
 *  NAME
 *    STDump -- Extracts the subelements that describe the input geometry.
 *  SYNOPSIS
 *    Function [$(owner)].[STDump](
 *               @p_geometry geometry
 *             )
 *     Returns @geometries TABLE 
 *     (
 *       id   integer,
 *       geom geometry
 *     )  
 *  DESCRIPTION
 *    This function allows a user to extract the subelements of the supplied geometry.
 *    Some geometries have no subelements: eg Point, LineString
 *    The subelements of a geometry change depending on the geometry type: 
 *      1. A MultiPoint only has one or more Point subelements; 
 *      2. A MultiLineString only more than one LineString subelements; 
 *      3. A Polygon has zero one or more inner rings and only one outer ring;
 *      4. A MultiPolygon has zero one or more inner rings and one or more outer rings;
 *    Some subelements can have subelements when they are Compound:
 *      1. A CircularCurve can be described by one or more three point circular arcs.
 *    If subelements exist they are extracted and returned.
 *  NOTES
 *    This version is for versions of SQL Server from 2012 onwards.
 *
 *    This version is a wrapper over STExtract to mirror the PostGIS function.
 *  INPUTS
 *    @p_geometry (geometry) - (Multi)geometry or geometryCollection object.
 *  EXAMPLE
 *    -- MultiPoint
 *    SELECT d.id, d.geom.AsTextZM() as geom
 *      FROM [$(owner)].[STDump] (geometry::STGeomFromText('MULTIPOINT((0 0),(10 0),(10 10),(0 10),(0 0))',0)) as d;
 *    GO
 *    
 *    id   geom
 *    1    POINT (0 0)
 *    2    POINT (10 0)
 *    3    POINT (10 10)
 *    4    POINT (0 10)
 *    5    POINT (0 0)
 *    -- Polygon with hole
 *    SELECT d.id, d.geom.AsTextZM() as geom
 *      FROM [$(owner)].[STDump] (geometry::STGeomFromText('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 9 1,9 9,1 9,1 1))',0)) as d;
 *    GO
 *
 *    id   geom
 *    1    POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))
 *    2    POLYGON ((1 1, 9 1, 9 9, 1 9, 1 1))
 *    
 *    -- 2 Polygons, one with hole.
 *    SELECT d.id, d.geom.AsTextZM() as geom
 *      FROM [$(owner)].[STDump] (geometry::STGeomFromText('MULTIPOLYGON(((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 9 1,9 9,1 9,1 1)),((100 100,110 100,110 110, 100 110,100 100)))',0)) as d;
 *    GO
 *    
 *    id   geom
 *    1    POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))
 *    2    POLYGON ((1 1, 9 1, 9 9, 1 9, 1 1))
 *    3    POLYGON ((100 100, 110 100, 110 110, 100 110, 100 100))
 *    
 *    SELECT d.id, d.geom.AsTextZM() as geom
 *      FROM [$(owner)].[STDump] (geometry::STGeomFromText('GEOMETRYCOLLECTION (POLYGON ((100 200, 180 300, 100 300, 100 200)), LINESTRING (100 200, 100 75), POINT (100 0))',0)) as d;
 *    GO
 *    
 *    id   geom
 *    1    POLYGON ((100 200, 180 300, 100 300, 100 200))
 *    2    LINESTRING (100 200, 100 75)
 *    3    POINT (100 0)
 *    
 *    -- MultiLineString
 *    SELECT d.id, d.geom.AsTextZM() as geom
 *      FROM [$(owner)].[STDump] (geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0)) as d;
 *    GO
 *    
 *    id   geom
 *    1    LINESTRING (0 0, 5 5, 10 10, 11 11, 12 12)
 *    2    LINESTRING (100 100, 200 200)
 *    
 *    -- geometryCollection
 *    SELECT d.id, d.geom.AsTextZM() as geom
 *      FROM [$(owner)].[STDump] (geometry::STGeomFromText('GEOMETRYCOLLECTION (COMPOUNDCURVE(CIRCULARSTRING (3 6.32, 0 7, -3 6.32),(-3 6.32, 0 0, 3 6.32)))',0)) as d;
 *    GO
 *    
 *    id   geom
 *    1    CIRCULARSTRING (3 6.32, 0 7, -3 6.32)
 *    2    LINESTRING (-3 6.32, 0 0)
 *    3    LINESTRING (0 0, 3 6.32)
 *  RESULT
 *    Array of subelements:
 *    id  - Unique identifier ordered from first element to las.
 *    geom - Geometry representation of element.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2019
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  INSERT INTO @geometries ( [id],[geom] ) 
       SELECT row_number() over (order by [gid],[sid]) as id,
              [geom]
         FROM [$(owner)].[STExtract](@p_geometry,1) as e;
  RETURN;
END;
GO

-- ************************************************************************************

PRINT 'Creating [$(owner)].[STDumpRings] ...';
GO

CREATE FUNCTION [$(owner)].[STDumpRings] 
(
  @p_geometry geometry
)
Returns @rings TABLE
(
  gid  integer,
  rid  integer,
  geom geometry
)  
AS
/****f* GEOPROCESSING/STDumpRings (2012)
 *  NAME
 *    STDumpRings -- Dumps the rings of a CurvePolygon, Polygon or MultiPolygon
 *  SYNOPSIS
 *    Function [dbo].[STDumpRings] (
 *               @p_geometry geometry
 *             )
 *     Returns @rings TABLE
 *     (
 *       gid  integer,
 *       sid  integer,
 *       geom geometry
 *     )  
 *  DESCRIPTION
 *    This function allows a user to extract all the rings of the supplied (multi)polygon.
 *    This function is a wrapper over STExtract.
 *  INPUTS
 *    @p_geometry (geometry) - CurvePolygon, Polygon or MultiPolygon geometry object.
 *  RESULT
 *    Array of subelements:
 *    gid  - Unique ring identifier starting at first and ending at last in order exist within (multi)polygon
 *    rid  - Ring id within polygon element (id)
 *    geom - Geometry representation of subelement.
 *  NOTES
 *    Depends on STExtract.
 *  EXAMPLE
 *    -- Polygon with one exterior ring and two interior rings
 *    SELECT t.gid, t.rid, t.geom.STAsText() as geom
 *      FROM [dbo].[STDumpRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as t
 *    GO
 *    
 *    gid rid geom
 *    1   1   POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))
 *    1   2   POLYGON ((10 10, 10 11, 11 11, 11 10, 10 10))
 *    1   3   POLYGON ((5 5, 5 7, 7 7, 7 5, 5 5))
 *
 *    -- Multi Polygon with 3 exterior rings, with one with 2 interior rings 
 *    select d.gid,d.rid,d.geom.STAsText() as geom 
 *      from [dbo].[STDumpRings](geometry::STGeomFromText(
 *                'MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), 
 *                               ((80 80, 100 80, 100 100, 80 100, 80 80)), 
 *                               ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as d
 *
 *    GO
 *    gid rid geom
 *    1   1   POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))
 *    1   2   POLYGON ((10 10, 10 11, 11 11, 11 10, 10 10))
 *    1   3   POLYGON ((5 5, 5 7, 7 7, 7 5, 5 5))
 *    2   1   POLYGON ((80 80, 100 80, 100 100, 80 100, 80 80))
 *    3   1   POLYGON ((110 110, 150 110, 150 150, 110 150, 110 110))
 *
 *    -- Single Polygon with exterior ring only
 *    select d.gid,d.rid,d.geom.STAsText() as geom 
 *      from [dbo].[STDumpRings](geometry::STGeomFromText(
 *               'CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0)) as d
 *    GO
 *
 *    gid rid geom
 *    1   1   CURVEPOLYGON (COMPOUNDCURVE ((0 -23.43778, 0 23.43778), CIRCULARSTRING (0 23.43778, -45 23.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING (-90 -23.43778, -45 -23.43778, 0 -23.43778)))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan  2013 - Original coding.
 *    Simon Greener - Jan  2015 - Port to TSQL SQL Server
 *    Simon Greener - July 2019 - Modfied to return only id and geom and no subelements.
 *    Simon Greener - October 2019 - Modfied to use STExplode; return more geom/ring identifiers.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geom geometry;
  Begin
    If ( @p_geometry is NULL ) 
      return;
    IF ( @p_geometry.STGeometryType() NOT IN ('GeometryCollection','CurvePolygon','Polygon','MultiPolygon') )
      return;
    IF ( @p_geometry.STGeometryType() = 'GeometryCollection' )
      SET @v_geom = [$(owner)].[STExtractPolygon](@p_geometry)
    ELSE
      SET @v_geom = @p_geometry;
    INSERT INTO @rings ( [gid],[rid],[geom] )
    SELECT e.[gid],
           e.[sid] as rid,
           e.[geom]
      FROM [$(owner)].[STExtract](@v_geom,1/*Rings*/) as e;
    RETURN;
  End;
End;
Go

