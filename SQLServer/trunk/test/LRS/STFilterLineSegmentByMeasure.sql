SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STFilterLineSegmentByMeasure] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 1 as id, 'SM NULL (set to 1)/ EM NULL (return all segments)' as locateType,[$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,null,null,3,2) as s
union all
select 2 as id, 'SM NULL (set to 1) / EM = 1 (returns first segment)' as locateType,[$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,null,1,3,2) as s
union all
select 3 as id, 'SM/EM Same Mid First Segment (Returns First Segment)' as locateType, [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,2,3,2) as s
union all
select 5 as id, 'SM 5 (First Segment)/EM 10 (last Segment)' as locateType, [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,5,10,3,2) as s
union all
select 6 as id, 'SM 6 / EM 10 (Last Segment)' as locateType,  [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,6,10,3,2) as s
union all
select 9 as id, 'SM before First and EM after last point' as locateType, [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,0.1,30.0,3,2) as s;
GO

-- MULTILINESTRING 

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',28355) as linestring
)
select 1 as id, 'Start = First Point Second Segment' as locateType,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,15.61,null,3,2) as s
union all
select 2 as id, 'Start = First Point / End Second Point Second Segment' as locateType,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,15.61,25.4,3,2) as s
union all
select 3 as id, 'Cross first and second segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,6,3,2) as s
union all
select 4 as id, 'Cross first and second segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,25,3,2) as s
union all
select 4 as id, 'Cross all segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,26,3,2) as s;
GO

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',28355) as linestring
)
select g.intValue        as start_measure,
       g.IntValue + 2.25 as end_measure,
       s.* 
  from data as d 
       cross apply
       [$(owner)].[generate_series](d.lineString.STStartPoint().M, 
                                    round(d.lineString.STEndPoint().M,0,1), 
                                    2) as g
       cross apply 
       [$(lrsowner)].[STFilterLineSegmentByMeasure](d.linestring,g.IntValue,g.IntValue + 2.25,3,2) as s;
GO

with data as (
select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as linestring
)
select CAST(d.LineString.STGeometryType() as varchar(30)) as gType, 
       d.lineString.STStartPoint().M as start_measure, 
       d.linestring.STEndPoint().M as end_measure, 
       d.linestring 
  from data as d
union all 
select TOP 1 
       s.multi_tag    as gType, 
       g.intValue     as start_measure, 
       g.IntValue+2.5 as end_measure, 
       s.geom.STBuffer(1) as fSegment
  from data as d
       cross apply
       [$(owner)].[generate_series](      d.lineString.STStartPoint().M, 
                                    round(d.lineString.STEndPoint().M,0,1), 
                                    2) as g
       cross apply 
       [$(lrsowner)].[STFilterLineSegmentByMeasure](d.linestring,g.IntValue,g.IntValue + 2.25,3,2) as s;
GO


