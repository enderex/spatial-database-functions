SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STSetZ] ...';
Print '... Simple Point case ...';
GO

With data as (
  select geometry::Parse('POINT(100.123 100.456 NULL 4.567)') as pointzm
)
SELECT CAST(d.pointzm.STGeometryType() as varchar(20)) as GeomType, 
       d.pointzm.HasZ as z, 
       d.pointzm.HasM as m, 
       CAST([$(owner)].[STSetZ](d.pointzm,99.123,3,1).AsTextZM() as varchar(50)) as rGeom
  FROM data as d; 
GO

Print '... LineStrings ...';
GO

With Data as (
select 'Simple LineString' as lType, geometry::STGeomFromText('LINESTRING (-2 -2, 25 -2)',0) as geom
union all
select 'Simple MultiLineString' as lType, geometry::STGeomFromText('MULTILINESTRING((-2 -2,25 -2),(10 10,11 11))',0) as geom
union all
Select '2D CompoundCurve -> Must have non-NULL Z of same value' as lType,  
       geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as geom
)
select d.lType, 'Before' as status, d.geom.AsTextZM() as geometry from data as d
union all
select d.ltype, 'After'  as status, [$(owner)].[STSetZ] (d.geom,-999,3,1).AsTextZM() as geometry from data as d
order by 1,2 desc;
GO


