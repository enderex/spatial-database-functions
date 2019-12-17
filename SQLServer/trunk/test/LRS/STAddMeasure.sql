SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STAddMeasure] ...';
GO

With Data as (
select 'Simple LineString' as lType, 'Before' as status, 
       geometry::STGeomFromText('LINESTRING(0 0,5 5,10 10)',0) as geom
union all 
select 'MultiLineString' as lType,   'Before' as status, 
       geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10),(11 11, 12 12))',0) as geom
union all
Select '2D CompoundCurve -> Must have non-NULL Z added before add Measure' as lType,  'Before' as status, 
       [$(owner)].[STSetZ](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),0,4,1) as geom
union all 
Select '3D CompoundCurve' as lType,  'Before' as status, 
       geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 1.1, 0 7 1.1, -3 6.3246 1.1),(-3 6.3246 1.1, 0 0 1.4, 3 6.3246 1.55))',0) as geom
)
select *
  from (select d.lType, d.status, d.geom.AsTextZM() as geometry from data as d
        union all
        select d.ltype, 'After' as status, 
		      [$(lrsowner)].[STAddMeasure](d.geom,0,null,1,1).AsTextZM() as nowMeasured from data as d
       ) as f
order by 1,2;
go
