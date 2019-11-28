SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STDumpPoints] ...';
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('POINT(0 1 2 3)',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('LINESTRING(2 3 4,3 4 5)',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('POLYGON ((0 0, 100 0, 100 100, 0 100, 0 0))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints] (geometry::STGeomFromText('MULTIPOLYGON( ((200 200, 400 200, 400 400, 200 400, 200 200)), ((0 0, 100 0, 100 100, 0 100, 0 0),(40 40,60 40,60 60,40 60,40 40)))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('POLYGON((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400, 2300 200, 2100 100, 2500 100, 2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700), (2300 1000, 2400  900, 2200 900, 2300 1000))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('MULTILINESTRING((2 3 4,3 4 5),(1 1,2 2))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('MULTIPOINT((1 1),(2 2),(3 3))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('MULTIPOLYGON (((200 200, 400 200, 400 400, 200 400, 200 200)),((0 0, 100 0, 100 100, 0 100, 0 0)),((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400, 2300 200, 2100 100, 2500 100, 2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700),(2300 1000, 2400  900, 2200 900, 2300 1000)))',0)) as e;
GO

select e.[uid], e.[pid], e.[mid], e.[rid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),POINT(4 5),MULTIPOINT((1 1),(2 2),(3 3)),LINESTRING(2 3 4,3 4 5),MULTILINESTRING((2 3 4,3 4 5),(1 1,2 2)),POLYGON((0 0 0, 100 0 1, 100 100 2, 0 100 3, 0 0 4)),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)),MULTIPOLYGON(((200 200, 400 200, 400 400, 200 400, 200 200)), ((0 0, 100 0, 100 100, 0 100, 0 0), (40 40,60 40,60 60,40 60,40 40))))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STDumpPoints]([$(owner)].[STToGeometry](geography::STGeomFromText('POLYGON((148.0 -44.0, 148.0 -43.0, 147.0 -43.0, 147.0 -44.0, 148.0 -44.0), (147.4 -43.6, 147.2 -43.6, 147.2 -43.2, 147.4 -43.2, 147.4 -43.6))',4326),0)) as e;
GO

select t.*
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('COMPOUNDCURVE ((-4 -4 NULL 0, 0 0 NULL 5.657, 10 0 NULL 15.657), CIRCULARSTRING (10 0 NULL 15.657, 10 5 NULL 20.657, 20 10 NULL 38.162), (20 10 NULL 38.162, 21 11 NULL 39.577, 22 12 NULL 35.991))',0)) as t;
GO

-- ****************************************************************************
PRINT 'Testing [$(owner)].[STDump] ...';
GO

-- MultiPoint 
SELECT d.id, d.geom.AsTextZM() as geom FROM [$(owner)].[STDump] ( geometry::STGeomFromText('MULTIPOINT((0 0),(10 0),(10 10),(0 10),(0 0))',0)) as d;
GO

-- id   geom
-- 1    POINT (0 0)
-- 2    POINT (10 0)
-- 3    POINT (10 10)
-- 4    POINT (0 10)
-- 5    POINT (0 0)

-- Polygon with hole
SELECT d.id, geom.AsTextZM() as geom FROM [$(owner)].[STDump] ( geometry::STGeomFromText('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 9 1,9 9,1 9,1 1))',0)) as d;
GO

-- id   geom
-- 1    POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))
-- 2    POLYGON ((1 1, 9 1, 9 9, 1 9, 1 1))

-- 2 Polygons, one with hole.
SELECT d.id, d.geom.AsTextZM() as geom FROM [$(owner)].[STDump] ( geometry::STGeomFromText('MULTIPOLYGON(((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 9 1,9 9,1 9,1 1)),((100 100,110 100,110 110, 100 110,100 100)))',0)) as d;
GO

-- id   geom
-- 1    POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))
-- 2    POLYGON ((1 1, 9 1, 9 9, 1 9, 1 1))
-- 3    POLYGON ((100 100, 110 100, 110 110, 100 110, 100 100))

SELECT d.id, d.geom.AsTextZM() as geom FROM [$(owner)].[STDump] ( geometry::STGeomFromText('GEOMETRYCOLLECTION (POLYGON ((100 200, 180 300, 100 300, 100 200)), LINESTRING (100 200, 100 75), POINT (100 0))',0)) as d;
GO

-- id   geom
-- 1    POLYGON ((100 200, 180 300, 100 300, 100 200))
-- 2    LINESTRING (100 200, 100 75)
-- 3    POINT (100 0)

-- MultiLineString
SELECT d.id, d.geom.AsTextZM() as geom FROM [$(owner)].[STDump] (geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0)) as d;
GO

-- id   geom
-- 1    LINESTRING (0 0, 5 5, 10 10, 11 11, 12 12)
-- 2    LINESTRING (100 100, 200 200)

-- geometryCollection
SELECT d.id, d.geom.AsTextZM() as geom FROM [$(owner)].[STDump] (geometry::STGeomFromText('GEOMETRYCOLLECTION (COMPOUNDCURVE(CIRCULARSTRING (3 6.32, 0 7, -3 6.32),(-3 6.32, 0 0, 3 6.32)))',0)) as d;
GO

-- id    geom
-- 1    CIRCULARSTRING (3 6.32, 0 7, -3 6.32)
-- 2    LINESTRING (-3 6.32, 0 0)
-- 3    LINESTRING (0 0, 3 6.32)

-- ****************************************************

PRINT 'Testing [$(owner)].[STDumpRings]...';
go

select d.gid,d.rid,d.geom.STAsText() as geom from [$(owner)].[STDumpRings](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as d ;
GO

-- id geom -- ie no rows

-- Polygon
select d.gid,d.rid,d.geom.STAsText() as geom from [$(owner)].[STDumpRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as d;
GO

-- MultiPolygon with 3 Exterior rings and 2 interior rings
select d.gid,d.rid,d.geom.STAsText() as geom from [$(owner)].[STDumpRings](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((80 80, 100 80, 100 100, 80 100, 80 80)),((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as d;
GO

-- Single CurvePolygon with exterior ring only
select d.gid,d.rid,d.geom.STAsText() as geom from [$(owner)].[STDumpRings](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0)) as d;
GO

-- GeometryCollection with one internal Polygon
select d.gid,d.rid,d.geom.STAsText() as geom from [$(owner)].[STDumpRings](geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0),CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))),COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0)) as d;
GO

