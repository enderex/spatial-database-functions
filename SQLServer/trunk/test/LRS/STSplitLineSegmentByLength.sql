SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STSplitLineSegmentByLength] ...';
GO

with data as (
  select geometry::STGeomFromText('LINESTRING(0 0 NULL 1, 10 10 NULL 15.142135623731)',0) as lString
)
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3) as start_distance, 
       round(d.lString.STLength(),3) as end_distance, 
       CAST([$(lrsowner)].[STSplitLineSegmentByLength] ( 
          d.lString, 
          0.0, round(d.lString.STLength(),3), 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3)       as start_distance, 
       round(d.lString.STLength() / 3.0,3) as   end_distance,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByLength] ( 
         d.lString, 
         0.0, 
         round(d.lString.STLength() / 3.0,3), 0.0,3,2 ).AsTextZM()  as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0,3)       as start_distance, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as   end_distance,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByLength] ( 
         d.lString, 
         d.lString.STLength() / 3.0, 
         d.lString.STLength() / 3.0 * 2.0, 0.0,3,2 ).AsTextZM()  as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.lString.AsTextZM() as varchar(50)) as wkt, 
       round(d.lString.STLength() / 3.0 * 2.0,3) as start_distance, 
       round(d.lString.STLength()+1.0,3)         as end_distance,  
       CAST(
       [$(lrsowner)].[STSplitLineSegmentByLength] ( 
         d.lString, 
         d.lString.STLength() / 3.0 * 2.0, 
         round(d.lString.STLength()+1.0,3), 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d;
GO

