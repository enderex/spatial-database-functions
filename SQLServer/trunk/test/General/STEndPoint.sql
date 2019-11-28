SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STEndPoint] ...';
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('POINT(0 0 0)',0)).AsTextZM() as ENDPOINT;
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('MULTIPOINT((0 0 0),(1 1 1))',0)).AsTextZM() as ENDPOINT;
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0)).AsTextZM() as ENDPOINT;
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('MULTILINESTRING((2 3, 3 4), (1 1, 2 2))',0)).AsTextZM() as ENDPOINT;
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)).AsTextZM() as ENDPOINT;
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0)).AsTextZM() as ENDPOINT;
GO


