SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STSplitCircularStringByLength] ...';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3246, 0 7, 3 6.3246)',0) as linestring
  union all
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
)
select a.linestring as linestring
  from data as a
union all
select [$(lrsowner)].[STSplitCircularStringByLength](a.linestring,0.5,2.0,0.0,3,2).STBuffer(0.4) as split
  from data as a;
GO



with data as (
  select geometry::STGeomFromText('CIRCULARSTRING(0 0, 10.1234 10.1234, 20 0)',0) as cString
)
SELECT CAST(d.cString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3) as start_length  , 
       round(d.cString.STLength(),3) as end_length  , 
       CAST([$(lrsowner)].[STSplitCircularStringByLength] ( d.cString, 0, 32.0, 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.cString.AsTextZM() as varchar(50)) as wkt, 
       round(d.cString.STLength() / 3.0,3)       as start_length  , 
       round(d.cString.STLength() / 3.0 * 2.0,3) as   end_length  ,  
       CAST(
       [$(lrsowner)].[STSplitCircularStringByLength] ( 
         d.cString, 
         d.cString.STLength() / 3.0, 
         d.cString.STLength() / 3.0 * 2.0, 0.0,3,2 ).AsTextZM()  as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.cString.AsTextZM() as varchar(50)) as wkt, 
       round(d.cString.STLength() / 3.0 * 2.0,3)          as start_length  , 
       round((d.cString.STLength() / 3.0 * 2.0 ) + 1.0,3) as   end_length  ,  
       CAST(
       [$(lrsowner)].[STSplitCircularStringByLength] ( 
         d.cString, 
         d.cString.STLength() / 3.0 * 2.0, 
         (d.cString.STLength() / 3.0 * 2.0) + 1.0, 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d;
GO

