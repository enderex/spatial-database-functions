DROP FUNCTION IF EXISTS  spdba.ST_CircularStringN(geometry,integer);

CREATE OR REPLACE FUNCTION spdba.ST_CircularStringN(
  p_geometry geometry,
  p_stringN  integer
)
 RETURNS geometry 
LANGUAGE 'sql'
    COST 100
IMMUTABLE 
AS 
$$
SELECT f.cString
  FROM (SELECT NumStrings as stringN, 
               spdba.ST_MakeCircularString(
                  ST_PointN(p_geometry,(NumStrings-1)*2 + 1),
                  ST_PointN(p_geometry,(NumStrings-1)*2 + 2),
                  ST_PointN(p_geometry,(NumStrings-1)*2 + 3)
               ) as cString
          FROM generate_series(1,spdba.ST_NumCircularStrings(p_geometry),1) as NumStrings
      ) as f
 WHERE f.stringN = p_stringN;
$$;

with data as (
  select ST_GeomFromText('CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0)',0) as cGeom
)
  SELECT StringN, 
         spdba.ST_CircularStringN(a.cGeom,StringN) as cString
    FROM data as a,
         generate_series(1,spdba.ST_NumCircularStrings(a.cGeom),1) as StringN

