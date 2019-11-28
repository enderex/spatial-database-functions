SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STLineMerge] ...';
GO

With tGeometry As (
  select cast('1' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (10 0,30 0,20 10)',0) as geom
   union all
  select cast('2' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (20 10,10 10)',0) as geom
   union all
  select cast('3' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (10 10,10 0)',0) as geom
   union all
  select cast('4' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (0 0,10 0)',0) as geom
   union all
  select cast('5' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (20 20, 20 10)',0) as geom
)
select 'O' + f.id as text, f.geom.STBuffer(0.2) as geom, ROUND(f.geom.STLength(),3) as gLen from tGeometry as f
union all
select 'MinX' as text,     f.geom.STBuffer(2)   as geom, ROUND(f.geom.STLength(),3) as gLen from (select [$(owner)].[STLineMerge](geometry::CollectionAggregate(a.geom),'X') as geom from tGeometry as a) as f
union all
select 'Long' as text,     f.geom.STBuffer(1)   as geom, ROUND(f.geom.STLength(),3) as gLen from (select [$(owner)].[STLineMerge](geometry::CollectionAggregate(a.geom),'L') as geom from tGeometry as a) as f;
GO

