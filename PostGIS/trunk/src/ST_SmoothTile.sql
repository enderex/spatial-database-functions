DROP FUNCTION IF EXISTS spdba.ST_SmoothTile(geometry,integer);

CREATE FUNCTION spdba.ST_SmoothTile(
  p_geometry geometry,
  p_precision integer DEFAULT 3
)
RETURNS geometry
LANGUAGE 'plpgsql'
COST 100
VOLATILE 
AS 
$BODY$
Declare
  v_GeometryType varchar(100);
  v_wkt_coords   text;
  v_wkt          text;
  v_end_pt_wkt   varchar(100);
  v_elemN        int := 0;
  v_geomN        int := 0;
  v_nElems       int := 0;
  v_nGeoms       int := 0;
  v_geom         geometry;
  v_precision    int;
  v_fmt_string   varchar(100);
  
  c_elements CURSOR ( p_geom geometry ) 
  IS
    WITH geometries as (
    SELECT gs.*, 
           ST_NumGeometries(p_geom) as nGeoms,
           ST_GeometryN(p_geom,gs.*) as geom
      FROM generate_series(1,ST_NumGeometries(p_geom)) as gs
    )
    SELECT geomN, nGeoms, elemN, nElems, geom 
      FROM (SELECT a.gs as geomN, CAST(null as int) as elemN, CAST(null as int) as nElems, a.nGeoms, a.geom
              FROM geometries as a
             WHERE ST_GeometryType(a.geom) = 'ST_LineString'
             UNION ALL
            SELECT a.gs as geomN, 1 as elemN, ST_NRings(a.geom) as nElems,nGeoms, ST_ExteriorRing(a.geom) as geom
              FROM geometries as a
             WHERE ST_GeometryType(a.geom) = 'ST_Polygon'
             UNION ALL
            SELECT a.gs as geomN,  gs.* + 1 as nElem, ST_NRings(a.geom) as nElems,nGeoms, ST_InteriorRingN(a.geom,gs.*) as geom
              FROM geometries as a,
                   generate_series(1,ST_NumInteriorRings(a.geom)) as gs
             WHERE ST_GeometryType(a.geom) = 'ST_Polygon'
           )  as f
     ORDER BY 1,2;

Begin
  If ( p_geometry is null ) Then
    Return p_geometry;
  End If;

  v_GeometryType := ST_GeometryType(p_geometry);
  if ( v_GeometryType not in ('ST_Polygon','ST_LineString','ST_MultiPolygon','ST_MultiLineString') ) Then
    Return p_geometry;
  End If;
  -- raise notice '%', v_GeometryType;

  if ( ST_HasArc(p_geometry) ) then
    Raise exception 'Compound geometries are not supported.';
  End If;

  if ( ST_NDims(p_geometry)<>2 ) then
    Raise exception 'Only 2D geometries supported.';
  End If;

  v_wkt := '';
  v_precision := case when p_precision is null then 3 else p_precision end;
  v_fmt_string := CONCAT('FM999999999999990D',RPAD('0',v_precision,'9'));
  OPEN c_elements(p_geometry);
    LOOP
      FETCH c_elements INTO v_geomN, v_nGeoms, v_elemN, v_nElems, v_geom;
      EXIT WHEN NOT FOUND;
      --raise notice 'geomN(%), nGeoms(%), elemN(%), nElems(%), GeometryType(%)',v_geomN, v_nGeoms, v_elemN, v_nElems, v_geometryType;
      -- process coordinates of this element 
      select string_agg(
               concat(TO_CHAR(mx::numeric,v_fmt_string),
                      ' ',
                      TO_CHAR(my::numeric,v_fmt_string)),
                      ',' 
                      order by rid) as coord
        into v_wkt_coords
        FROM (select rid, slope, next_slope, mx, my
               FROM (select rid,
                            slope,
                            lag(slope,1)  over (order by rid) as prev_Slope,
                            lead(slope,1) over (order by rid) as next_Slope,
                            mx,my
                       FROM (select rid,
                                    CASE WHEN (mx - lag(mx,1) over (order by rid)) = 0
                                         THEN 10
                                         ELSE (mY - lag(my,1) over (order by rid)) / (mx - lag(mx,1) over (order by rid))
                                     END as slope,
                                    lag(mx,1) over (order by rid) as lagX,
                                    lag(my,1) over (order by rid) as lagY,
                                    mx, my
                               FROM (select row_number() over () as rid,
                                            ((seg.startCoord).x + (seg.endCoord).x) / 2.0 as mX,
                                            ((seg.startCoord).y + (seg.endCoord).y) / 2.0 as mY
                                       FROM spdba.ST_Vectorize(v_geom) as seg
                                    ) as u
                            ) as v
                    ) as w
             ) as b
       where b.slope is null
          or b.slope <> b.next_slope
          or b.next_slope is null;
      IF ( v_geometryType = 'ST_LineString' ) THEN
        /* LineString
           geomN,nGeoms,elemN,nElems
           1,1,null,null
        */
        v_wkt := v_wkt_coords;
      ELSIF ( v_geometryType = 'ST_MultiLineString' ) THEN
        IF (v_geomN=1 and v_elemN is null and v_nElems is null and v_nGeoms=1 ) THEN
          /* MultiLineString
           geomN,nGeoms,elemN,nElems
           1,2,null,null
           2,2,null,null
          */
        ELSIF ( v_geomN=1 and v_nGeoms is not null and v_elemN is null and v_nElems is null ) THEN 
          -- raise notice '%','Start MultiLine';
          v_wkt := CONCAT('(',v_wkt_coords,')');
        ELSIF ( v_geomN>1 and v_nGeoms is not null and v_elemN is null and v_nElems is null ) THEN
          -- raise notice '%','End MultiLine';
          v_wkt := CONCAT(v_wkt,',(',v_wkt_coords,')');
        END IF;

      ELSIF ( v_geometryType = 'ST_Polygon' ) THEN
        /* Polygon
           geomN,nGeoms,elemN,nElems
           1,1,1,3
           1,1,2,3
           1,1,3,3
        */
        -- Get missing end point
        v_end_pt_wkt := SUBSTRING(v_wkt_coords,1,POSITION(',' in v_wkt_coords)-1);
        IF ( v_elemN=1 ) THEN 
          v_wkt := CONCAT('(',v_wkt_coords,',',v_end_pt_wkt,')');
          -- Raise Notice 'Start Polygon - Exterior Ring';
        ELSE
          v_wkt := CONCAT(v_wkt,',(',v_wkt_coords,',',v_end_pt_wkt,')');
          -- Raise Notice 'Interior Ring';
        END IF;

      ELSIF ( v_geometryType = 'ST_MultiPolygon' ) THEN
        --raise notice 'v_wkt_coords %',v_wkt_coords;
        --raise notice 'Start v_wkt %',v_wkt;
        /* MultiPolygon
           geomN,nGeoms,elemN,nElems
           1,2,1,2
           1,2,2,2
           2,2,1,3
           2,2,2,3
           2,2,3,3
           GeometryN = 2 with 1 Exterior Ring per poly           
           1,2,1,1
           2,2,1,1
        */
        -- Get missing end point
        v_end_pt_wkt := SUBSTRING(v_wkt_coords,1,POSITION(',' in v_wkt_coords)-1);
        -- raise notice '% %', 'End Point: ', v_end_pt_wkt;
        IF ( v_elemN=1 ) THEN  -- New Polygon and its Exterior Ring
          -- raise notice 'v_geomN %',v_geomN;
          IF ( v_geomN = 1 ) THEN -- First Polygon
            v_wkt := CONCAT('((',
                            v_wkt_coords,
                            ',',
                            v_end_pt_wkt,
                            ')'
                           );
          ELSE /* v_geomN > 1 */ 
            v_wkt := CONCAT(v_wkt,
                            ',((',
                            v_wkt_coords,
                            ',',
                            v_end_pt_wkt,
                            ')'
                            );
          END IF;
          -- IF NOTHING ELSE
          -- Interior Rings
          -- raise notice 'Polygon %', v_wkt;
        ELSE
          -- Interior Ring
          v_wkt := CONCAT(v_wkt,',(',v_wkt_coords,',',v_end_pt_wkt,')');
          -- raise notice 'Inner ring %',v_wkt;
        END IF;
        IF (v_elemN=v_nElems) Then 
          -- End of Geometry and rings
          v_wkt := CONCAT(v_wkt,')');
          -- raise notice 'End Polygon and its Rings %',v_wkt;
        END IF; 
      END IF; 
    END LOOP;
  CLOSE c_elements;
  v_wkt := CONCAT( UPPER(REPLACE(v_geometryType,'ST_','')),' (',v_wkt,')');
  -- raise notice '%', v_wkt;
  Begin
    v_geom := ST_GeomFromText(v_wkt,ST_Srid(p_geometry));
    EXCEPTION
      WHEN OTHERS THEN
		v_geom := p_geometry;
  End;
  Return v_geom;
END;
$BODY$;

ALTER FUNCTION spdba.st_smoothtile(geometry, integer)
  OWNER TO postgres;

select TO_CHAR(3834784.00009,CONCAT('FM999999999999990D',RPAD('0',3,'9')));

with data as (
select ST_GeomFromText('POLYGON((0 0,1 0,2 0,3 0,4 0,5 0,6 0,7 0,8 0,9 0,10 0,10 1,9 1,8 1,7 1,6 1,5 1,4 1,3 1,2 1,1 1,0 1,0 0))') as geom
)
select (ST_DumpPoints(spdba.ST_SmoothTile(a.geom,3))).geom from data as a
union all
select spdba.ST_SmoothTile(a.geom,3) from data as a
union all
select a.geom from data as a;


with data as (
select 1 as id, 'POLYGON((0 0,10 0,10 10,0 10,0 0))'::geometry as p_geom     union all
select 2, 'POLYGON((0 0,10 0,10 10,0 10,0 0),(2.5 2.5,7.5 2.5, 7.5 7.5,2.5 7.5,2.5 2.5))'::geometry as p_geom     union all
select 3, 'POLYGON((0 0,10 0,10 10,0 10,0 0),(2.5 2.5,7.5 2.5, 7.5 7.5,2.5 7.5,2.5 2.5),(0.5 0.5,1.5 0.5,1.5 1.5,0.5 1.5, 0.5 0.5))'::geometry as p_geom    union all
select 4 as id, 'LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2)'::geometry as p_geom union all
select 9 as id, 'LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,4 3)'::geometry as p_geom union all
select 5 as id, 'MULTILINESTRING((0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2),(10 0,11 0,11 1,12 1,12 2,13 2,13 3,13 6,10 6,10 2))'::geometry as p_geom union all
select 6 as id,  'MULTIPOLYGON(((0  0, 9 0, 9  9, 0 9, 0 0),( 2.5 2.5, 7.5 2.5, 7.5 7.5, 2.5 7.5, 2.5 2.5)),
                       ((10 0,19 0,19  9,10 9,10 0),(12.5 2.5,17.5 2.5,17.5 7.5,12.5 7.5,12.5 2.5),(11 1,18 1,18 8,11 8,11 1)))'::geometry as p_geom 
)
select id, p_geom from data as a
union all
select id, spdba.ST_SmoothTile(p_geom,3) from data as a

with data as (
select 7, 'MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)))' as p_geom union all
select 8, 'MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)),((200000 155300,200010 155300,200010 155310,200000 155310,200000 155300)))'  as p_geom
)
select id, p_geom from data as a
union all 
select id,spdba.ST_SmoothTile(p_geom) as sGeom from data as a;

with data as (
select 8 as id, ST_GeoMFromText('MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)),((200000 155300,200010 155300,200010 155310,200000 155310,200000 155300)))')  as p_geom
)
,geometries as (
SELECT gs.*, 
     ST_NumGeometries(a.p_geom) as nGeoms,
     ST_GeometryN(a.p_geom,gs.*) as geom
FROM data as a,
     generate_series(1,ST_NumGeometries(a.p_geom)) as gs
 WHERE id = 8
)
select geomN, nGeoms, elemN, nElems
from (
SELECT a.gs as geomN, CAST(null as int) as elemN, CAST(null as int) as nElems, a.nGeoms, a.geom
from geometries as a
 WHERE ST_GeometryType(a.geom) = 'ST_LineString'
 UNION ALL
SELECT a.gs as geomN, 1 as elemN, 1+ST_NumInteriorRings(a.geom) as nElems, a.nGeoms,ST_ExteriorRing(a.geom) as geom
FROM geometries as a
 WHERE ST_GeometryType(a.geom) = 'ST_Polygon'
 UNION ALL
SELECT a.gs as geomN,  gs.* + 1 as nElem, 1+ST_NumInteriorRings(a.geom) as nElems, a.nGeoms, ST_InteriorRingN(a.geom,gs.*) as geom
from geometries as a,
   generate_series(1,ST_NumInteriorRings(a.geom)) as gs
 WHERE ST_GeometryType(a.geom) = 'ST_Polygon'
)  as f
order by 1,2;
 



