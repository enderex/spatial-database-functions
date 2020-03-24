DROP FUNCTION IF EXISTS  spdba.ST_NumCurves(geometry);

CREATE OR REPLACE FUNCTION spdba.ST_NumCurves(
  p_geometry geometry
)
 RETURNS integer
LANGUAGE 'plpgsql'
    COST 100
IMMUTABLE 
AS 
$$
BEGIN
  RETURN ST_NumGeometries(p_geometry);
END;
$$;

select spdba.ST_NumCurves(ST_GeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0)) as numCurves;

