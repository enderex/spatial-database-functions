SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
 
Print 'Testing [$(lrsowner)].[STSplitCircularStringByMeasure] ...';
GO

with data as (
  select [$(lrsowner)].[STAddMeasure](
           [$(owner)].[STSetZ](geometry::STGeomFromText('CIRCULARSTRING(0 0, 10.1234 10.1234, 20 0)',0),
                               -999,3,2),
           1.0,33.1,3,2) as cString
)
SELECT CAST(d.cString.AsTextZM() as varchar(50)) as wkt, 
       round(0.0,3) as start_measure, 
       round(d.cString.STLength(),3) as end_measure, 
       CAST([$(lrsowner)].[STSplitCircularStringByMeasure] ( d.cString, 0, 32.0, 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.cString.AsTextZM() as varchar(50)) as wkt, 
       round(d.cString.STLength() / 3.0,3)       as start_measure, 
       round(d.cString.STLength() / 3.0 * 2.0,3) as   end_measure,  
       CAST(
       [$(lrsowner)].[STSplitCircularStringByMeasure] ( 
         d.cString, 
         d.cString.STLength() / 3.0, 
         d.cString.STLength() / 3.0 * 2.0, 0.0,3,2 ).AsTextZM()  as varchar(50)) as subString FROM data as d
UNION ALL
SELECT CAST(d.cString.AsTextZM() as varchar(50)) as wkt, 
       round(d.cString.STLength() / 3.0 * 2.0,3)          as start_measure, 
       round((d.cString.STLength() / 3.0 * 2.0 ) + 1.0,3) as   end_measure,  
       CAST(
       [$(lrsowner)].[STSplitCircularStringByMeasure] ( 
         d.cString, 
         d.cString.STLength() / 3.0 * 2.0, 
         (d.cString.STLength() / 3.0 * 2.0) + 1.0, 0.0,3,2 ).AsTextZM() as varchar(50)) as subString FROM data as d;
GO

