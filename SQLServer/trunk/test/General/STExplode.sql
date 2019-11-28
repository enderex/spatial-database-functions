SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STExplode] ...';
GO

With data as (
  SELECT GEOMETRY::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))) ',0) as geom
)
select CAST('Original' as varchar(10)) as result, 0, 0, geom.AsTextZM() as geom from data as d
UNION ALL
select 'Explode' as result, t.gid, t.sid, t.geom.AsTextZM() as geom
  From data as d
       cross apply
       [$(owner)].[STExplode](d.geom) as t;
GO


