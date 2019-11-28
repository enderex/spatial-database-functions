SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STMove] ...';
GO

-- Point
select [$(owner)].[STMove](geometry::STPointFromText('POINT(0 0)',0),-5.0,30.1,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'POINT(-5 30.1)'

-- MultiPoint
SELECT [$(owner)].[STMove](geometry::STGeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),-100,-3000,default,default,2,1).STAsText() as rGeom;
GO
-- # rGeom
-- 'MULTIPOINT((0.12 -2899.65),(288.84 -2500.6))'

-- Linestring
select [$(owner)].[STMove](geometry::STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),-5.0,30.1,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'LINESTRING(-4.9 30.2,-3.6 75.3)'

-- Polygon
select [$(owner)].[STMove](geometry::STGeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),-5.0,30.1,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'POLYGON((-5 30.1,5 30.1,5 40.1,-5 40.1,-5 30.1))'

select [$(owner)].[STMove](
         geometry::STGeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          -50,-100,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'MULTIPOLYGON(((110 300,150 300,150 380,110 380,110 300)),((50 100,130 200,50 200,50 100)))'


