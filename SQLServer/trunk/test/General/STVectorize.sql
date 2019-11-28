SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing .....';
GO

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE EMPTY',0)) as v;
go
  
select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('LINESTRING(0 0,5 5)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('LINESTRING(0 0,5 5,10 10,15 15,20 20)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10),(11 11, 12 12))',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5, 10 -10,15 -15)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CIRCULARSTRING(0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE((3 5, 3 3), CIRCULARSTRING(3 3, 5 1, 7 3), (7 3, 7 5), CIRCULARSTRING(7 5, 5 7, 3 5))',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE ((4 4, 3 3, 2 2, 0 0),CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0))',0)) as v;
GO

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(7 5 4 2, 5 7 4 2, 3 5 4 2), (3 5 4 2, 8 7 4 2))',0)) as v;
GO

select v.* 
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246), CIRCULARSTRING(3 6.3246, 0 7, -3 6.3246), CIRCULARSTRING(-3 6.3246, -1 2.1082, 0 0))',0)) as v;
GO
  
select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))',0)) as v;
GO

select v.*, v.geom.STBuffer(1) as vector
  from [$(owner)].[STVectorize](geometry::STGeomFromText('POLYGON ((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as v;
GO

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80),(85 85, 100 85, 90 90, 85 90, 85 85)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

select v.* 
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

-- Single CurvePolygon with one interior ring
select  v.*, v.geom.STBuffer(1)
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 5, 5 0, 0 -5, -5 0, 0 5), (-2 2, 2 2, 2 -2, -2 -2, -2 2))',0)) as v;
GO

-- GeometryCollection
select  v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('GEOMETRYCOLLECTION( LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON( COMPOUNDCURVE( (0 -23.43778, 0 23.43778), CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE( CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0)) as v;
GO


