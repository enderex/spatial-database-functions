SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$owner)].[STIsMeasured] ...';

WITH data AS (
 select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as Geom
 union all
 select geometry::STGeomFromText('LINESTRING(0 0, 100 100)',0) 
 union all
 select geometry::STGeomFromText('LINESTRING(0 0 0.1, 100 100 99.8)',0) 
 union all
 select geometry::STGeomFromText('LINESTRING(0 0 0 0.1, 100 100 0 99.8)',0) 
 union all
 select geometry::STPointFromText('POINT(0 0)',0) 
 union all
 select geometry::STPointFromText('POINT(0 0 1.1)',0) 
 union all
 select geometry::STPointFromText('POINT(0 0 1.1 2.2)',0) 
)
SELECT d.geom.STGeometryType() as gType, 
       [$(owner)].[STCoordDim](d.geom) as cDim,
       [$(lrsowner)].[STIsMeasured]( d.geom ) as isMeasured
  FROM data as d;
GO

