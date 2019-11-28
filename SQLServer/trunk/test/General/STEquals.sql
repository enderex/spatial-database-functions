SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STEquals] ...';
GO

select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 0 1)',0), geometry::STGeomFromText('POINT(-4 -4 0 1)',1), 3,2,2);
GO

select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 0 1)',0), geometry::STGeomFromText('POINT(-4 -4 0 1)',0), 3,2,2);
GO

select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 NULL 1)',0), geometry::STGeomFromText('POINT(-4 -4 NULL 1)',0), 3,2,2);
GO

select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 NULL 1.1236)',0), geometry::STGeomFromText('POINT(-4 -4 NULL 1.124)',0), 3,2,2);
GO

select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 NULL 1.126)',0), geometry::STGeomFromText('POINT(-4 -4 NULL 1.124)',0), 3,2,2);
GO

