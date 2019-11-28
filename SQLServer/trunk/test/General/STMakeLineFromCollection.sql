SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STMakeLineFromGeometryCollection] ...';
GO

select [$(owner)].[STMakeLineFromGeometryCollection](geometry::STGeomFromText('GEOMETRYCOLLECTION (POINT (148.13461 -35.29305), POINT (148.13443 -35.29315))',4283),3,2).AsTextZM() as linestring;
GO

SELECT [$(owner)].[STMakeLineFromGeometryCollection](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0),POINT(10 10))',28355),3,2).STAsText() as line;
GO

SELECT [$(owner)].[STMakeLineFromGeometryCollection](geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 5),LINESTRING(3 10,6 -5))',0),3,2).STAsText() as line;
GO


