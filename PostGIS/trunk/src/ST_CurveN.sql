drop function if exists spdba.ST_CurveN(geometry,integer);

create or replace function spdba.ST_CurveN(
  p_geometry geometry,
  p_curveN   integer
)
  RETURNS geometry
 LANGUAGE 'sql'
     COST 100
IMMUTABLE 
AS $$
select ST_GeometryN(ST_ForceCollection(p_geometry),p_curveN)
 where p_geometry is not null and p_curveN > 0
$$;


