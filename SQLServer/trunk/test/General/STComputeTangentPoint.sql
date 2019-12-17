PRINT 'Testing STComputeTangentPoint...';
GO

With data as (
  select 1 as id,  geometry::STGeomFromText('CIRCULARSTRING(40 0, 35 5, 30 0)',0) as linestring
  union all
  select 2 as id, geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as linestring
  union all
  select 3 as id, geometry::STGeomFromText('CIRCULARSTRING(25 30, 30 12, 25 10)',0) as linestring
  union all
  select 4 as id, geometry::STGeomFromText('CIRCULARSTRING(25 30, 20 12, 25 10)',0) as linestring
  union all
  select 5 as id, geometry::STGeomFromText('CIRCULARSTRING(12 12, 12 15, 10 18)',0) as linestring
)
select id, 'S' as direction, [$(cogoowner)].[STComputeTangentPoint] (a.linestring,'START',3).STBuffer(1) as tPoint from data as a
union all
select id, 'E' as direction, [$(cogoowner)].[STComputeTangentPoint] (a.linestring,'END',3).STBuffer(1) as tPoint from data as a
union all
select id, 'L' as direction,a.linestring.STBuffer(1) from data as a;
GO

