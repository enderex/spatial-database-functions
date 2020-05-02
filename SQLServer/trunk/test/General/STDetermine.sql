SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STDetermine] ...';
GO

Select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0),
         geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0)
       ) as relations;
go

Select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('LINESTRING (100.0 0.0, 400.0 0.0)',0),
         geometry::STGeomFromText('LINESTRING (90.0 0.0, 100.0 0.0)',0)
       ) as relations;
GO

select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) ,
         geometry::STPointFromText('POINT (250 150)',0)
     ) as relations;
GO

select [$(owner)].[STDetermine] ( 
       geometry::STPointFromText('POINT (250 150)',0),
       geometry::STPointFromText('POINT (250 150)',0)
     ) as relations;
GO

with data as (
select 1 as id, geometry::STGeomFromText('POLYGON((1 1,9 1,9 9,1 9,1 1))',0) as geom
union all
select 2 as id, geometry::STGeomFromText('POLYGON((3 3,8 3,8 8,3 8,3 3))',0)
union all
select 3 as id, geometry::STGeomFromText('POLYGON((1 1,3 1,3 3,1 3,1 1))',0)
union all
select 4 as id, geometry::STGeomFromText('POLYGON((2 2,4 2,4 4,2 4,2 2))',0)
union all
select 5 as id, geometry::STGeomFromText('POLYGON((9 9,10 9,10 10,9 10,9 9))',0)
union all
select 6 as id, geometry::STGeomFromText('POLYGON((2 6,3 6,3 8,2 8,2 6))',0)
union all
select 7 as id, geometry::STGeomFromText('POLYGON((5 6,6 6,6 7,5 7,5 6))',0)
union all
select 8 as id, geometry::STGeomFromText('POLYGON((3.5 1.5,4.5 1.5,4.5 3.5,3.5 3.5,3.5 1.5))',0)
)
, geometrycollection as (
select geometry::CollectionAggregate(a.geom) as geomC
  from data as a
)
select dbo.STDetermine(a.geomC,b.geom) as determine
  from geometryCollection as a,
       data as b
GO


