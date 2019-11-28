SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing STConvertToLineString ...';
GO

With gc As (
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION (MULTILINESTRING((0 0,20 0),(20 20,0 20,0 0)))', 0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0),LINESTRING(1 1,2 2),LINESTRING(3 3,19 19),POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(MULTILINESTRING((0 0,20 0),(20 20,0 20,0 0)), LINESTRING(1 1,2 2),LINESTRING(3 3,19 19),POINT(0 0),POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
)
SELECT [$(owner)].[STConvertToLineString](geom) as geom,
       [$(owner)].[STConvertToLineString](geom).STAsText() as geomWKT
  from gc as a;
GO

