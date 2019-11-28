SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STNumRings] ...';
GO

          select 'Point' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('POINT(0 0)',0)) as numRings
union all select 'MultiPoint' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0)) as numRings
union all select 'LineString' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0)) as numRings
union all select 'MultiLineString' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as numRings
union all select 'Polygon Outer' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0))',0)) as numRings
union all select 'Polygon' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as numRings
union all select 'MultiPolygon' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as numRings
union all select 'CurvePolygon' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0)) as numRings
union all select 'GeometryCollection' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('GEOMETRYCOLLECTION(CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0)) as numRings;
GO


