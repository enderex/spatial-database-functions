DROP FUNCTION IF EXISTS spdba.ST_SplayNSEW(geometry, integer, varchar, integer, numeric, numeric);

CREATE OR REPLACE FUNCTION spdba.ST_SplayNSEW(
  p_geometry            geometry,
  p_position            integer    DEFAULT 1,
  p_direction           varchar(2) DEFAULT 'N',
  p_number_of_locations integer    DEFAULT 1,
  p_splay_offset        numeric    DEFAULT 1.0,
  p_splay_delta         numeric    DEFAULT 0.25
)
 RETURNS geometry
LANGUAGE 'plpgsql'
    COST 100
VOLATILE 
AS 
$BODY$
DECLARE
  v_direction           varchar(2);
  v_tx                  numeric;
  v_ty                  numeric;
  v_position            integer;
  v_number_of_locations integer;
  v_splay_offset        float;
  v_splay_delta         float;
  v_splay_point         geometry;
  v_splay_geometry      geometry;
BEGIN
  IF ( p_geometry is null ) THEN
    RETURN p_geometry;
  END IF;
  v_direction           := UPPER(COALESCE(p_direction,'N'));
  IF ( v_direction not in ('N','S','E','W',
                           'NE','SE','SW','NW',
                           'WS','WN','ES','EN') ) THEN
    return p_geometry;
  END IF;  
  v_position            := COALESCE(ABS(p_position),1);
  v_number_of_locations := COALESCE(ABS(p_number_of_locations),1);
  v_splay_offset        := COALESCE(p_splay_offset,1.0);
  v_splay_delta         := COALESCE(p_splay_delta,0.25);
  v_tx                  := case v_direction
                           when 'N'  then 0.0
                           when 'S'  then 0.0
                           when 'E'  then        (v_splay_offset + (v_splay_delta * (v_position-1)))
                           when 'W'  then -1.0 * (v_splay_offset + (v_splay_delta * (v_position-1)))
                           
                           when 'NE' then        (v_splay_delta * (v_position-1))
                           when 'NW' then -1.0 * (v_splay_delta * (v_position-1))
                           when 'SE' then        (v_splay_delta * (v_position-1))
                           when 'SW' then -1.0 * (v_splay_delta * (v_position-1))
                           
                           when 'WN' then -1.0 * v_splay_offset
                           when 'WS' then -1.0 * v_splay_offset
                           when 'EN' then        v_splay_offset
                           when 'ES' then        v_splay_offset

                           end;
  v_ty                  := case v_direction
                           when 'N'  then        (v_splay_offset + (v_splay_delta * (v_position-1)))
                           when 'S'  then -1.0 * (v_splay_offset + (v_splay_delta * (v_position-1)))
                           when 'E'  then 0.0
                           when 'W'  then 0.0
                           
                           when 'NE' then v_splay_offset
                           when 'NW' then v_splay_offset
                           when 'SE' then -1.0 * v_splay_offset
                           when 'SW' then -1.0 * v_splay_offset
                           
                           when 'WN' then        (v_splay_delta * (v_position-1))
                           when 'WS' then -1.0 * (v_splay_delta * v_position)
                           when 'EN' then        (v_splay_delta * (v_position-1))
                           when 'ES' then -1.0 * (v_splay_delta * (v_position-1))

                            end;
  -- Move supplied object to splay position
  If ( NOT (v_tx = 0 and v_ty = 0 ) ) Then
    v_splay_geometry := ST_Translate(p_geometry,v_tx,v_ty);
  else
    v_splay_geometry := p_geometry;
  End If;
  RETURN v_splay_geometry;
END;
$BODY$;

ALTER FUNCTION spdba.st_splayNSEW(geometry, integer, varchar, integer, numeric, numeric)
    OWNER TO postgres;

-- **********************************************************************************************

DROP FUNCTION IF EXISTS spdba.ST_SplayOffsetDeltaNSEW(geometry, integer, varchar, integer, numeric, numeric, numeric, numeric);

CREATE OR REPLACE FUNCTION spdba.ST_SplayOffsetDeltaNSEW(
  p_geometry            geometry,
  p_position            integer    DEFAULT 1,
  p_direction           varchar(2) DEFAULT 'N',
  p_number_of_locations integer    DEFAULT 1,
  p_offset_north_south  numeric    DEFAULT 1.0,
  p_delta_north_south   numeric    DEFAULT 0.25,
  p_offset_east_west    numeric    DEFAULT 1.0,
  p_delta_east_west     numeric    DEFAULT 0.25
)
 RETURNS geometry
LANGUAGE 'plpgsql'
    COST 100
VOLATILE 
AS 
$BODY$
DECLARE
  v_direction           varchar(2);
  v_tx                  numeric;
  v_ty                  numeric;
  v_position            integer;
  v_number_of_locations integer;
  v_offset_north_south  float;
  v_delta_north_south   float;
  v_offset_east_west    float;
  v_delta_east_west     float;
  v_splay_point         geometry;
  v_splay_geometry      geometry;
BEGIN
  IF ( p_geometry is null ) THEN
    RETURN p_geometry;
  END IF;
  v_direction           := UPPER(COALESCE(p_direction,'N'));
  IF ( v_direction not in ('N','S','E','W',
                           'NE','SE','SW','NW',
                           'WS','WN','ES','EN') ) THEN
    return p_geometry;
  END IF;  
  v_position            := COALESCE(ABS(p_position),1);
  v_number_of_locations := COALESCE(ABS(p_number_of_locations),1);
  v_offset_north_south  := COALESCE(p_offset_north_south,1.0);
  v_delta_north_south   := COALESCE(p_delta_north_south,0.25);
  v_offset_east_west    := COALESCE(p_offset_east_west,1.0);
  v_delta_east_west     := COALESCE(p_delta_east_west,0.25);
  v_tx                  := case v_direction
                           when 'N'  then 0.0
                           when 'S'  then 0.0
                           when 'E'  then        (v_offset_east_west + (v_delta_east_west * (v_position-1)))
                           when 'W'  then -1.0 * (v_offset_east_west + (v_delta_east_west * (v_position-1)))
                           
                           when 'NE' then        (v_delta_east_west   * (v_position-1))
                           when 'NW' then -1.0 * (v_delta_east_west   * (v_position-1))
                           when 'SE' then        (v_delta_north_south * (v_position-1))
                           when 'SW' then -1.0 * (v_delta_north_south * (v_position-1))
                           
                           when 'WN' then -1.0 * v_offset_east_west
                           when 'WS' then -1.0 * v_offset_east_west
                           when 'EN' then        v_offset_east_west
                           when 'ES' then        v_offset_east_west

                           end;
  v_ty                  := case v_direction
                           when 'N'  then        (v_offset_north_south + (v_delta_north_south * (v_position-1)))
                           when 'S'  then -1.0 * (v_offset_north_south + (v_delta_north_south * (v_position-1)))
                           when 'E'  then 0.0
                           when 'W'  then 0.0
                           
                           when 'NE' then v_offset_north_south
                           when 'NW' then v_offset_north_south
                           when 'SE' then -1.0 * v_offset_north_south
                           when 'SW' then -1.0 * v_offset_north_south
                           
                           when 'WN' then        (v_delta_north_south * (v_position-1))
                           when 'WS' then -1.0 * (v_delta_north_south * v_position)
                           when 'EN' then        (v_delta_north_south * (v_position-1))
                           when 'ES' then -1.0 * (v_delta_north_south * (v_position-1))

                            end;
  -- Move supplied object to splay position
  If ( NOT (v_tx = 0 and v_ty = 0 ) ) Then
    v_splay_geometry := ST_Translate(p_geometry,v_tx,v_ty);
  else
    v_splay_geometry := p_geometry;
  End If;
  RETURN v_splay_geometry;
END;
$BODY$;

ALTER FUNCTION spdba.st_splayOffsetDeltaNSEW(geometry, integer, varchar, integer, numeric, numeric, numeric, numeric)
    OWNER TO postgres;

