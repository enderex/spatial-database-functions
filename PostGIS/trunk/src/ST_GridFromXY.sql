-- ****************************************************************************************************
-- Drop functions and type.

DROP FUNCTION IF EXISTS spdba.ST_GridFromXY(numeric,numeric,numeric,numeric,numeric,numeric,numeric,numeric,numeric,int4,boolean);

CREATE OR REPLACE FUNCTION spdba.ST_GridFromXY(
  p_xmin        numeric,
  p_ymin        numeric,
  p_xmax        numeric,
  p_ymax        numeric,
  p_TileSizeX   numeric,
  p_TileSizeY   numeric,
  p_rotateX     numeric,
  p_rotateY     numeric,
  p_rotateAngle numeric,
  p_srid        int4,
  p_point       boolean
)
Returns SETOF spdba.T_Grid IMMUTABLE
As 
$$
SELECT g.colN,
       g.rowN,
       case when p_point then ST_Centroid(g.tile) else g.tile end as geom
  FROM (SELECT colN,
               rowN,
               case when p_rotateX     is not null
                     and p_rotateY     is not null
                     and p_rotateAngle is not null
                    then ST_Rotate(f.tile,
                               RADIANS(p_rotateAngle),
                               ST_SetSrid(ST_MakePoint(p_rotateX,p_rotateY),p_srid)
                            )
                    else f.tile
                end as tile
          FROM (SELECT colN,
                       rowN,
                       ST_SetSRID(
                          ST_MakeBox2D(
                             ST_Point(( colN * p_TileSizeX),               (rowN * p_TileSizeY)),
                             ST_Point(((colN * p_TileSizeX)+p_TileSizeX), ((rowN * p_TileSizeY)+p_TileSizeY))
                          ),
                          p_srid
                       )::geometry(Polygon) as tile
                  FROM generate_series(
                         TRUNC((p_XMIN / p_TileSizeX)::numeric )::integer,
                         CEIL( (p_XMAX / p_TileSizeX)::numeric )::integer - 1,
                         1) as ColN,
                       generate_series(
                         TRUNC((p_YMIN / p_TileSizeY)::numeric )::integer,
                         CEIL( (p_YMAX / p_TileSizeY)::numeric )::integer - 1,
                         1) as rowN
               ) as f
       ) as g;
$$
LANGUAGE 'sql';

select geom
  from spdba.ST_GridFromXY(0,0,100,100,
                           2.5,3.5,
                           NULL,NULL,NULL,
                           0,false) as gxy;

select *
  from spdba.ST_GridFromXY(0,0,100,100,
                           2.5,3.5,
                           0,0,45,
                           0,true) as gxy;

WITH geomQuery AS (
SELECT ST_XMIN(g.geom)::numeric as xmin, round(ST_XMAX(g.geom)::numeric,2)::numeric as xmax, 
       ST_YMIN(g.geom)::numeric as ymin, round(ST_YMAX(g.geom)::numeric,2)::numeric as ymax,
       g.geom, 0.050::numeric as gridX, 0.050::numeric as gridY, 0::int4 as loCol, 0::int4 as loRow
  FROM (SELECT ST_SymDifference(ST_Buffer(a.geom,1.000::numeric),ST_Buffer(a.geom,0.50::numeric)) as geom 
          FROM (SELECT ST_GeomFromText('MULTIPOINT((09.25 10.00),(10.75 10.00),(10.00 10.75),(10.00 9.25))',0) as geom ) as a
       ) as g 
)
SELECT row_number() over (order by f.gcol, f.grow) as tid,
       f.gcol,
       f.grow,
       count(*) as UnionedTileCount,
       ST_Union(f.geom) as geom
  FROM (SELECT case when ST_GeometryType(b.geom) in ('ST_Polygon','ST_MultiPolygon')
                    then ST_Intersection(b.ageom,b.geom) 
                    else b.geom
                end as geom, 
               b.gcol, b.grow, b.loCol, b.loRow
          FROM (SELECT a.geom as ageom, a.loCol, a.loRow,
                       (spdba.ST_GridFromXY(a.xmin,a.ymin,a.xmax,a.ymax,a.gridX,a.gridY,0,0,0,ST_Srid(a.geom))).*
                  FROM geomQuery as a 
                ) as b
         WHERE ST_Intersects(b.ageom,b.geom) 
        ) as f 
 WHERE position('POLY' in UPPER(ST_AsText(f.geom))) > 0
 GROUP BY f.gcol, f.grow, f.loCol, f.loRow
 ORDER BY  2;

WITH geomQuery AS (
SELECT g.rid,
       (min(ST_XMIN(g.geom))                   over (partition by g.pid))::numeric  as xmin, 
       (max(round(ST_XMAX(g.geom)::numeric,2)) over (partition by g.pid))::numeric as xmax, 
       (min(ST_YMIN(g.geom))                   over (partition by g.pid))::numeric as ymin, 
       (max(round(ST_YMAX(g.geom)::numeric,2)) over (partition by g.pid))::numeric as ymax,
       g.geom, 0.050::numeric as gridX, 0.050::numeric as gridY, 0::int4 as loCol, 0::int4 as loRow
  FROM (SELECT 1::int4 as pid, a.rid, ST_SymDifference(ST_Buffer(a.geom,1.000::numeric),ST_Buffer(a.geom,0.750::numeric)) as geom 
          FROM (SELECT 1::int4 as rid, ST_GeomFromText('POINT(09.50 10.00)',0) as geom
      UNION ALL SELECT 2::int4 as rid, ST_GeomFromText('POINT(10.50 10.00)',0) as geom
      UNION ALL SELECT 3::int4 as rid, ST_GeomFromText('POINT(10.00 10.50)',0) as geom
      UNION ALL SELECT 4::int4 as rid, ST_GeomFromText('POINT(10.00 09.50)',0) as geom ) a
       ) g                         
)
SELECT row_number() over (order by f.gcol, f.grow) as tid,
       f.gcol,
       f.grow,
       count(*) as UnionedTileCount,
       ST_Union(f.geom) as geom
  FROM (SELECT case when ST_GeometryType(b.geom) in ('ST_Polygon','ST_MultiPolygon')
                    then ST_Intersection(b.ageom,b.geom) 
                    else b.geom
                end as geom, 
               b.gcol, b.grow, b.loCol, b.loRow
          FROM (SELECT a.geom as ageom, a.loCol, a.loRow,
                       (spdba.ST_GridFromXY(a.xmin,a.ymin,a.xmax,a.ymax,a.gridX,a.gridY,0,0,0,ST_Srid(a.geom))).*
                  FROM geomQuery a 
                ) b
         WHERE ST_Intersects(b.ageom,b.geom) 
        ) f 
 WHERE position('POLY' in UPPER(ST_AsText(f.geom))) > 0
 GROUP BY f.gcol, f.grow, f.loCol, f.loRow
 ORDER BY  2;
 -- 2136 


