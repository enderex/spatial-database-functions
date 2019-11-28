SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STDeleteN] ...';
GO

select 'Single Point - No Action' AS message, [$(owner)].[STDeleteN](geometry::STGeomFromText('POINT(0 0 1 1)',0),1,3,2).AsTextZM() as WKT;
GO

select 'MultiPoint - No Action'   as message, [$(owner)].[STDeleteN](geometry::STGeomFromText('MULTIPOINT((0 0 1 1))',0),1,3,2).AsTextZM() as WKT;
GO

select 'MultiPoint - All Points'  as message, 
       t.IntValue,
       [$(owner)].[STDeleteN](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0),t.IntValue,3,2).AsTextZM() as WKT
  from [$(owner)].[generate_series](-1,4,1) as t;
GO

Select 'LineString - All Points' as message, 
       t.IntValue, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),t.IntValue,3,2).AsTextZM() as WKT 
  from [$(owner)].[generate_series](-1,5,1) as t;
GO

select 'MultiLineString - All Points' as message, 
       t.IntValue,
       [$(owner)].[STDeleteN](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0),t.IntValue,3,2).AsTextZM() as WKT
  from [$(owner)].[generate_series](-1,7,1) as t;
GO

with poly as (
  select geometry::STGeomFromText('POLYGON((326000.0 5455000.0,327000.0 5455000.0,326820 5455440,326500.0 5456000.0,326000.0 5455000.0))',0) as poly
)
select 'ExteriorRing -- Sufficient Points - Note first and last point avoided.' as message, 
       t.IntValue,
       [$(owner)].[STDeleteN](a.poly,t.intValue,3,2).AsTextZM() as t
  from poly as a cross apply [$(owner)].[generate_series](2,a.poly.STNumPoints()-1,1) as t;
GO

select 'SAME OUT' as message, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0),
                        3,3,2).AsTextZM() as WKT;
GO

Select 'LineString - Points' as message, 
       [$(owner)].[STDelete](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),'1,2',3,2).AsTextZM() as WKT ;
GO

Select 'LineString - Last Point' as message, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),-1,3,2).AsTextZM() as WKT ;
GO


