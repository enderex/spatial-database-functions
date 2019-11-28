SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STSplitLineSegmentByMeasure] ...';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
)
select a.linestring as linestring
  from data as a
union all
select [$(lrsowner)].[STSplitCircularStringByMeasure](a.linestring,0.5,2.0,0.0,3,2).STBuffer(0.4) as split
  from data as a;
GO

-- **************

with data as (
  select geometry::STGeomFromText('LINESTRING(0 0 NULL 1, 10 10 NULL 15.142135623731)',0) as lString
)
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3) as start_measure, 
       round(d.lString.STLength(),3) as end_measure, 
       CAST([$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
          d.lString, 
          0.0, 
          round(d.lString.STLength(),3),
          0.0,3,2 ).AsTextZM() as varchar(80)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3)       as start_measure, 
       round(d.lString.STLength() / 3.0,3) as   end_measure,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
         d.lString, 
         0.0, 
         round(d.lString.STLength() / 3.0,3),
         0.0,3,2 ).AsTextZM()  as varchar(80)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0,3)       as start_measure, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as   end_measure,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
         d.lString, 
         round(d.lString.STLength() / 3.0, 3),
         round(d.lString.STLength() / 3.0 * 2.0,3),
         0.0,3,2 ).AsTextZM()  as varchar(80)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as start_measure, 
       round(d.lString.STLength()+1.0,3)         as end_measure,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByMeasure] ( 
         d.lString, 
         d.lString.STLength() / 3.0 * 2.0, 
         round(d.lString.STLength()+1.0,3), 
         0.0,3,2 ).AsTextZM() as varchar(80)) as subString FROM data as d;
GO

