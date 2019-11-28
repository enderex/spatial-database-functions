SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STMulti] ...';
GO

select [$(owner)].[STMulti](geometry::STGeomFromText('POINT(1 1 1 1)',0)) as wkt;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0)) as WKT;
GO
Select [$(owner)].[STMulti](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0)) as wkt;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0)) as WKT;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872)',0)) as wkt;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('POLYGON((1 1,10 1,10 10,1 10,1 1),(2 2,9 2,9 9,2 9,2 2))',0)) as wkt;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0)) as WKT;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872))',0)) as wkt;
GO

SELECT f.mGeom.AsTextZM() as mGeom, f.mGeom.STNumGeometries() as numGeometries
  FROM (SELECT [$(owner)].[STMulti](geometry::STPointFromText('POINT(0 0)',0)) as mGeom
         UNION ALL
        SELECT [$(owner)].[STMulti](geometry::STGeomFromText ('POLYGON ((0 0,10 0,10 10,0 10,0 0))',0)) as mgeom
         UNION ALL
        SELECT [$(owner)].[STMulti](geometry::STGeomFromText ('LINESTRING(0 0,10 10,20 20)',0)) as mgeom
         UNION ALL
        SELECT [$(owner)].[STMulti](geometry::STGeomFromText('CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872)',0)) as mgeom
	 ) as f;
GO


