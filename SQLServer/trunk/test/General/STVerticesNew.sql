SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing .....';
GO

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('POINT(0 1)',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('POINT(0 1 2 3)',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('LINESTRING(0 0,5 5)',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('LINESTRING(0 0,5 5,10 10,15 15,20 20)',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10),(11 11, 12 12))',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5, 10 -10,15 -15)',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('CIRCULARSTRING(0 0,3 0,1 2.1082,3 6.3246, 0 7,-3 6.3246, -1 2.1082,-3 0,0 0)',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('COMPOUNDCURVE EMPTY',0)) as v;
go
  
-- FIX 
select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('COMPOUNDCURVE((3 5, 3 3), CIRCULARSTRING(3 3, 5 1, 7 3), (7 3, 7 5), CIRCULARSTRING(7 5, 5 7, 3 5))',0)) as v;
go

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('COMPOUNDCURVE ((4 4, 3 3, 2 2, 0 0),CIRCULARSTRING(0 0,3 0,1 2.1082,3 6.3246, 0 7,-3 6.3246, -1 2.1082,-3 0,0 0))',0)) as v;
GO

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(7 5 4 2, 5 7 4 2, 3 5 4 2), (3 5 4 2, 8 7 4 2))',0)) as v;
GO

select v.* 
  from [dbo].[STVertices](geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (0 0, 3 3, 3 6.3246), CIRCULARSTRING(3 6.3246, 0 7, -3 6.3246), CIRCULARSTRING(-3 6.3246, -3 3, 0 0))',0)) as v;
GO

select v.*, v.point as vector
  from [dbo].[STVertices](geometry::STGeomFromText('POLYGON ((0 0,20 0,20 20,0 20,0 0))',0)) as v;
GO
  
select v.*, v.point as vector
  from [dbo].[STVertices](geometry::STGeomFromText('POLYGON ((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as v;
GO

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

select v.*
  from [dbo].[STVertices](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80),(85 85, 100 85, 90 90, 85 90, 85 85)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

select v.* 
  from [dbo].[STVertices](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

-- Single CurvePolygon with one interior ring
-- FIX
select  v.*, v.point
  from [dbo].[STVertices](geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 5, 5 0, 0 -5, -5 0, 0 5), (-2 2, 2 2, 2 -2, -2 -2, -2 2))',0)) as v;
GO

-- Single CurvePolygon with one interior ring both described using CompoundCurves.

select  v.*
  from [dbo].[STVertices](geometry::STGeomFromText('CURVEPOLYGON (COMPOUNDCURVE (CIRCULARSTRING (-45 -27.437779999999755, -22.411286003846982 -26.435812456721468, 0 -23.43778), (0 -23.43778, 0 23.43778), CIRCULARSTRING (0 23.43778, -45 27.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING (-90 -23.43778, -67.5887139961527 -26.435812456721468, -45 -27.437779999999755)), COMPOUNDCURVE ((-10 -16.43778, -80 -15.43778), CIRCULARSTRING (-80 -15.43778, -45 0, -10 -16.43778)))',0)) as v;
GO

-- GeometryCollection
-- FIX 
select  v.*
  from [dbo].[STVertices](geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON( COMPOUNDCURVE( (0 -23.43778, 0 23.43778), CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0)) as v;
GO

select geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 5, 5 0, 0 -5, -5 0, 0 5), (-2 2, 2 2, 2 -2, -2 -2, -2 2))',0).STExteriorRing().STNumCurves() as v;
GO

with Tractgeom as (
select 1 as id_tract, geometry::STGeomFromText('MULTILINESTRING((0.02345 0.01278,5.123 5.456,10.9876 10.1738),(11.00123 11.456, 12.345 12.02))',0) as geom
)
, rtract as (
select 1 as id_tract, CAST(null as geometry) as geom
)
Select dbo.STRound(d.geom,1,1,0,0).MakeValid().STAsText() as geom
  From Tractgeom tg join rtract rt on tg.id_tract=rt.id_tract
       Cross apply
       [dbo].[STDump](coalesce(tg.geom, rt.geom)) as d;
GO
