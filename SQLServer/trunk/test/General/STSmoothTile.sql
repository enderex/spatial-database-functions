SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: owner($(owner))';
GO

Print 'Tresting [$(owner)].[STSmoothTile]....';
GO

select [$(owner)].[STSmoothTile](geometry::STGeomFromText('POLYGON ((12.5 2.5, 17.5 2.5, 17.5 7.5, 12.5 7.5, 12.5 2.5))',0),3).AsTextZM() as geom;
GO

select [$(owner)].[STSmoothTile](geometry::STGeomFromText('POLYGON ((0 0, 9 0, 9 9, 0 9, 0 0), (2.5 2.5, 2.5 7.5, 7.5 7.5, 7.5 2.5, 2.5 2.5))',0),3).AsTextZM() as geom;
GO


select [$(owner)].[STSmoothTile](geometry::STGeomFromText(
'MULTIPOLYGON (((12.5 2.5, 17.5 2.5, 17.5 7.5, 12.5 7.5, 12.5 2.5)), ((10 0, 19 0, 19 9, 10 9, 10 0), (11 1, 11 8, 18 8, 18 1, 11 1)), ((0 0, 9 0, 9 9, 0 9, 0 0), (2.5 2.5, 2.5 7.5, 7.5 7.5, 7.5 2.5, 2.5 2.5)))',0),3);
GO


/*
with data as (
select geometry::STGeomFromText('LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2)',0) as geom 
--select geometry::STGeomFromText('POLYGON((0 0,1 0,2 0,3 0,4 0,5 0,6 0,7 0,8 0,9 0,10 0,10 1,9 1,8 1,7 1,6 1,5 1,4 1,3 1,2 1,1 1,0 1,0 0))',0) as geom
)
select [$(owner)].[STSmoothTile](a.geom,3) from data as a
select (ST_DumpPoints(dbo.STSmoothTile(a.geom,3))).geom from data as a
union all
select spdba.ST_SmoothTile(a.geom,3) from data as a
union all
select a.geom from data as a;


with data as (
select 1 as id, 'POLYGON((0 0,10 0,10 10,0 10,0 0))'::geometry as p_geom     union all
select 2, 'POLYGON((0 0,10 0,10 10,0 10,0 0),(2.5 2.5,7.5 2.5, 7.5 7.5,2.5 7.5,2.5 2.5))'::geometry as p_geom     union all
select 3, 'POLYGON((0 0,10 0,10 10,0 10,0 0),(2.5 2.5,7.5 2.5, 7.5 7.5,2.5 7.5,2.5 2.5),(0.5 0.5,1.5 0.5,1.5 1.5,0.5 1.5, 0.5 0.5))'::geometry as p_geom    union all
select 4 as id, 'LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2)'::geometry as p_geom union all
select 9 as id, 'LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,4 3)'::geometry as p_geom union all
select 5 as id, 'MULTILINESTRING((0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2),(10 0,11 0,11 1,12 1,12 2,13 2,13 3,13 6,10 6,10 2))'::geometry as p_geom union all
select 6 as id,  'MULTIPOLYGON(((0  0, 9 0, 9  9, 0 9, 0 0),( 2.5 2.5, 7.5 2.5, 7.5 7.5, 2.5 7.5, 2.5 2.5)),
                       ((10 0,19 0,19  9,10 9,10 0),(12.5 2.5,17.5 2.5,17.5 7.5,12.5 7.5,12.5 2.5),(11 1,18 1,18 8,11 8,11 1)))'::geometry as p_geom 
)
select id, p_geom from data as a
union all
select id, spdba.ST_SmoothTile(@p_geom,3) from data as a

with data as (
select 7, 'MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)))' as p_geom union all
select 8, 'MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)),((200000 155300,200010 155300,200010 155310,200000 155310,200000 155300)))'  as p_geom
)
select id, p_geom from data as a
union all 
select id,spdba.ST_SmoothTile(@p_geom) as sGeom from data as a;

with data as (
select 8 as id, ST_GeoMFromText('MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)),((200000 155300,200010 155300,200010 155310,200000 155310,200000 155300)))')  as p_geom
)
,geometries as (
SELECT gs.*, 
     ST_NumGeometries(a.p_geom) as nGeoms,
     ST_GeometryN(a.p_geom,gs.*) as geom
FROM data as a,
     generate_series(1,ST_NumGeometries(a.p_geom)) as gs
 WHERE id = 8
)
select geomN, nGeoms, elemN, nElems
from (
SELECT a.gs as geomN, CAST(null as int) as elemN, CAST(null as int) as nElems, a.nGeoms, a.geom
from geometries as a
 WHERE a.geom.STGeometryType() = 'ST_LineString'
 UNION ALL
SELECT a.gs as geomN, 1 as elemN, 1+ST_NumInteriorRings(a.geom) as nElems, a.nGeoms,ST_ExteriorRing(a.geom) as geom
FROM geometries as a
 WHERE a.geom.STGeometryType() = 'ST_Polygon'
 UNION ALL
SELECT a.gs as geomN,  gs.* + 1 as nElem, 1+ST_NumInteriorRings(a.geom) as nElems, a.nGeoms, ST_InteriorRingN(a.geom,gs.*) as geom
from geometries as a,
   generate_series(1,ST_NumInteriorRings(a.geom)) as gs
 WHERE a.geom.STGeometryType() = 'ST_Polygon'
)  as f
order by 1,2;
*/


