SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STMakePoint] ...';
GO

SELECT [$(owner)].STMakePoint(10,10,null,null,0);
GO

SELECT f.point.AsTextZM() as point, 
       f.point.STSrid as srid
  FROM (SELECT [$(owner)].[STMakePoint](1,2,3,4,28355) as point) as f;
GO

