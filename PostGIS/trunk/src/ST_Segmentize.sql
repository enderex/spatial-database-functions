DROP TYPE IF EXISTS spdba.segment;

CREATE TYPE spdba.segment AS (
  id             integer,
  element_id     integer, 
  sub_element_id integer,
  vector_id      integer,
  sx float,sy float,sz float,sm float,
  mx float,my float,mz float,mm float,
  ex float,ey float,ez float,em float,
  cumulative_length float,
  segment_length    float,
  segment           geometry
);

DROP FUNCTION IF EXISTS spdba.ST_Segmentize(geometry);

CREATE OR REPLACE FUNCTION spdba.ST_Segmentize(
  p_geometry geometry
)
RETURNS SETOF spdba.segment IMMUTABLE 
AS
$$
with geoms as (
SELECT f.element_id,
       ST_GeometryType(f.geom) as mainType,
       f.geom as geom
  FROM (select gs as element_id,
               case when ST_GeometryType(p_geometry) = 'ST_CompoundCurve'
                    then spdba.ST_CurveN(p_geometry,gs)
                    else ST_GeometryN(p_geometry,gs)
                end as geom
          from generate_Series(1,ST_NumGeometries(p_geometry),1) as gs
       ) as f
 where ST_GeometryType(f.geom) <> 'ST_Point'
)
SELECT g.id::integer,
       g.element_id::integer,
       g.sub_element_id::integer,
       g.vector_id::integer,
       g.sx,g.sy,g.sz,g.sm,
       g.mx,g.my,g.mz,g.mm,
       g.ex,g.ey,g.ez,g.em,
       SUM(ST_Length(g.segment)) OVER (order by g.id) as cumulative_length,
       ST_Length(g.segment) as segment_length,
       g.segment
  FROM (SELECT f.id, f.element_id, f.sub_element_id, f.vector_id,
               ST_X(sp) as sx,ST_Y(sp) as sy,ST_Z(sp) as sz,ST_M(sp) as sm,
               case when mp IS not null then ST_X(mp) else CAST(NULL as float) end as mx,
               case when mp IS not null then ST_Y(mp) else CAST(NULL as float) end as my,
               case when mp IS not null then ST_Z(mp) else CAST(NULL as float) end as mz,
               case when mp IS not null then ST_M(mp) else CAST(NULL as float) end as mm,
               ST_X(ep) as ex,ST_Y(ep) as ey,ST_Z(ep) as ez, ST_M(ep) as em,
               case when f.geomType = 'ST_CircularString' 
                    then spdba.ST_MakeCircularString(sp,mp,ep)
                    else ST_GeomFromText(
                         CONCAT('LINESTRING(',ST_X(sp),' ',ST_Y(sp),
                                case when spdba.ST_HasZ(sp) 
                                     then ' ' || case when ST_Z(sp) is not null then ST_Z(sp)::varchar else 'NULL' end 
                                     else        case when spdba.ST_HasZ(sp) then ' NULL' else '' end 
                                 end,
                                case when spdba.ST_HasM(sp) 
                                     then ' ' || case when ST_M(sp) is not null then ST_M(sp)::varchar else 'NULL' end 
                                     else '' 
                                 end,
                                ',',ST_X(ep),' ',ST_Y(ep),
                                case when spdba.ST_HasZ(ep) 
                                     then ' ' || case when ST_Z(ep) is not null then ST_Z(ep)::varchar else 'NULL' end 
                                     else case when spdba.ST_HasZ(ep) then ' NULL' else '' end 
                                 end,
                                case when spdba.ST_HasM(ep) 
                                     then ' ' || case when ST_M(ep) is not null then ST_M(ep)::varchar else 'NULL' end 
                                     else '' 
                                 end,
                                ')'
                         ),ST_Srid(sp)
                         )
                end as segment
          FROM (SELECT row_number() over (order by b.element_id, b.sub_element_id, b.id) as id,
                       b.element_id,
                       b.sub_element_id,
                       b.vector_id,
                       b.geomType,
                       b.sp, b.mp, b.ep
                    FROM (SELECT gs as id, 
                                 a.element_id,
                                 1 as sub_element_id,
                                 gs as vector_id, 
                                 ST_GeometryType(a.geom) as geomType,
                                 ST_PointN(a.geom,gs)   as sp,
                                 CAST(NULL AS geometry) as mp,
                                 ST_PointN(a.geom,gs+1) as ep
                            FROM geoms as a,
                                 generate_series(1,ST_NPoints(a.geom)-1,1) as gs
                           WHERE ST_GeometryType(a.geom) = 'ST_LineString'
                           UNION ALL
                          SELECT row_number() over (order by stringN) as id, 
                                 b.element_id,
                                 1       as sub_element_id,
                                 StringN as vector_id, 
                                 ST_GeometryType(b.geom) as geomType,
                                 ST_PointN(spdba.ST_CircularStringN(b.geom,StringN),1) as sp, 
                                 ST_PointN(spdba.ST_CircularStringN(b.geom,StringN),2) as mp,
                                 ST_PointN(spdba.ST_CircularStringN(b.geom,StringN),3) as ep
                            FROM geoms as b,
                                 generate_series(1,spdba.ST_NumCircularStrings(b.geom),1) as StringN
                           WHERE ST_GeometryType(b.geom) = 'ST_CircularString'
                           UNION ALL
                          SELECT gs as id, 
                                 a.element_id, 
                                 a.sub_element_id, 
                                 gs as vector_id,
                                 ST_GeometryType(a.geom) as geomType,
                                 ST_PointN(a.geom,gs)   as sp, 
                                 CAST(NULL AS geometry) as mp,
                                 ST_PointN(a.geom,gs+1) as ep
                            FROM (SELECT 1 as id, 
                                         a.element_id,
                                         1.sub_element_id, 
                                         ST_ExteriorRing(a.geom) as geom 
                                    FROM geoms as a
                                   WHERE ST_GeometryType(a.geom) = 'ST_Polygon'
                                   UNION ALL
                                  SELECT ir as id, 
                                         a.element_id,
                                         ir + 1 as sub_element_id, 
                                         ST_InteriorRingN(a.geom,ir) as geom
                                    FROM geoms as a ,
                                         generate_series(1,ST_NumInteriorRing(a.geom),1) as ir
                                    WHERE ST_GeometryType(a.geom) = 'ST_Polygon'
                                 ) as a,
                                 generate_series(1,ST_NPoints(a.geom)-1,1) as gs
                         ) as b
                ) as f
          ) as g
  ORDER BY g.id,g.element_id, g.sub_element_id, g.vector_id;
$$
LANGUAGE 'sql';

select * from spdba.ST_Segmentize(ST_GeomFromText('LINESTRING(10 0, 15 5)',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('MULTILINESTRING((0 0,1 0,2 0),(10 0, 15 5))',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('POLYGON((0 0, 9 0, 9  9, 0 9, 0 0),(2.5 2.5, 7.5 2.5, 7.5 7.5, 2.5 7.5, 2.5 2.5))',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('MULTIPOLYGON(((0  0, 9 0, 9  9, 0 9, 0 0)),((2.5 2.5, 7.5 2.5, 7.5 7.5, 2.5 7.5, 2.5 2.5)))',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('MULTIPOLYGON(((0  0, 9 0, 9  9, 0 9, 0 0),( 2.5 2.5, 7.5 2.5, 7.5 7.5, 2.5 7.5, 2.5 2.5)),((10 0,19 0,19  9,10 9,10 0),(12.5 2.5,17.5 2.5,17.5 7.5,12.5 7.5,12.5 2.5),(11 1,18 1,18 8,11 8,11 1)))',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('COMPOUNDCURVE ((4 4, 3 3, 2 2, 0 0),CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0))',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0));
select * from spdba.ST_Segmentize(ST_GeomFromText('CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0)',0));
