SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STRemoveMeasure]';
GO

select [$(lrsowner)].[STRemoveMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 NULL 1,2 2 NULL 2),(3 3 NULL 3,4 4 NULL 4))',0),3,2).AsTextZM() as geom;
GO

select [$(lrsowner)].[STRemoveMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 1,2 2 3 2),(3 3 4 3,4 4 5 4))',0),3,2).AsTextZM() as geom;
GO


