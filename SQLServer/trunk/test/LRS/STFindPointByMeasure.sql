SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STFindPointByMeasure] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'Original Linestring as backdrop for SSMS mapping' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,null,0,3,2).STBuffer(1) as measureSegment from data as a
union all
select 'Null measure (-> NULL)' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,null,0,3,2).STBuffer(1) as measureSegment from data as a
union all
select 'Measure = Before First SM -> NULL)' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,0.1,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 1st Segment SP -> SM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,1,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 1st Segment EP -> EM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,5.6,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = MidPoint 1st Segment -> NewM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,2.3,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 2nd Segment MP -> NewM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,10.0,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,20.0,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment End Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,25.4,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = After Last Segment''s End Point Measure' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,50.0,0,3,2).STBuffer(2) as measureSegment from data as a;
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  4, 0  0 0 2)',28355) as rlinestring
)
select 'Measure is middle First With Reversed Measures' as locateType, [$(lrsowner)].[STFindPointByMeasure](rlinestring,3.0,0,3,2).AsTextZM() as measureSegment from data as a;
GO

-- Now with offset
with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'LineString' as locateType, linestring from data as a
union all
select 'Measure = First Segment Start Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,1,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = First Segment End Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,5.6,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure is middle First Segment' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,2.3,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Second Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,10.0,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,20.0,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment End Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,25.4,-1.0,3,2).STBuffer(2) as measureSegment from data as a;
GO

-- Measures plus left/right offsets

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByMeasure](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByMeasure](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as measure, 
       null as offset,
       linestring.STBuffer(0.2)
  from data as a;
GO

-- Circular Arc / Measured Tests
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
  union all 
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
)
select CAST(a.linestring.STGeometryType() as varchar(30)) as curve_type,
       g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByMeasure](a.linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.2) as fPoint
  from data as a
       cross apply
       [dbo].[generate_series](a.lineString.STPointN(1).M,
                               round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
                               [$(lrsowner)].[STMeasureRange](a.linestring) / 4.0 ) as g
       cross apply
       [$(owner)].[generate_series](-1, 1, 1) as o
order by curve_type, measure;
GO


