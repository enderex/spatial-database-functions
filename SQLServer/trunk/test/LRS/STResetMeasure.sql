SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STResetMeasure]';
GO

select [$(lrsowner)].[STResetMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 1,2 2 3 2),(3 3 4 3,4 4 5 4))',0),default,3,2).AsTextZM() as geom;
GO

