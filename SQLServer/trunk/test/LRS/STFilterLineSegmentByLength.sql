SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STFilterLineSegmentByLength] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 1 as id, 'SM NULL (set to 1)/ EM NULL (return all segments)' as locateType,
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,null,null,3,2) as s
union all
select 2 as id, 'SM NULL (set to 1) / End Length Less than first segment (returns first segment)' as locateType,
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,null,1,3,2) as s
union all
select 3 as id, 'SM/EM Same/ Returns First Segment' as locateType, 
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,1,1,3,2) as s
union all
select 5 as id, 'SM Before SP/EM = 10 (last Segment)' as locateType, 
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,0,10,3,2) as s
union all
select 6 as id, 'SM & EM Within First Segment' as locateType,  
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,2,5.6,3,2) as s
union all
select 7 as id, 'Cross first and second segments' as locateType, 
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,2,6,3,2) as s
union all
select 8 as id, 'Start in First and Finish in last Segment' as locateType, 
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,4,20,3,2) as s
union all
select 9 as id, 'Start before First and Finish after last point' as locateType, 
       [$(lrsowner)].STMeasureRange(d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,0.1,30.0,3,2) as s;
go

-- MULTILINESTRING

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6),(10 0 0 15.61, 10 5 0 20.61,10 10 0 25.4),(11 11 0 26.8, 12 12 0 28.30))',28355) as linestring
)
select 1 as id, 'Start = First Point Second Segment' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,15.61,null,3,2) as s
union all
select 2 as id, 'SM = First Point Second Element / EM = Second Point Second Element' as locateType,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,15.61,25.4,3,2) as s
union all
select 3 as id, 'Cross first and second segments of first element',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,2,6,3,2) as s
union all
select 4 as id, 'Cross first and second segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,2,25,3,2) as s
union all
select 4 as id, 'Cross all segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,2,26,3,2) as s;
go

-- COMPOUNDCURVE

select geometry::STGeomFromText('COMPOUNDCURVE((-4 -4, 0 0, 10 0),CIRCULARSTRING(10 0, 10 5,20 10),(20 10, 21 11, 22 12))',0).STLength() as linestring;
go
-- Create linestring where M ordinates have length values....
-- Must first create NON-NULL Z values
select [$(lrsowner)].[STAddMeasure](
         [$(owner)].[STSetZ] (
            geometry::STGeomFromText('COMPOUNDCURVE((-4 -4, 0 0, 10 0),CIRCULARSTRING(10 0, 10 5,20 10),(20 10, 21 11, 22 12))',0),
            -999,3,2),
         null,null,3,2).AsTextZM() as linestring;
GO

-- End point each segment has cumulative lenght records in its Measure ordinate ...
--

with data as (
select geometry::STGeomFromText( 'COMPOUNDCURVE ( (-4 -4 NULL 0, 0 0 NULL 5.657, 10 0 NULL 15.657), CIRCULARSTRING (10 0 NULL 15.657, 10 5 NULL 20.657, 20 10 NULL 33.162), (20 10 NULL 33.162, 21 11 NULL 34.577, 22 12 NULL 35.991))',0) as linestring
-- Length at segment Start: 0
-- Length at segment Start: 5.657
-- Length at segment Start: 15.657
-- Length at segment Start: 33.162
-- Length at segment Start: 34.577
-- Total 35.991
)
select 'SP = FP First Segment; EP < EP First Segment' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,0,5.0,3,2) as s
union all
select 'SP = FP First Segment; EP = EP First Segment' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,0,5.65685424949238,3,2) as s
union all
select 'SP > FP First Segment; EP < EP First Segment' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,0.1,5.0,3,2) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM > FP Second Element' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,5.0,15.0,3,2) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM = EP Second Element' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,5.0,15.657,3,2) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM > SP Third Element' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,5.0,16.0,3,2) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM > SP Fourth Element' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,5.0,24.1,3,2) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM = EP Last CircularString Element' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,5.0,33.162,3,2) as s
union all
select 'All segments' as locateType, 
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByLength](linestring,null,null,3,2) as s;
go

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',28355) as linestring
)
select g.intValue as start_length,
       g.IntValue+1.5 as end_length,
       s.*
  from data as d
       cross apply
       [$(owner)].[generate_series](0, round(d.lineString.STLength(),1), 2 ) as g
       cross apply
       [$(lrsowner)].[STFilterLineSegmentByLength](d.linestring,g.IntValue,g.IntValue + 1.5,3,2) as s;
GO

with data as (
select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.1 16.3, 3 6.3 1.1 20.2))',0) as linestring
)
select       0          as start_length, d.linestring.STLength() as end_length, d.linestring from data as d
union all 
select TOP 1 g.intValue as start_length, g.IntValue+1.5          as end_length, s.geom.STBuffer(1) 
  from data as d
       cross apply
       [$(owner)].[generate_series](0, round(d.lineString.STLength(),1), 2 ) as g
       cross apply
       [$(lrsowner)].[STFilterLineSegmentByLength](d.linestring,g.IntValue,g.IntValue + 1.5,3,2) as s;
GO

