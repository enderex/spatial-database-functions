SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing ...';
GO

select [$(cogoowner)].[STBearing](0,0,45,45) as Bearing;
GO

select [$(cogoowner)].[STPointFromBearingAndDistance](0,0,45,100,3,0).STAsText();
GO

select g.IntValue as bearing, 
       [$(cogoowner)].[STPointFromBearingAndDistance](0,0,g.IntValue,100,3,0).AsTextZM() as point
  from [$(owner)].[GENERATE_SERIES] (0,350,10) as g;
GO

SELECT [$(cogoowner)].[STPointFromCOGO] (geometry::Point(0,0,0),45,100,3).STAsText() as endPoint;
GO

