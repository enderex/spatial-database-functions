SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STExtractPolygon] ...';
GO

Print '1. All these return null as non of inputs are polygons ....';
go

select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('POINT(0 0)',0)).STAsText() as ePoly union all
select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0)).STAsText() as ePoly union all
select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0)).STAsText() as ePoly union all
select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)).STAsText() as ePoly;
GO

PRINT '2. These should extract only the polygons within the GeometryCollection.';
GO

-- (The second is wrapped as a GeometryCollection as a MultiPolygon cannot be constructed that includes a CurvePolygon
--
select e.gid, e.sid, e.geom.STAsText() as geomWKt
  from [$(owner)].[STExtract](
         [$(owner)].[STExtractPolygon](
           geometry::STGeomFromText(
             'GEOMETRYCOLLECTION(
                  LINESTRING(0 0,20 0,20 20,0 20,0 0), 
                  CURVEPOLYGON(
                       COMPOUNDCURVE(
                               (0 -23.43778, 0 23.43778),
                               CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
                               (-90 23.43778, -90 -23.43778),
                               CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), 
                  COMPOUNDCURVE(
                          CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), 
                          (0 -23.43778, 0 23.43778)
                  ),
                  POLYGON ((100 200, 180.00 300.00, 100 300, 100 200)), 
                  LINESTRING (100 200, 100 75), 
                  POINT (100 0))',0
             )
           ),0) as e;
GO

PRINT '3. Test the intersection between two polygons...';
GO

WITH data As (
SELECT geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) as geoma,
       geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0) as geomb
)
SELECT CAST('POLY A' as varchar(12)) as source, d.geoma.AsTextZM() as geoma from data as d
union all
SELECT 'POLY B' as source, d.geomb.AsTextZM() as geomb from data as d
union all
SELECT 'Intersection' as source, d.geoma.STIntersection(d.geomb).AsTextZM() as geom FROM data as d
union all
SELECT 'RESULT' as source, [$(owner)].[STExtractPolygon](d.geoma.STIntersection(d.geomb)).AsTextZM() as geom FROM data as d;
GO

