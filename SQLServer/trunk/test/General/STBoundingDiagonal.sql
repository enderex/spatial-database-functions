SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STBoundingDiagonal] ...';
GO

with data as (
  select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
)
select [$(owner)].[STBoundingDiagonal] (b.geom,3,2).STAsText() as bLine
  from data as b;
GO


