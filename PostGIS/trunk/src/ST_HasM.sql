drop function if exists spdba.ST_HasM(geometry);

create or replace function spdba.ST_HasM(
  p_geometry geometry
)
  RETURNS boolean
 LANGUAGE 'sql'
     COST 100
IMMUTABLE 
AS $$
select case when ST_NDims(p_geometry) = 4 
	   then true
	   when ST_NDims(p_geometry) = 3 and ST_AsText(p_geometry) LIKE '% M %'
	   then true
	   when ST_NDims(p_geometry) = 3 and ST_AsText(p_geometry) NOT LIKE '% M %'
	   then false
	   else false
	   end
$$;

