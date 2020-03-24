DROP FUNCTION IF EXISTS spdba.ST_Reduce(geometry,numeric,varchar(5),integer,integer);

CREATE OR REPLACE FUNCTION spdba.ST_Reduce
(
  p_linestring       geometry,
  p_reduction_length numeric,
  p_end              varchar(5) = 'START',
  p_round_xy         integer   = 3,
  p_round_zm         integer   = 2
)
returns geometry
as
$BODY$
/****f* EDITOR/ST_Reduce (2008)
 *  NAME
 *    STReduce -- Function that shortens the supplied linestring at either its start or end (p_end) the required length.

 *  SYNOPSIS
 *    Function ST_Reduce (
 *               p_linestring       geometry,
 *               p_reduction_length float,
 *               p_end              varchar(5),
 *               p_round_xy         integer = 3,
 *               p_round_zm         integer = 2
 *             )
 *     Returns geometry
 *  USAGE
 *    SELECT ST_AsText(spdba.ST_Reduce(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),5.0,'START',2,1)) as reducedGeom;
 *    # reducedGeom
 *    'LINESTRING(-4.9 30.2,-3.6 31.5)'
 *  DESCRIPTION
 *    Function that shortens the supplied linestring at either its start or end (p_end) the required length.
 *    The function can apply the reduction at either ends (or both).
 *    The function will remove existing vertices as the linestring is shortened. 
 *    If the linestring reduces to nothing, an error will be thrown by STGeomFromText.
 *    Any computed ordinates of the new geometry are rounded to p_round_xy/p_round_zm number of decimal digits of precision.
 *  NOTES
 *    MultiLinestrings and CircularString linestrings are not supported.
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    p_linestring        (geometry) - Supplied geometry of type LINESTRING only.
 *    p_reduction_length  (float)    - Length to reduce linestring by in SRID units.
 *    p_end               (varchar5) - START means reduce line at its start; END means extend at its end and BOTH means extend at both START and END of line.
 *    p_round_xy          (int)      - Round XY ordinates to supplied decimal digits of precision.
 *    p_round_zm          (int)      - Round ZM ordinates to supplied decimal digits of precision.
 *  RESULT
 *    linestring           (geometry) - Input geometry extended as instructed.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
Declare
  v_GeometryType     varchar(100);
  v_isGeography      boolean;
  v_reduction_length float;
  v_round_xy         integer;
  v_round_zm         integer;
  v_geom_length      float = 0;
  v_end              varchar(5);
  v_deltaX           float;
  v_deltaY           float;
  v_segment_length   float;
  v_pt_id            integer = 0;
  v_end_pt           geometry;
  v_internal_pt      geometry;
  v_new_point        geometry;
  v_linestring       geometry;
Begin
  IF ( p_linestring is NULL )THEN
    Return Null;
  END IF;

  -- Only support simple linestrings
  v_GeometryType := ST_GeometryType(p_linestring);

  IF ( v_GeometryType <> 'ST_LineString' ) THEN
    Return p_linestring;
  END IF;

  IF ( v_end NOT IN ('START','BOTH','END') ) THEN
    Return p_linestring;
  END IF;

  IF ( p_reduction_length is NULL OR p_reduction_length = 0 ) THEN
    Return p_linestring;
  END IF;

  v_isGeography      := false; -- spdba.ST_IsGeographicSrid(ST_Srid(p_linestring));
  v_round_xy         := COALESCE(p_round_xy,3);
  v_round_zm         := COALESCE(p_round_zm,2);
  v_linestring       := p_linestring;
  v_reduction_length := ABS(p_reduction_length);
  v_end              := UPPER(SUBSTRING(COALESCE(p_end,'START'),1,5));

  -- Is reduction distance (when BOTH) greater than actual length of string?
  --
  v_geom_length := ROUND((case when v_isGeography
                               then ST_Length(ST_GeogFromText(ST_AsEWKT(p_linestring)))
                               else ST_Length(p_linestring)
                           end)::numeric,
                        v_round_xy
                 );

  IF ( (v_reduction_length * CASE v_end WHEN 'BOTH' THEN 2.0 ELSE 1.0 END) >= v_geom_length ) THEN
    Return p_linestring;
  END IF;

  IF ( v_end IN ('START','BOTH') )THEN
    v_pt_id = 0; 
    WHILE (1=1) LOOP
      v_pt_id          := v_pt_id + 1;
      v_end_pt         := ST_PointN(v_linestring,v_pt_id);
      v_internal_pt    := ST_PointN(v_linestring,v_pt_id + 1);
RAISE NOTICE 'START: Internal Point %',ST_AsText(v_internal_pt);
      v_deltaX         := ST_X(v_internal_pt) - ST_X(v_end_pt);
      v_deltaY         := ST_Y(v_internal_pt) - ST_Y(v_end_pt);
      v_segment_length := ROUND((case when v_isGeography 
                                      then ST_Distance(
                                             ST_GeogFromText(ST_AsEWKT(v_end_pt)),
                                             ST_GeogFromText(ST_AsEWKT(v_internal_pt)) 
                                           )
                                      else ST_Distance(v_end_pt,v_internal_pt)
                                  End)::numeric,
                                 v_round_xy
                          );
Raise Notice 'START: delta X/Y %/% -- Length seg/reduce %/%',v_deltaX,v_deltaY,v_segment_length,v_reduction_length;
      IF (ROUND(v_reduction_length::numeric,v_round_xy + 1) >= 
          ROUND(v_segment_length::numeric,  v_round_xy + 1)) THEN
        v_linestring       := ST_RemovePoint(v_linestring, v_pt_id-1 );
        v_reduction_length := v_reduction_length - v_segment_length;
        v_pt_id            := v_pt_id - 1;
      ELSE
        -- To Do: Handle Z and M
        v_new_point  := ST_MakePoint (
                           ROUND((ST_X(v_end_pt) + v_deltaX * (v_reduction_length / v_segment_length))::numeric, v_round_xy),
                           ROUND((ST_Y(v_end_pt) + v_deltaY * (v_reduction_length / v_segment_length))::numeric, v_round_xy),
                           ST_Srid(p_linestring)
                        );
        v_linestring := ST_SetPoint(v_linestring, v_pt_id-1, v_new_point );
        EXIT;
      END IF;
    END LOOP; -- While 
  END IF;   -- IF ( v_end IN ('START','BOTH') ) THEN

  IF ( v_end IN ('BOTH','END') ) THEN
    -- Reduce
    v_reduction_length := ABS(p_reduction_length); -- Reset as could be modified in START/BOTH handler.
    v_pt_id            := ST_NumPoints(v_linestring) + 1;
    WHILE (1=1) LOOP
      v_pt_id          := v_pt_id - 1;
      v_end_pt         := ST_PointN(v_linestring,v_pt_id);
      v_internal_pt    := ST_PointN(v_linestring,v_pt_id - 1);
RAISE NOTICE 'END: Internal Point %',ST_AsText(v_internal_pt);
      v_deltaX         := ST_X(v_internal_pt) - ST_X(v_end_pt);
      v_deltaY         := ST_Y(v_internal_pt) - ST_Y(v_end_pt);
      v_segment_length := ROUND((case when v_isGeography 
                                      then ST_Distance (
                                              ST_GeogFromText(ST_AsEWKT(v_end_pt)),
                                              ST_GeogFromText(ST_AsEWKT(v_internal_pt))
                                           )
                                      else ST_Distance(v_end_pt,v_internal_pt)
                                  End)::numeric,v_round_xy);
Raise Notice 'END: delta X/Y %/% -- Length seg/reduce %/%',v_deltaX,v_deltaY,v_segment_length,v_reduction_length;
      IF ( ROUND(v_reduction_length::numeric,v_round_xy + 1) 
        >= ROUND(v_segment_length::numeric,  v_round_xy + 1) ) THEN
        v_linestring       := ST_RemovePoint(v_linestring, v_pt_id-1 );
        v_reduction_length := v_reduction_length - v_segment_length;
      ELSE
        -- To Do: Handle Z and M
        v_new_point  := ST_MakePoint(
                           ROUND((ST_X(v_end_pt) + v_deltaX * (v_reduction_length / v_segment_length))::numeric, v_round_xy),
                           ROUND((ST_Y(v_end_pt) + v_deltaY * (v_reduction_length / v_segment_length))::numeric, v_round_xy),
                           ST_Srid(p_linestring)
                       );
        v_linestring := ST_SetPoint(v_linestring, ST_NumPoints(v_linestring)-1, v_new_point );
        EXIT;
      END IF;
    END LOOP; -- LOOP
  END IF;   -- IF ( v_end IN ('BOTH','END') )THEN
  Return v_linestring;
END
$BODY$
LANGUAGE plpgsql;

-- Test
--
With data as (
select ST_GeomFromText('LINESTRING (1 1,2 2,3 3,4 4)',0) as linestring
)
select f.reduction_length,
       f.direction,
       cast(ST_AsText(d.linestring) as varchar(100)) as original, 
       cast(case when f.newLinestring is not null then ST_AsText(f.newLinestring) else null end as varchar(100)) as newLinestring,
       ROUND((ST_Length(d.linestring) - ST_Length(f.newLinestring))::numeric,3) as length_Change
from data as d, 
     (select case when hIntValue = 1 then 1.1 else 1.414 end as reduction_length,
            (case when gIntValue = 1 then 'START'
                   when gIntValue = 2 then 'END'
                   when gIntValue = 3 then 'BOTH'
              end)::varchar(5) as direction,
             spdba.ST_Reduce (
                      d.linestring,
                      case when hIntValue = 1 then 1.1 else 1.414 end,
                      (case when gIntValue = 1 then 'START'
                            when gIntValue = 2 then 'END'
                            when gIntValue = 3 then 'BOTH'
                        end)::varchar(5),
                      3,2) as newLinestring 
        from data as d,
             generate_series ( 1, 3, 1 ) as gIntValue,
             generate_series ( 1, 2, 1 ) as hIntValue
      ) as f
  ORDER BY reduction_length;

