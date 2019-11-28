SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STDelete] ...';
GO

Select 'LineString - Last Point' as msg, [$(owner)].[STDelete](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),'-1',3,2).AsTextZM() as WKT;
GO

select 'MULTIPOLYGON Single Point - OK' as msg, 
       [$(owner)].[STDelete] ( geometry::STGeomFromText('MULTIPOLYGON (((0 0, 5 0, 10 0, 5 5, 0 0)),((20 20, 25 20, 30 20, 25 30, 20 20),(22 22, 25 26, 28 22, 22 22)))',0), '2',3,2).AsTextZM() as WKT;
GO

/*
select 'MULTIPOLYGON Two Points - Fail' as msg, 
       [$(owner)].[STDelete](
         geometry::STGeomFromText('MULTIPOLYGON (((0 0, 5 0, 10 0, 5 5, 0 0)),((20 20, 25 20, 30 20, 25 30, 20 20),(22 22, 25 26, 28 22, 22 22)))',0),
         '2,3',3,2) as t
GO
*/

