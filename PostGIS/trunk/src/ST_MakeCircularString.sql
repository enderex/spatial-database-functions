DROP FUNCTION IF EXISTS spdba.ST_MakeCircularString(geometry,geometry,geometry);

CREATE OR REPLACE FUNCTION spdba.ST_MakeCircularString(
  p_point1 geometry,
  p_point2 geometry,
  p_point3 geometry
)
RETURNS geometry
LANGUAGE 'plpgsql'
    COST 100
IMMUTABLE 
AS 
$$
DECLARE
  v_zm varchar(2);
BEGIN
  IF (p_point1 is null or p_point2 is null or p_point3 is null) THEN
    RETURN NULL;
  END IF;
  IF (ST_GeometryType(p_point1) <> 'ST_Point' or 
      ST_GeometryType(p_point2) <> 'ST_Point' or
      ST_GeometryType(p_point3) <> 'ST_Point') THEN
    RETURN NULL;
  END IF;
  v_zm = case when spdba.ST_HasZ(p_point1) then 'Z' else '' end ||
         case when spdba.ST_HasM(p_point1) then 'M' else '' end;
  RETURN ST_GeomFromText(
            CONCAT('CIRCULARSTRING ',
                   v_zm,
                   '( ',
                   REPLACE(SUBSTRING(ST_AsText(p_point1),position('(' in ST_AsText(p_point1))+1,100),')',''),
                   ',',
                   REPLACE(SUBSTRING(ST_AsText(p_point2),position('(' in ST_AsText(p_point2))+1,100),')',''),
                   ',',
                   REPLACE(SUBSTRING(ST_AsText(p_point3),position('(' in ST_AsText(p_point3))+1,100),')',''),
                   ')'
            ),
            ST_Srid(p_point1)
         );
END;
$$;

select ST_AsText(
          spdba.ST_MakeCircularString(
            ST_GeomFromText('POINT (0 0)',0),
            ST_GeomFromText('POINT (1 2.1082)',0),
            ST_GeomFromText('POINT (3 6.3246)',0)
          )
       );

select ST_AsText(
          spdba.ST_MakeCircularString(
            ST_GeomFromText('POINT Z (0 0      1)',0),
            ST_GeomFromText('POINT Z (1 2.1082 1)',0),
            ST_GeomFromText('POINT Z (3 6.3246 1)',0)
          )
       );

select ST_AsText(
          spdba.ST_MakeCircularString(
            ST_GeomFromText('POINT M (0 0 0)',0),
            ST_GeomFromText('POINT M (1 2.1082 0)',0),
            ST_GeomFromText('POINT M (3 6.3246 0)',0)
          )
       );

select ST_AsText(
          spdba.ST_MakeCircularString(
            ST_GeomFromText('POINT ZM (0 0      0 1)',0),
            ST_GeomFromText('POINT ZM (1 2.1082 0 2)',0),
            ST_GeomFromText('POINT ZM (3 6.3246 0 3)',0)
          )
       );

