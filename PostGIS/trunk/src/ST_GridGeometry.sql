DROP   FUNCTION IF EXISTS spdba.ST_GridGeometry(geometry,numeric,numeric,numeric,numeric,numeric,boolean);

CREATE OR REPLACE FUNCTION spdba.ST_GridGeometry(
  p_geometry    geometry,
  p_TileSizeX   numeric,
  p_TileSizeY   numeric,
  p_rotateX     numeric,
  p_rotateY     numeric,
  p_rotateAngle numeric,
  p_point       boolean
)
Returns SETOF spdba.T_Grid IMMUTABLE
As 
$$
SELECT g.colN,
       g.rowN,
       case when p_point then ST_Centroid(g.tile) else g.tile end as geom
  FROM (SELECT f.colN, 
               f.rowN,
               case when p_rotateX     is not null
                     and p_rotateY     is not null
                     and p_rotateAngle is not null
                    then ST_Rotate(f.tile,
                            RADIANS(p_rotateAngle),
                            ST_SetSrid(ST_MakePoint(p_rotateX,p_rotateY),ST_Srid(p_geometry))
                         )
                    else f.tile
                end as tile
          FROM (SELECT colN, 
                       rowN,
                       ST_SetSRID(
                          ST_MakeBox2D(ST_Point(( colN * p_TileSizeX),               (rowN * p_TileSizeY)),
                             ST_Point(((colN * p_TileSizeX)+p_TileSizeX), ((rowN * p_TileSizeY)+p_TileSizeY))),
                             ST_Srid(p_geometry)
                       )::geometry(Polygon) as tile
                  FROM generate_series(TRUNC( (ST_XMIN(p_geometry) / p_TileSizeX)::numeric)::integer,
                                       CEIL(  (ST_XMAX(p_geometry) / p_TileSizeX)::numeric)::integer - 1,
                                       1
                                      ) as colN,
                       generate_series(TRUNC( (ST_YMIN(p_geometry) / p_TileSizeY)::numeric )::integer,
                                       CEIL(  (ST_YMAX(p_geometry) / p_TileSizeY)::numeric )::integer - 1,
                                       1
                                      ) as rowN
               ) as f
      ) as g;
$$ 
LANGUAGE 'sql';

select * from spdba.ST_GridGeometry('LINESTRING(0 0,10 10)'::geometry,1.0,1.0,0.0,0.0,45.0,true);



