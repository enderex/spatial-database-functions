SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STExtend] ...';
GO

With data as (
select geometry::STGeomFromText('LINESTRING (1 1,2 2,3 3,4 4)',0) as linestring
)
select cast(d.linestring as varchar(40)) as original, 
       cast(case when f.newLinestring is not null then f.newLinestring.AsTextZM() else null end as varchar(40)) as newLinestring
from data as d, 
     ( select [$(owner)].[STExtend] (d.linestring,1.414,'START',0,3,2) as newLinestring from data as d union all
       select [$(owner)].[STExtend] (d.linestring,1.414,'END',  0,3,2)                  from data as d union all
       select [$(owner)].[STExtend] (d.linestring,1.414,'BOTH', 1,3,2)                  from data as d 
     ) as f;
GO

Print 'Testing [$(owner)].[STReduce] ...';
GO

With data as (
select geometry::STGeomFromText('LINESTRING (1 1,2 2,3 3,4 4)',0) as linestring
)
select f.direction,
       cast(d.linestring.AsTextZM() as varchar(40)) as original, 
       cast(case when f.newLinestring is not null then f.newLinestring.AsTextZM() else null end as varchar(40)) as newLinestring
from data as d, 
(
select case when g.IntValue = 1 then 'START'
            when g.IntValue = 2 then 'END'
            when g.IntValue = 3 then 'BOTH'
        end as direction,
       [$(owner)].[STReduce] (
          d.linestring,
          1.414,
          case when g.IntValue = 1 then 'START'
               when g.IntValue = 2 then 'END'
               when g.IntValue = 3 then 'BOTH'
           end,
          3,2) as newLinestring 
  from data as d 
       cross apply
       [$(owner)].[generate_series] ( 1, 3, 1 ) as g
) as f;
GO

