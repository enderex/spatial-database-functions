SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STFindArcPointByLength] ...';
GO

with data as (
select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
)
select g.intValue as length,
       o.IntValue as offset,
       [$(lrsowner)].[STFindArcPointByLength](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.1) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](0, a.lineString.STLength(), 1) as g
       cross apply
       [$(owner)].[generate_series](-1, 1, 1) as o
union all
select a.linestring.STPointN(a.linestring.STNumPoints()).M as measure, 
       null as offset,
       linestring.STBuffer(0.05)
  from data as a;
GO

With data as (
--select 'CircularArc (clockwise)'        as test, geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as linestring
--select 'CircularArc (clockwise) Angled' as test, geometry::STGeomFromText('CIRCULARSTRING(25 30, 30 12, 25 10)',0) as linestring
--select 'CircularArc (anticlockwise)' as test, geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as linestring
select 'CircularArc 3/4 (clockwise)' as test ,            geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0) as linestring
)
--select [$(cogoowner)].[STFindArcPointByLength](d.linestring,2.3,0,3,2).STBuffer(0.5) as point from data as d
--union all
--select d.linestring.STBuffer(0.2) from data as d;
select 1.0 * g.Intvalue as aLength, 
       [$(lrsowner)].[STFindArcPointByLength](d.linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.5) as point
  from data as d
       cross apply
       [$(owner)].[Generate_Series](0,ROUND(d.linestring.STLength(),0)+1,1) as g
       cross apply
       [$(owner)].[Generate_Series](-1,1,1) as o
union all
select d.linestring.STLength() as aLength, d.linestring.STBuffer(0.2) from data as d;
GO


