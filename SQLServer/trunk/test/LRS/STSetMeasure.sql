SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing STSetMeasure...';
GO

With Data As (
  SELECT geometry::Parse('POINT(100.123 100.456 NULL 4.567)') as point
)
SELECT CAST(CONCAT(g.point.AsTextZM(),
       ' ==> ',
       [$(lrsowner)].[STSetMeasure](g.point,99.123,3,1).AsTextZM()) as varchar(500)) as updatedPoint
  FROM data as g;
GO

SELECT [$(lrsowner)].[STSetMeasure](geometry::Point(0,0,28355),10.125,3,2).AsTextZM();
GO


