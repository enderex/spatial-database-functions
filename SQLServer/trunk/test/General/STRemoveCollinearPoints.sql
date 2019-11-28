PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

PRINT 'Testing [$(owner)].[STRemoveCollinearPoints] ...';
GO

select [$(owner)].[STRemoveCollinearPoints]( geometry::STGeomFromText('LINESTRING(0 0,1 1,2 2)',0),1.0,3,2,1) as angle;
GO

select [$(owner)].[STRemoveCollinearPoints] (geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,2.1 0,2.2 0.0,2.3 0,3 0)',0),1.0,3,2,1) as cleanedLine ;
GO

