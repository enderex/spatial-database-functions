SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STRotate] ...';
GO

-- Rotate rectangle about itself and the origin
--
With data as (
select 'Original' as name, geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0) as geom
)
select name, geom from data as d
union all
select '45' + CHAR(176) + ' rotate about 0,0' as name, 
       [$(owner)].[STRotate](d.geom,0.0,0.0,45,3,3) as geomO
  from data as d
union all
SELECT '45' + CHAR(176) + ' rotate about MBR centre' as name, 
       [$(owner)].[STRotate](d.geom,(a.minx + a.maxx) / 2.0,(a.miny + a.maxy) / 2.0,45,3,3) as geom
  FROM data as d
       cross apply
       [$(owner)].[STGEOMETRY2MBR](d.geom) as a;
GO

-- Point
--
select geometry::STGeomFromText('POINT(0 0 0)',0).STBuffer(0.5)  as geom
union all
select [$(owner)].[STRotate](geometry::STGeomFromText('POINT(0 0 0)',0),10,10,45,3,3).STBuffer(0.5) as geom;
GO

select a.intValue as oid,
       CAST(a.intValue as varchar) + CHAR(176) as label,
       [$(owner)].[STRotate](geometry::STGeomFromText('POINT(0 10 0)',0),0.0,0.0,a.IntValue,3,3).STBuffer(1) as geom
  from [$(owner)].[generate_series](0,350,10) a;
GO

-- Linestring
--
With data as (
select geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
)
select a.intValue as oid,
       CAST(a.intValue as varchar) + CHAR(176) as label,
       [$(owner)].[STRotate](d.geom,0.0,0.0,a.IntValue,3,3).STBuffer(0.05) as geom
  from data as d
       cross apply 
       [$(owner)].[generate_series](0,350,10) a;
GO

select [$(owner)].[STRotate](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872)))',0),0.0,0.0,45.0,3,3) as geom;
GO

-- Curved polygon
--
With data as (
select geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872)))',0) as geom
)
select a.intValue as deg,
       CAST(a.intValue as varchar) + CHAR(176) as label,
       [$(owner)].[STRotate](d.geom,0.0,0.0,a.IntValue,3,3) as geom
  from data as d
       cross apply 
       [$(owner)].[generate_series](0,350,10) a;
GO

