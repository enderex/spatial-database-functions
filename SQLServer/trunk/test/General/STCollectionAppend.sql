SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STCollectionAppend] ...';
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('POINT(0 0)',0),
  geometry::STGeomFromText('POINT(1 1)',0),
  1
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('POINT(1 1)',0),
  1
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  NULL,
  geometry::STGeomFromText('POINT(1 1)',0),
  0
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('LINESTRING EMPTY',0),
  geometry::STGeomFromText('POINT(1 1)',0),
  0
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('POINT(1 1)',0),
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  0
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('LINESTRING(0 0,1 1)',0),
  1
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('POLYGON((0 0,1 0,1 1,0 1,0 0))',0),
  0
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('POLYGON((0 0,1 1,1 0,0 1,0 0))',0),
  0
).AsTextZM();
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(1 1),LINESTRING(1 1,2 2))',0),
  1
).AsTextZM();
GO

