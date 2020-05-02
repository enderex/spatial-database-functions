SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STReduce] ...';
GO

With data as (
select geometry::STGeomFromText('LINESTRING (1 1,2 2,3 3,4 4)',0) as linestring
)
select f.reduction_length,
       f.direction,
       cast(d.linestring.AsTextZM() as varchar(40)) as original, 
       cast(case when f.newLinestring is not null then f.newLinestring.AsTextZM() else null end as varchar(40)) as newLinestring,
       ROUND(d.linestring.STLength() - f.newLinestring.STLength(),3) as length_Change
from data as d, 
     (select case when h.IntValue = 1 then 1.1 else 1.414 end as reduction_length,
             case when g.IntValue = 1 then 'START'
                  when g.IntValue = 2 then 'END'
                  when g.IntValue = 3 then 'BOTH'
              end as direction,
            [$(owner)].[STReduce] (
                d.linestring,
                case when h.IntValue = 1 then 1.1 else 1.414 end,
                case when g.IntValue = 1 then 'START'
                     when g.IntValue = 2 then 'END'
                     when g.IntValue = 3 then 'BOTH'
                 end,
                3,2) as newLinestring 
        from data as d 
             cross apply
             [$(owner)].[generate_series] ( 1, 3, 1 ) as g
             cross apply
             [$(owner)].[generate_series] ( 1, 2, 1 ) as h
      ) as f
order by 1;
GO

