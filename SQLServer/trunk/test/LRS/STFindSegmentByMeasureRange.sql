SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing....';
GO

PRINT 'STFindSegmentByMeasureRange -> LineString ...';
PRINT 'LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
Select locateType, 
       sm,em,
       case when f.measureSegment is not null 
            then f.measureSegment.AsTextZM() 
            else null 
        end as measureSegment 
  from (
select 'SM 1.0/EM 1.0 => Start Point' as locateType,1.0 as sm,1.0 as em,  [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,1.0,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM 1.0/EM NULL => Whole Linestring',1.0,null,                     [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,1.0,null,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 1 => Start Point',null,1.0,                            [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,null,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 5.6 => Return 1s Segment',null,5.6,                    [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,null,5.6,0.0,3,2) as measureSegment from data as a
union all
select 'SM 5.6/EM 5.6 => 1st Segment EP or 2nd SP',5.6,5.6,               [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.6,5.6,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 5.0 Within First Segment => New Segment',2.0,5.0,       [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2.0,5.0,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 6.0 => Two New Segments',2.0,6.0,                       [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2,6,0,3,2) as measureSegment from data as a
union all
select 'SM 1.1/EM 25.4 => New 1st Segment, 2nd, New 3rd Segment',1.1,25.1,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,1.1,25.1,0,3,2) as measureSegment from data as a
union all
select 'SM 0.1/EM 30.0 => whole linestring',0.1,30.0,                     [$(lrsowner)].[STFindSegmentByMeasureRange](linestring,0.1,30.0,0,3,2) as measureSegment from data as a
) as f;
GO

PRINT 'STFindSegmentByMeasureRange -> MultiLineString ...';
PRINT 'MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6),(10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))';
GO

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',0) as linestring
)
Select locateType, 
       sm,em,
       case when f.measureSegment is not null 
            then f.measureSegment.AsTextZM() 
            else null 
        end as measureSegment 
  from (
select 'SM before SPM/EM < EPM 1st Segment' as locateType,0 as sm,5.0 as em,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,0.0,5.0,0,3,2) as measureSegment from data as a
union all
select 'SM SPM 2nd Segment / EM NULL => ',                       15.61,null,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,15.61,null,0,3,2) as measureSegment from data as a
union all
select 'SM = SPM/EM EPM Second Segment',                         15.61,25.4,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,15.61,25.4,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM Between 1st and 2nd segments',                    2.0,6.0,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2.0,6.0,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 26.0 (Cross 1st/3rd segments)',                  2.0,26.0,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,2.0,26.0,0,3,2) as measureSegment from data as a
union all 
select 'SM 5.6 = EPM 1st Segment/EM 16.61 (2nd Line, 2nd Seg)',   5.6,16.61,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.6,16.61,0.0,3,2) as fsegment from data as a
union all
select 'SM 5.6 = EPM 1st Seg/EM 15.61 (1st Pnt, 2nd Seg) => point only',5.6,15.61,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.6,15.61,0.0,3,2) as fsegment from data as a
union all
select 'SM/EM falls in gap between two segments (return NULL)',         5.6,15.60,[$(lrsowner)].[STFindSegmentByMeasureRange](linestring,5.61,15.60,0.0,3,2) as fsegment from data as a
) as f;
GO

