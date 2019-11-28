SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STCoordDim] ...';
GO

With Geoms As (
            select 1 as id, geometry::STGeomFromText('POINT(4 5)',0) as geom
  union all select 2 as id, geometry::STGeomFromText('MULTIPOINT((1 1 1))',0) as geom
  union all select 3 as id, geometry::STGeomFromText('MULTIPOINT((1 1 1),(2 2 2),(3 3 3))',0) as geom
  union all select 4 as id, geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
  union all select 5 as id, geometry::STGeomFromText('MULTILINESTRING((2 3, 3 4), (1 1, 2 2))',0) as geom
  union all select 5.1 as id, geometry::STGeomFromText('MULTILINESTRING((1 1 2 3,2 2 3 4),(3 3 4 5,4 4 5 6))',0) as geom
  union all select 5.2 as id, geometry::STGeomFromText('MULTILINESTRING((4 4 5 6,3 3 4 5),(2 2 3 4,1 1 2 3))',0) as geom
  union all select 6 as id, geometry::STGeomFromText('CIRCULARSTRING(0 -23.43778, 0 0, 0 23.43778)',0) as geom
  union all select 7 as id, geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 -23.43778, 0 0, 0 23.43778), CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), CIRCULARSTRING(-90 23.43778, -90 0, -90 -23.43778), CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))',0) as geom
  union all select 8 as id, geometry::STGeomFromText('COMPOUNDCURVE((0 -23.43778, 0 23.43778), CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)) ',0) as geom
  union all select  9 as id, geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0) as geom
  union all select 10 as id, geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0) as geom
  union all select 11 as id, geometry::STGeomFromText('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((30 30, 50 30, 50 50, 30 50, 30 30)), ((0 30, 20 30, 20 50, 0 50, 0 30)), ((30 0,31 0,31 1,30 1,30 0)))',0) as geom
  union all select 12 as id, geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5))',0) as geom
  union all select 13 as id, geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0) as geom
  union all select 14 as id, geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 50, 50 100, 100 50, 50 0, 0 50))',0) as geom
  union all select 15 as id, GEOMETRY::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE( (0 -23.43778, 0 23.43778), CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0) as geom 
)
select a.geom.AsTextZM() as geom, [$(owner)].[STCoordDim](a.geom) as cDim
 from Geoms as a;
GO

