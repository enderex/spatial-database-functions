SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STReverse] ....'
GO

select id, action, geom 
  from (select 'Before' as action, id, geom.STAsText() as geom
          from (select 1 as id, geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
                union all
                select 2 as id, geometry::STGeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
                union all
                select 3 as id, geometry::STGeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
                ) as data
       union all
       select 'After' as action, id, [$(owner)].[STReverse](geom,3,2).STAsText() as geom
         from (select 1 as id, geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
               union all
               select 2 as id, geometry::STGeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
               union all
               select 3 as id, geometry::STGeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
              ) as data
       ) as f
order by id, action desc;
GO


