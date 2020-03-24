SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STFindSegmentByLengthRange] ...';
GO

with mLine as (
  SELECT geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0) as mLinestring
)
select 'ORGNL' as tSource, e.mLineString from mLine as e
union all
SELECT 'SGMNT', [$(lrsowner)].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0, 0.0, 3, 2).STBuffer(0.3) as Lengths2SegmentNoOffset FROM mLine as e
union all
SELECT 'RIGHT', [$(lrsowner)].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0, 1.0, 3, 2).STBuffer(0.3) as Lengths2SegmentNoOffset FROM mLine as e
union all
SELECT 'LEFT',  [$(lrsowner)].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0,-1.0, 3, 2).STBuffer(0.3) as Lengths2SegmentNoOffset FROM mLine as e
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
Select locateType, segmentByLength.AsTextZM() as segmentByLength from (
select 'SM 1-> EM NULL->25.4 => While Linestring' as locateType,   [$(lrsowner)].[STFindSegmentByLengthRange](linestring,1,null,0,3,2) as segmentByLength from data as a
union all
select 'SM NULL->1, EM 1 => Start Point' as locateType,            [$(lrsowner)].[STFindSegmentByLengthRange](linestring,null,1,0,3,2) as segmentByLength from data as a
union all
select 'SM == EM 1 => Start Point' as locateType,                  [$(lrsowner)].[STFindSegmentByLengthRange](linestring,1,1,0,3,2) as segmentByLength from data as a
union all
select 'SM NULL, EM 5.6 => Return 1s Segment' as locateType,       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,null,5.6,0.0,3,2) as segmentByLength from data as a
union all
select 'SM / EM 5.6 => 1st Segment End Point' as locateType,       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,5.6,5.6,0,3,2) as segmentByLength from data as a
union all
select 'SM / EM Within First Segment => New Segment',              [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2.0,5.0,0,3,2) as segmentByLength from data as a
union all
select 'SM 2.0, EM 6.0 => two new segments',                       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2,6,0,3,2) as segmentByLength from data as a
union all
select 'SM 1.1, EM 25.4 => new 1st segment, current 2nd, new 3rd', [$(lrsowner)].[STFindSegmentByLengthRange](linestring,1.1,25.1,0,3,2) as segmentByLength from data as a
union all
select 'SM Before SPM, EM after EPM=> whole linestring',           [$(lrsowner)].[STFindSegmentByLengthRange](linestring,0.1,30.0,0,3,2) as segmentByLength from data as a 
) as f;
GO

-- MultiLineString....

--select [$(lrsowner)].STAddMeasure(geometry::STGeomFromText('MULTILINESTRING((-4 -4, 0  0), (10  0, 10 10),(11 11, 12 12 ))',0),
--       0.0,null,3,3).AsTextZM() as segmentByLength;
-- go

with data as (
select geometry::STGeomFromText('MULTILINESTRING ((-4 -4 NULL 0, 0 0 NULL 5.657), (10 0 NULL 5.657, 10 10 NULL 15.657), (11 11 NULL 15.657, 12 12 NULL 17.071))',0) as linestring
)
Select locateType, f.segmentByLength.AsTextZM() as segmentByLength from (
select 'Original Linestring'                  as locateType,       linestring as segmentByLength from data as a
union all
select 'SL before SP and EL after EP of Line' as locateType,       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,0,30.0,0,3,2) as segmentByLength from data as a
union all
select 'SL = SP 2nd Segment / End Rest of Line' as locateType,     [$(lrsowner)].[STFindSegmentByLengthRange](linestring,15.61,null,0,3,2) as segmentByLength from data as a
union all
select 'SL = SP / EL 2nd Point in Second Segment' as locateType,   [$(lrsowner)].[STFindSegmentByLengthRange](linestring,15.61,25.4,0,3,2) as segmentByLength from data as a
union all
select 'EL Falls between 1st and 2nd segments',                    [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2,6,0,3,2) as segmentByLength from data as a
union all
select 'Range Crosses 1st and 3rd segments',                       [$(lrsowner)].[STFindSegmentByLengthRange](linestring,2,26,0,3,2) as segmentByLength from data as a
union all
select 'SL = EP First Segment with EL next segment',               [$(lrsowner)].[STFindSegmentByLengthRange](linestring,5.6,16.61,0.0,3,2) as fsegment from data as a
union all
select 'SL/EL falls in gap between two segments',                  [$(lrsowner)].[STFindSegmentByLengthRange](linestring,5.6,15.61,0.0,3,2) as fsegment from data as a
) as f;
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
select 0.0            as start_length,
       g.intValue+1.0 as end_length,
       [$(lrsowner)].[STFindSegmentByLengthRange](a.linestring,0.0,g.IntValue+1,0.0,3,2).AsTextZM() as fsegment
  from data as a
       cross apply
       generate_series(0,
                       round(a.lineString.STLength(),0),
                       round(a.lineString.STLength()/4.0,0)
                      ) as g;
GO

-- Mix including CompoundCurve

with data as (
  --select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
  --union all
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
  --union all
  --select geometry::STGeomFromText('MULTILINESTRING ((-4 -4 NULL 0, 0 0 NULL 5.657), (10 0 NULL 5.657, 10 10 NULL 15.657), (11 11 NULL 15.657, 12 12 NULL 17.071))',0) as linestring
)
--select [$(lrsowner)].[STFindSegmentByLengthRange] (a.linestring,5.0,7.0,0.0,3,2).STBuffer(0.2) as fsegment from data as a;
--select b.* from data as a cross apply dbo.STSegmentize( a.linestring,'LENGTH_RANGE',null,null, 5.0,7.0, 3,2,2) as b; 
select 'Original'              as geom_type,
       0.0                     as start_length, 
       a.lineString.STLength() as end_length, 
       linestring
  from data as a
union all
select a.linestring.STGeometryType()       as geom_type,
       CAST(g.IntValue+1 as numeric) / 2.0 as start_length,
       g.intValue+1.0                      as end_length,
       [$(lrsowner)].[STFindSegmentByLengthRange] (
           a.linestring,
           CAST(g.IntValue   as numeric) / 2.0,
           CAST(g.IntValue+1 as numeric),
           0.0,
           3,2
       ).STBuffer(0.2) as fsegment
  from data as a
       cross apply
       [$(owner)].[generate_series](0,
                               round(a.lineString.STLength(),0),
                               round(a.lineString.STLength(),0)/8.0 ) as g
 order by geom_type, start_length;
GO


/*
with data as (
select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3))',0) as cString
)
select 0.0  as start_length,
       21.0 as end_length,
       [$(lrsowner)].[STFindSegmentByLengthRange] (
           a.cString,
           0.0,
           21.0,
           0.0,
           3,2) as fsegment
  from data as a
GO
*/

