DROP FUNCTION IF EXISTS spdba.st_numcircularstrings(geometry);

CREATE OR REPLACE FUNCTION spdba.st_numcircularstrings(
    p_geometry geometry
)
RETURNS integer
 LANGUAGE 'sql'
     COST 100
IMMUTABLE 
AS 
$BODY$
  SELECT (ST_NumPoints(p_geometry) - 1) / 2  as numCircularStrings
   WHERE p_geometry is not null
$BODY$;

ALTER FUNCTION spdba.st_numcircularstrings(geometry)
    OWNER TO postgres;

