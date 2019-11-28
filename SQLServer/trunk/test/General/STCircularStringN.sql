PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

PRINT 'Testing [$(owner)].[STCircularStringN] ...';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) as p_geometry
)
SELECT NumStrings.IntValue as curveN,
       [$(owner)].[STCircularStringN](a.p_geometry, NumStrings.IntValue).AsTextZM() as cString
  FROM data as a
       cross apply
       [$(owner)].[generate_series](1,[$(owner)].[STNumCircularStrings](p_geometry),1) as NumStrings;
GO


