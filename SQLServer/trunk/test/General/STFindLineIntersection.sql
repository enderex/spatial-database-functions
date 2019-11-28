SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[STFindLineIntersection] ...';
GO

Print '1. Crossed Lines ...';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection](0,0,10,10,0,10,10,0) as intersections ) as f;
GO

Print '2. Extended Intersection ...';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection](0,0,10,10,0,10,4,6) as intersections ) as f;
GO

Print '3. Parallel Lines (meet at single point)....';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection] (0,0,10,0, 0,20,10,0) as intersections ) as f;
GO

Print '4. Parallel Lines that do not meet at single point....';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection] (0,0,10,0, 0,1,10,1) as intersections ) as f;
GO

Print 'Testing [$(cogoowner)].[STFindLineIntersectionBySegment]: ';
GO

SELECT [$(cogoowner)].[STFindLineIntersectionBySegment] (
          geometry::STLineFromText('LINESTRING(0 0,10 10)',0),
          geometry::STLineFromText('LINESTRING(0 10,10 0)',0)
       ).AsTextZM() as intersection;
GO

Print 'Testing [$(cogoowner)].[STFindLineIntersectionDetails]: ';
GO

with data as (
select -20 as offset, geometry::STGeomFromText('LINESTRING (0 20, 20 20)',0) as first_segment, geometry::STGeomFromText('LINESTRING (0 0, 0 10)',0) as second_segment
union all
select -10 as offset, geometry::STGeomFromText('LINESTRING (0 10, 20 10)',0) as first_segment, geometry::STGeomFromText('LINESTRING (10 0, 10 10)',0) as second_segment
union all
select  -5 as offset, geometry::STGeomFromText('LINESTRING (0 5, 20 5)',0) as first_segment, geometry::STGeomFromText('LINESTRING (15 0, 15 10)',0) as second_segment
union all
select   0 as offset, geometry::STGeomFromText('LINESTRING (0 0, 20 0)',0) as first_segment, geometry::STGeomFromText('LINESTRING (20 0, 20 10)',0) as second_segment
union all
select -15 as offset, geometry::STGeomFromText('LINESTRING (0 15, 20 15)',0) as first_segment, geometry::STGeomFromText('LINESTRING (5 0, 5 10)',0) as second_segment
union all
select -25 as offset, geometry::STGeomFromText('LINESTRING (0 25, 20 25)',0) as first_segment, geometry::STGeomFromText('LINESTRING (-5 0, -5 10)',0) as second_segment
)
select f.offset,
       [$(owner)].[STRound]([$(cogoowner)].[STFindLineIntersectionBySegment](first_segment,second_segment),3,3,1,1).STAsText() as geom,
                            [$(cogoowner)].[STFindLineIntersectionDetails]  (first_segment,second_segment) as reason
  from data as f
order by offset;
GO

