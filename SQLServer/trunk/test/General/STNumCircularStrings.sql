PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

PRINT 'Testing [$(owner)].[STNumCircularStrings] ...';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) as cGeom
)
SELECT [$(owner)].[STNumCircularStrings](a.cGeom) as numStrings
  from data as a;
GO

