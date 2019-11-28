SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STUpdate] ...';
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('POINT(0 0 1 1)',0),
                             geometry::STGeomFromText('POINT(0 0 1 1)',0),
                             geometry::STGeomFromText('POINT(1 1 1 1)',0),2,1).AsTextZM() as WKT;
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0),
                             geometry::STGeomFromText('POINT(2 2 2 2)',0),
                             geometry::STGeomFromText('POINT(2.1 2.1 2 2)',0),2,1).AsTextZM() as WKT;
GO

Select [$(owner)].[STUpdate](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),
                             geometry::STGeomFromText('POINT(3 3)',0), 
                             geometry::STGeomFromText('POINT(2.1 2.5)',0),2,1).AsTextZM() as WKT;
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0),
                             geometry::STGeomFromText('POINT(3 3)',0),
                             geometry::STGeomFromText('POINT(3.1 3.3)',0),2,1).AsTextZM() as WKT;
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872))',0),
                              geometry::STGeomFromText('POINT(9.962 0.872)',0),
                              geometry::STGeomFromText('POINT(9.9 0.9)',0),2,1).AsTextZM() as WKT;
GO

-- 'Polygon - First and lat point of ring update.
select [$(owner)].[STUpdate](geometry::STGeomFromText('POLYGON((1 1,10 1,10 10,1 10,1 1),(2 2,9 2,9 9,2 9,2 2))',0),
                             geometry::STGeomFromText('POINT(1 1)',0),
                             geometry::STGeomFromText('POINT(1.1 1.1)',0),2,1).AsTextZM() as WKT;
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0))',28355),
                             geometry::STGeomFromText('POINT(326000.0 5455000.0)',28355),
                             geometry::STGeomFromText('POINT(326100.0 5455100.0)',28355),2,1).AsTextZM() as WKT;
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0),
                             geometry::STGeomFromText('POINT(3 4 5)',0),
                             geometry::STGeomFromText('POINT(3.1 4.1 5.1)',0),2,1).AsTextZM() as WKT;
GO


