SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STFindArcPointByMeasure] ...';
GO

with data as (
select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindArcPointByMeasure](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.1) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M,
                               round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
                               1) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select a.linestring.STPointN(a.linestring.STNumPoints()).M as measure, 
       null as offset,
       linestring.STBuffer(0.5)
  from data as a;
GO

