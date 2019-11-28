SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STGeometryTypes] ...';
GO

-- Simple geometry
select dbo.[STGeometryTypes](geometry::STGeomFromText('POINT(0 1 2)',0)) as gtypes;
GO

-- Single CurvePolygon with one interior ring
select [$(owner)].[STGeometryTypes](geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 5, 5 0, 0 -5, -5 0, 0 5), (-2 2, 2 2, 2 -2, -2 -2, -2 2))',0)) as gtypes;
GO

-- GeometryCollection
select  [$(owner)].[STGeometryTypes](geometry::STGeomFromText('GEOMETRYCOLLECTION( LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON( COMPOUNDCURVE( (0 -23.43778, 0 23.43778), CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE( CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0)) as gTypes;
GO

