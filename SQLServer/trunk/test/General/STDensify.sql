SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STDensify] ...';
GO

-- Densify 2D line into 4 segments
with data as (
select geometry::STGeomFromText('LINESTRING(0 0,10 10)',0) as geom
)
select [$(owner)].[STDensify](a.geom,a.geom.STLength()/4.0,3,2).AsTextZM() as dGeom from data as a;
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
select [$(owner)].[STDensify](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0), 4.0, 3,2).AsTextZM() as dGeom;
GO

-- MultiPolygon
select [$(owner)].[STDensify](geometry::STGeomFromText('MULTIPOLYGON(((100 100,110 100,110 110,100 110,100 100)),((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)))',0), 4.0, 3,2).AsTextZM() as dGeom;
GO

