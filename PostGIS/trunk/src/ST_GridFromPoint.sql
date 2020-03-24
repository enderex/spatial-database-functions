-- Assumes TYPE spdba.T_Grid have been created.
DROP FUNCTION IF EXISTS spdba.ST_GridFromPoint(geometry,numeric,numeric,integer,integer,numeric,numeric,numeric,boolean);

CREATE OR REPLACE FUNCTION spdba.ST_GridFromPoint(
  p_geometry    geometry,
  p_TileSizeX   numeric,
  p_TileSizeY   numeric,
  p_NumTilesX   integer,
  p_NumTilesY   integer,
  p_rotateX     numeric,
  p_rotateY     numeric,
  p_rotateAngle numeric,
  p_point       boolean
)
Returns SETOF spdba.T_Grid IMMUTABLE
As 
$$
SELECT f.colN,
       f.rowN,
       case when p_point then ST_Centroid(f.tile) else f.tile end as geom
  FROM (SELECT a.colN,
               a.rowN,
               case when p_rotateX     is not null
                     and p_rotateY     is not null
                     and p_rotateAngle is not null
                    then ST_Rotate(
                            case when p_point then ST_Centroid(a.tile) else a.tile end,
                            RADIANS(p_rotateAngle),
                            ST_SetSrid(ST_MakePoint(p_rotateX,p_rotateY),ST_Srid(p_geometry))
                         )
                    else a.tile
                end as tile
          FROM (SELECT colN, 
                       rowN,
                       ST_SetSRID(
                          ST_MakeBox2D(
                             ST_Point(( colN * p_TileSizeX),               (rowN * p_TileSizeY)),
                             ST_Point(((colN * p_TileSizeX)+p_TileSizeX), ((rowN * p_TileSizeY)+p_TileSizeY))
                          ),
                          ST_Srid(p_geometry)
                       ) as tile
                  FROM generate_series(1,p_NumTilesX,1) as colN,
                       generate_series(1,p_NumTilesY,1) as rowN
               ) as a
       ) as f;
$$ LANGUAGE 'sql';

select * from spdba.ST_GridFromPoint(ST_GeomFromText('POINT(511133.444 6972266.009)',28356),0.003,0.003,10,11,0,0,45,true)
union all
select * from spdba.ST_GridFromPoint(ST_GeomFromText('POINT(511133.444 6972266.009)',28356),0.003,0.003,10,11,0,0,45,false);

