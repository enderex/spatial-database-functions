SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Testing [$(owner)].[STSegmentize] ...';
GO

select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326454.7 5455793.7 1,326621.3 5455813.7 2,326455.4 5455796.6 3,326454.7 5455793.7 4)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2, 3 3)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('LINESTRING(0 1 2 2.1, 2 3 2.1 3.4, 4 5 2.3 5.4, 6 7 2.2 6.7)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('POLYGON((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7))',28356) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5, 10 -10,15 -15)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('COMPOUNDCURVE((3 5, 3 3), CIRCULARSTRING(3 3, 5 1, 7 3), (7 3, 7 5), CIRCULARSTRING(7 5, 5 7, 3 5))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('COMPOUNDCURVE ((4 4, 3 3, 2 2, 0 0),CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0))',0) ) as v;
GO

