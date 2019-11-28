SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STOffsetSegment]...';
GO

-- LineString

With data as (
  select geometry::STGeomFromText('LINESTRING (3 6.3,0 7)',0) as segment
)
select test, pSegment.STBuffer(0.1) as geom from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STOffsetSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STOffsetSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;
GO

With data as (
  select geometry::STGeomFromText('LINESTRING (0 7,3 6.3)',0) as segment
)
select test, pSegment.STBuffer(0.1) as geom from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STOffsetSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STOffsetSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;
GO

-- Circular String
With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.3,0 7,-3 6.3)',0) as segment
)
select test, 
       pSegment.STBuffer(0.1) as geom, 
       pSegment.STAsText() as tGeom, 
       [$(cogoowner)].[STFindCircleFromArc](pSegment).AsTextZM() as circle
  from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STOffsetSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STOffsetSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;
GO

With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3,0 7,3 6.3)',0) as segment
)
select test, 
       pSegment.STBuffer(0.1) as geom, 
       pSegment.STAsText() as tGeom, 
       [$(cogoowner)].[STFindCircleFromArc](pSegment).AsTextZM() as circle 
  from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STOffsetSegment](d.segment, 1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STOffsetSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;
GO

-- *******************************************

With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.3,0 5.6,-3 6.3)',0) as segment
)
select test, pSegment.STBuffer(0.1) as geom from (
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STOffsetSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STOffsetSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;
GO

With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3,0 5.6,3 6.3)',0) as segment
)
select test, 
       pSegment.STBuffer(0.1) as geom, 
       pSegment.AsTextZM() as tgeom, 
       [$(cogoowner)].[STFindCircleFromArc](pSegment).AsTextZM() as circle 
  from (
select CONCAT('N:',g.IntValue) as test, d.segment.STPointN(g.IntValue).STBuffer(0.1) as pSegment from data as d cross apply dbo.generate_series(1,3,1) as g 
union all
select 'Before' as test, [$(cogoowner)].[STFindCircleFromArc](d.segment).STBuffer(0.1) as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STOffsetSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STOffsetSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;
GO

-- Point difference calculations....
With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3,0 5.6,3 6.3)',0) as segment
)
select 'Right' as test, 
       [$(owner)].[STOffsetSegment](d.segment, 1.0, 3, 1).STStartPoint().STDistance(d.segment.STStartPoint()) as startPointDist,
       [$(owner)].[STOffsetSegment](d.segment, 1.0, 3, 1).STPointN(2).STDistance(d.segment.STPointN(2)) as midPointDist,
       [$(owner)].[STOffsetSegment](d.segment, 1.0, 3, 1).STEndPoint().STDistance(d.segment.STEndPoint()) as endPointDist
from data as d
union all
select 'Left'  as test, 
       [$(owner)].[STOffsetSegment](d.segment,-1.0, 3, 1).STStartPoint().STDistance(d.segment.STStartPoint()) as startPointDist,
       [$(owner)].[STOffsetSegment](d.segment,-1.0, 3, 1).STPointN(2).STDistance(d.segment.STPointN(2)) as midPointDist,
       [$(owner)].[STOffsetSegment](d.segment,-1.0, 3, 1).STEndPoint().STDistance(d.segment.STEndPoint()) as endPointDist
from data as d;
GO

WITH data AS (
  SELECT geometry::STGeomFromText('CIRCULARSTRING (3 6.3,0 7,-3 6.3 )',0) as segment
  UNION ALL
  SELECT geometry::STGeomFromText('LINESTRING (-3 6.3,0 0)',0) as segment
)
SELECT 'Before'      as text, d.segment.AsTextZM() as rGeom from data as d
UNION ALL
SELECT 'After Right' as text, [$(owner)].[STOffsetSegment] (d.segment,1,3,2).AsTextZM() as rGeom from data as d
UNION ALL
SELECT 'After Left'  as text, [$(owner)].[STOffsetSegment] (d.segment,-1,3,2).AsTextZM() as rGeom from data as d;
GO

WITH data AS (
  SELECT geometry::STGeomFromText('CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3)',0) as segment
  UNION ALL
  SELECT geometry::STGeomFromText('LINESTRING (-3 6.3 1.1 9.3, 0 0 1.4 16.3)',0) as segment
)
SELECT 'Before' as text, d.segment.AsTextZM() as rGeom from data as d
UNION ALL
SELECT 'After' as text, [$(owner)].[STOffsetSegment] (d.segment,1,3,2).AsTextZM() as rGeom from data as d;
GO


