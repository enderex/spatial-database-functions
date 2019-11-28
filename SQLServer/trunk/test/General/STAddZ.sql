PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

PRINT 'Testing [$(owner).[STAddZ] ...';
GO

SELECT [$(owner)].[STAddZ] ( geometry::STGeomFromText('LINESTRING(0 0,0.5 0.5,1 1)',0), 1.232, 1.523, 3, 2).AsTextZM() as LineWithZ;
GO


