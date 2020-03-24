-- FUNCTION: spdba.st_line_offset(geometry, double precision)

-- DROP FUNCTION IF EXISTS spdba.st_line_offset(geometry, double precision);

CREATE OR REPLACE FUNCTION spdba.ST_Line_Offset(
  p_geometry      geometry,
  p_offset double precision
)
RETURNS geometry
LANGUAGE 'plpgsql'
COST 100
IMMUTABLE 
AS $BODY$
Declare
  v_id          integer;
  v_geomType    varchar(100);
  v_geometry    geometry;
  v_geomn       geometry;
  v_geomo       geometry;
  v_build_geom  geometry;
  v_return_geom geometry;
Begin
  IF ( p_geometry is null or p_offset is null) THEN
    RETURN p_geometry;
  END IF;
  v_geomType := ST_GeometryType(p_geometry);
  IF ( v_geomType NOT IN ('ST_LineString','ST_MultiLineString','ST_GeometryCollection') ) THEN
    RETURN null;
  END IF;

  IF ( v_geomType = 'ST_LineString' ) Then
    IF ( ST_IsSimple(p_geometry) ) THEN
      Return ST_OffsetCurve(p_geometry,p_offset);
	END IF;
    -- Break into individual vertex-to-vertex segments and save to GeometryCollection for processing later on
	SELECT ST_Collect(a.segment)
      INTO v_geometry
	  FROM (SELECT v.segment
              FROM spdba.ST_VectorAsSegment(p_geometry) as v
             ORDER BY v.id
		   ) as a;
  ELSE 
    v_geometry := p_geometry;
  END IF;
  
  -- Now process elements
  v_build_geom  := NULL;
  v_return_geom := NULL;
  FOR v_id in 1..ST_NumGeometries(v_geometry) LOOP
    BEGIN
      v_geomn := ST_GeometryN(v_geometry,v_id);
      IF ( ST_GeometryType(v_geomn) <> 'ST_LineString' ) THEN
        CONTINUE;
      END IF;
      IF ( v_build_geom is null ) THEN
        v_build_geom := v_geomn;
        CONTINUE;
      END IF;

      IF ( ST_IsSimple(ST_MakeLine(v_build_geom,v_geomn)) ) THEN
        v_build_geom := ST_MakeLine(v_build_geom,v_geomn);
        IF ( v_id <> ST_NumGeometries(v_geometry) ) THEN
          CONTINUE;
        END IF;
      END IF;
      
      -- We need to offset and start again
      v_geomo := ST_OffsetCurve(v_build_geom,p_offset);
      IF ( v_return_geom is null ) THEN
        v_return_geom := v_geomo;
      ELSE
        v_return_geom := ST_MakeLine(v_return_geom,v_geomo);
      END IF;
      v_build_geom := v_geomn;
      EXCEPTION 
        WHEN OTHERS THEN
          RAISE NOTICE 'ST_OffsetCurve failed with %',SQLERRM ;
    END;
  END LOOP;
  RETURN v_return_geom;
End;
$BODY$;

ALTER FUNCTION spdba.st_line_offset(geometry, double precision)
    OWNER TO postgres;

select ST_GeomFromText('LINESTRING (511132.198 6972267.7, 511132.198 6972267.9, 511132.272 6972267.9, 511132.198 6972267.9, 511132.0   6972267.9,  511132.1 6972267.95)',28356)
union all
select ST_OffsetCurve(ST_GeomFromText('LINESTRING (511132.198 6972267.7, 511132.198 6972267.9, 511132.272 6972267.9, 511132.198 6972267.9, 511132.0   6972267.9,  511132.1 6972267.95)',28356), -0.01);

select ST_GeomFromText('LINESTRING (511132.198 6972267.7, 511132.198 6972267.9, 511132.272 6972267.9, 511132.198 6972267.9, 511132.0   6972267.9,  511132.1 6972267.95)',28356)
union all
select spdba.ST_Line_Offset(ST_GeomFromText('LINESTRING (511132.198 6972267.7, 511132.198 6972267.9, 511132.272 6972267.9, 511132.198 6972267.9, 511132.0   6972267.9,  511132.1 6972267.95)',28356), -0.01);
