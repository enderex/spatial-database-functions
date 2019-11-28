SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

SELECT [$(owner)].[STCheckRadii](geometry::STGeomFromText('LINESTRING(0.0 0.0,10.0 0.0,10.0 10.0)',0),10.0,3).STAsText() as failingPoints;
GO

SELECT [$(owner)].[STCheckRadii](geometry::STGeomFromText('MULTILINESTRING((0.0 0.0,10.0 0.0,10.0 10.0),(20.0 0.0,30.0 0.0,30.0 10.0,35 15))',0), 15.0,3).STAsText()  as failingPoints; 
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING(0.0 0.0,10.0 10.0,20.0 0.0)',0) as circulararc
)
select gs.IntValue as requiredMinRadius,
       [$(cogoowner)].[STFindCircleFromArc](circularArc).Z as ArcRadius,
       [$(owner)].[STCheckRadii](
                circulararc,
                gs.IntValue,
                3).STAsText() as failingArc
  from data as a
       cross apply
       [$(owner)].[generate_series](5,15,5) as gs;
GO

