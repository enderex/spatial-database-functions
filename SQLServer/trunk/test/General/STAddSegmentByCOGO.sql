SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[STAddSegmentByCOGO] ...';
GO

With data as (
  select geometry::STGeomFromText('LINESTRING (0 0, 1 0, 1 1,2 2,3 3,4 4)',0) as linestring
)
select CAST('ORIGINAL' as varchar(8)) as text, 0 as bearing, /*a.linestring.STBuffer(0.2) as linestring,*/ CAST(a.linestring.AsTextZM() as varchar(80)) as lWKT from data as a
union all
select text, f.bearing, /*f.newLine.STBuffer(0.1), */ CAST(f.newLine.AsTextZM() as varchar(80)) as lWkt 
  from (select 'START' as text, g.IntValue as bearing, [$(cogoowner)].[STAddSegmentByCOGO] ( a.linestring, g.Intvalue, 1.0, 'START', 2, 1) as newLine from data as a cross apply [$(owner)].[generate_series] (45,315,45) as g
        union all
        select 'START' as text, NULL,                  [$(cogoowner)].[STAddSegmentByCOGO] ( a.linestring, NULL, 1.0, 'START', 2, 1) as newLine from data as a 
        union all
        select 'END'   as text, g.IntValue as bearing, [$(cogoowner)].[STAddSegmentByCOGO] ( a.linestring, g.Intvalue, 1.0, 'END', 2, 1) as newLine from data as a cross apply [$(owner)].[generate_series] (45,315,45) as g
        union all
        select 'END'   as text, NULL,                  [$(cogoowner)].[STAddSegmentByCOGO] ( a.linestring, NULL, 1.0, 'END', 2, 1) as newLine from data as a 
       ) as f;
GO

