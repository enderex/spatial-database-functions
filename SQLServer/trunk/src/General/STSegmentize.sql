SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner(dbo)';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STSegmentize]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STSegmentize];
  PRINT 'Dropped [$(owner)].[STSegmentize] ...';
END;
GO

PRINT 'Creating [$(owner)].[STSegmentize] ...';
GO

-- Needs work for recursive geometries such as CIRCULAR string within GEOMETRYCOLLECTION
CREATE FUNCTION [$(owner)].[STSegmentize](
  @p_geometry     geometry,
  @p_filter       varchar(20), -- ALL, X, Y, Z, CLOSEST, FURTHEST, ID, LENGTH, MEASURE, LENGTH_RANGE, MEASURE_RANGE or Z_RANGE.';
  @p_point        geometry,
  @p_filter_value float,
  @p_start_value  float,
  @p_end_value    float,
  @p_round_xy     integer,
  @p_round_z      integer,
  @p_round_m      integer
)
RETURNS @Segments TABLE
(
  id                 int,
  min_id             int,
  max_id             int,
  hierarchy          varchar(max),
  geometry_type      varchar(100),
  element_id         int,
  subelement_id      int,
  segment_id         int, 
  sx                 float,  /* Start Point */
  sy                 float,
  sz                 float,
  sm                 float,
  mx                 float,  /* Mid Point */
  my                 float,
  mz                 float,
  mm                 float,
  ex                 float,  /* End Point */
  ey                 float,
  ez                 float,
  em                 float,
  measure_range      float,
  z_range            float,
  cumulative_measure float,
  segment_length     float,
  start_length       float,
  cumulative_length  float,
  closest_distance   float,
  min_distance       float,
  max_distance       float,
  prev_segment       geometry,
  segment            geometry,
  next_segment       geometry
)
AS
/****f* GEOPROCESSING/STSegmentize (2008)
 *  NAME
 *   STSegmentize - Dumps all segments of supplied geometry object to SQL rowset with optional filtering
 *  SYNOPSIS
 *   Function [$(owner)].[STSegmentize] (
 *      @p_geometry     geometry,
 *      @p_filter    varchar(20), -- ALL, X, Y, Z, CLOSEST, FURTHEST, ID, LENGTH, MEASURE, LENGTH_RANGE, MEASURE_RANGE, or Z_RANGE.';
 *      @p_point        geometry,
 *      @p_filter_value    float,
 *      @p_start_value     float,
 *      @p_end_value       float                              
 *    )
 *    Returns Table
 *  DESCRIPTION
 *    This function segments the supplied geometry into 2-point linestrings or 3 point CircularStrings.
 *    The returned data includes all the metadata about the segmented linestring:
 *    - Segment identifiers (ie from 1 through n);
 *    - Start/Mid/End Coordinates as ordinates;
 *    - Length of segment.
 *    - Geometry representation of segment.
 *    The function can also filter the (@p_filter) generated segments as follows:
 *      - MISSPELL/NULL/ALL -- The default ie returns all segments unfiltered, 
 *      -                 X -- Returns segments whose X range (min/max) contains the supplied value, 
 *      -                 Y -- Returns segments whose Y range (min/max) contains the supplied value, 
 *      -                 Z -- Returns segments whose Z range (min/max) contains the supplied value, 
 *      -           CLOSEST -- Returns segment(s) closest to supplied @p_point
 *      -          FURTHEST -- Returns segment(s) furtherest away from supplied @p_point
 *      -                ID -- Returns segment with nominated ID (segment from start)
 *      -            LENGTH -- Returns segment whose length straddles the supplied value (starting from 0)
 *      -           MEASURE -- Returns segment whose m range (sm/em) straddles the supplied value
 *      -      LENGTH_RANGE -- Returns segments that cover the supplied @p_start_value/@p_end_value length values
 *      -     MEASURE_RANGE -- Returns segments that cover the supplied @p_start_value/@p_end_value measure values
 *      -           Z_RANGE -- Returns segments that cover the supplied @p_start_value/@p_end_value Z values
 *  NOTES
 *    - Function supports COMPOUNDCURVES and CIRCULARSTRINGs
 *    - COMPOUNDCURVES are broken in to the component elements, with each processed accordingly
 *    - CIRCULARSTRINGs are broken into individual CIRCULARSTRING sub-elements (segments).
 *    - If measure of supplied linestring is descending, the @p_start_value/@p_end_values must also be decreasing.
 *  INPUTS
 *    @p_geometry (geometry) -- Any non-point geometry object
 *    @p_filter  varchar(20) -- ALL, X, Y, CLOSEST, FURTHEST, ID, LENGTH, MEASURE, LENGTH_RANGE, or MEASURE_RANGE.
 *    @p_point      geometry -- Point for use with CLOSEST/FURTHEST
 *    @p_filter_value  float -- For X, Y, CLOSEST, FURTHEST, ID (CAST TO integer), LENGTH, MEASURE
 *    @p_start_value   float -- Min range value for use with LENGTH_RANGE, or MEASURE_RANGE.
 *    @p_end_value     float -- Max range value for use with LENGTH_RANGE, or MEASURE_RANGE.
 *  RESULT
 *    SQL Select statement with the following.
 *     id                  (int) - Unique identifier starting at segment 1.
 *     max_id              (int) - Id of last segment.
 *     hierarchy  (varchar(max)) - Hierarchically organised STGeometryTypes from start of @p_geometry
 *     element_id          (int) - Top level element identifier eg 1 for first polygon in multiPolygon.
 *     sub_element_id      (int) - SubElement identifier of subelement of element with parts eg OuterRing of Polygon
 *     segment_id          (int) - Unique identifier for all segments of a specific element.
 *     sx                (float) - Start Point X Ordinate 
 *     sy                (float) - Start Point Y Ordinate 
 *     sz                (float) - Start Point Z Ordinate 
 *     sm                (float) - Start Point M Ordinate
 *     mx                (float) - Mid Point X Ordinate (Only if CircularString)
 *     my                (float) - Mid Point Y Ordinate (Only if CircularString)
 *     mz                (float) - Mid Point Z Ordinate (Only if CircularString)
 *     mm                (float) - Mid Point M Ordinate (Only if CircularString)
 *     ex                (float) - End Point X Ordinate 
 *     ey                (float) - End Point Y Ordinate 
 *     ez                (float) - End Point Z Ordinate 
 *     em                (float) - End Point M Ordinate 
 *     measure_range     (float) - Measure range for each segment (if -ve descending measures)
 *     z_range           (float) - Z range for each segment (if -ve descending measures)
 *     cumulative_measure(float) - Cumulative measure (could descend or ascend in value)
 *     segment_length    (float) - Length of this segment in SRID units
 *     start_length      (float) - Length at start vertex of segment
 *     cumulative_length (float) - Sum Length from start of @p_geometry
 *     closest_distance  (float) - Distance from supplied @p_point to segment
 *     min_distance      (float) - Distance from supplied @p_point to closest segment
 *     max_distance      (float) - Distance from supplied @p_point to furthest segment
 *     segment        (geometry) - Geometry representation of segment.
 *     next_segment   (geometry) - Segment following on from current (ie id 2 when id 1)
 *  EXAMPLE
 *    SELECT v.* 
 *      FROM [$(owner)].[STSegmentize] ( 
 *              geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0),
 *              'ALL',
 *              NULL,
 *              NULL,
 *              NULL,
 *              NULL
 * 
 *           ) as v;
 *    GO
 *    id element_id sub_element_id segment_id sx sy     sz   sm   mx my mz   mm   ex ey     ez   em   segment_length   cumulative_length segment
 *    1  1          1              1           0  0      NULL NULL 0  4  NULL NULL 3  6.3246 NULL NULL 8.07248268970323 8.07248268970323  0x....
 *    2  1          1              2           3  6.3246 NULL NULL 5  5  NULL NULL 6  3      NULL NULL 4.68822179023796 12.7607044799412  0x....
 *    3  1          1              3           6  3      NULL NULL 5  0  NULL NULL 0  0      NULL NULL 8.83208735675195 21.5927918366931  0x....
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - November 2019, Complete re-write of original
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
WITH cteExtract (element_id,sub_element_id,hierarchy,geom) AS (
--********** Start Block ****************
select f.element_id,
       f.sub_element_id,
       @p_geometry.STGeometryType() + '>' + 
       case when sub_type = f.geom.STGeometryType() 
            then sub_type
            else sub_type + '>' + f.geom.STGeometryType() 
        end as hierarchy,
        f.geom
  from (select b.element_id,
               CAST(gs.IntValue as float) as sub_element_id,
               b.geom.STGeometryType() as sub_type,
               (case when b.geom.STGeometryType() = 'CompoundCurve'
                     then b.geom.STCurveN(gs.IntValue)
                     else b.geom.STGeometryN(gs.IntValue)
                 end) as geom
          from (select geomN.IntValue as element_id,
                       @p_geometry.STGeometryN(geomN.IntValue) as geom
                  from dbo.Generate_Series(1,@p_geometry.STNumGeometries(),1) as geomN
               ) as b
               cross apply
               dbo.Generate_Series(
                    1,
                    case when b.geom.STGeometryType() = 'CompoundCurve'
                         then b.geom.STNumCurves()
                         else b.geom.STNumGeometries()
                     end,
                    1
               ) as gs
        ) as f
    UNION ALL
--********* Recursive Block **************      
SELECT f.element_id, 
       f.sub_element_id, 
       f.hierarchy + 
           case when f.oGeom.STGeometryType() = f.geom.STGeometryType() 
                then '' 
                else '>' + f.geom.STGeometryType() 
            end as hierarchy,
       f.geom
  FROM (select a.geom as ogeom,
               a.element_id,
               a.element_id + (b.sub_element_id/10.0) as sub_element_id, 
               a.hierarchy,
               b.geom
          from cteExtract as a
               cross apply
               (SELECT a.sub_element_id, 
                       a.geom 
                 WHERE a.geom.STGeometryType() NOT IN ('CurvePolygon','CompoundCurve')
                 UNION ALL 
                SELECT gs.IntValue as sub_element_id, 
                       a.geom.STCurveN(gs.IntValue) as geom
                  FROM dbo.Generate_Series(1,a.geom.STNumCurves(),1) as gs
                 WHERE a.geom.STGeometryType() = 'CompoundCurve'
                 UNION ALL
                SELECT sub_element_id,
                       ring
                  FROM (SELECT 1 as sub_element_id, 
                               a.geom.STExteriorRing() as ring
                         WHERE a.geom.STGeometryType()  = 'CurvePolygon'
                         UNION ALL
                        SELECT ir.IntValue+1 as sub_element_id, 
                               a.geom.STInteriorRingN(ir.IntValue) as ring
                          FROM [$(owner)].[generate_series](1,a.geom.STNumInteriorRing(),1) as ir
                         WHERE a.geom.STGeometryType()  = 'CurvePolygon'
                       ) as cp
               ) as b
       ) as f
  WHERE f.oGeom.STEquals(f.geom) = 0
)
INSERT INTO @Segments (
  id,
  min_id,
  max_id,
  hierarchy,
  geometry_type,
  element_id,
  subelement_id,
  segment_id, 
  sx,
  sy,
  sz,
  sm,
  mx,
  my,
  mz,
  mm,
  ex,
  ey,
  ez,
  em,
  measure_range,
  z_range,
  cumulative_measure,
  segment_length,
  start_length,
  cumulative_length,
  closest_distance,
  min_distance,
  max_distance,
  prev_segment,
  segment,
  next_segment
)
SELECT TOP (100) PERCENT
       h.id,
       MIN(h.id) over (order by (select 1)) as min_id,
       MAX(h.id) over (order by (select 1)) as max_id,
       h.hierarchy,
       h.segment.STGeometryType() as geometry_type,
       h.element_id, 
       h.sub_element_id, 
       h.segment_id,
       h.sx,h.sy,h.sz,h.sm,
       h.mx,h.my,h.mz,h.mm,
       h.ex,h.ey,h.ez,h.em,
       h.measure_range,
       h.z_range,
       h.cumulative_measure,
       h.segment_length,
       (h.cumulative_length - h.segment_length) as start_length,
       h.cumulative_length,
       h.closest_distance,
       h.min_distance,
       h.max_distance,
       h.prev_segment,
       h.segment,
       h.next_segment
  FROM (SELECT row_number() over (order by g.element_id, g.sub_element_id, g.segment_id) as id,
               g.hierarchy,
               g.element_id, 
               ROUND(g.sub_element_id,1) as sub_element_id, 
               g.segment_id,
               g.sx,g.sy,g.sz,g.sm,
               g.mx,g.my,g.mz,g.mm,
               g.ex,g.ey,g.ez,g.em,
               g.em - g.sm as measure_range,
               g.ez - g.sz as z_range,
               CAST(CASE WHEN @p_point is not null then g.segment.STDistance(@p_point) else NULL end as float) as closest_distance,
               --SUM(g.em) OVER (order by g.element_id, g.sub_element_id, g.segment_id)                 as cumulative_measure,
			   case when (g.em-g.sm) > 0 
			        then SUM(g.em) OVER (order by  g.element_id, g.sub_element_id, g.segment_id)
					else FIRST_VALUE(g.sm) OVER(ORDER BY  g.element_id, g.sub_element_id, g.segment_id)  +
                                 SUM(g.em-g.sm) OVER (order BY g.element_id, g.sub_element_id, g.segment_id) 
                end as cumulative_measure,
               SUM(g.segment.STLength()) OVER (order by g.element_id, g.sub_element_id, g.segment_id) as cumulative_length,
               MIN(g.segment.STDistance(@p_point)) over (order by (select 1)) as min_distance,
               MAX(g.segment.STDistance(@p_point)) over (order by (select 1)) as max_distance,
               g.segment.STLength() as segment_length,
               LAG(g.segment,1) OVER (order by g.element_id, g.sub_element_id, g.segment_id) as prev_segment,
               g.segment,
               LEAD(g.segment,1) OVER (order by g.element_id, g.sub_element_id, g.segment_id) as next_segment
          FROM (SELECT f.element_id, f.sub_element_id, f.segment_id,
                       sp.STX as sx,sp.STY as sy,sp.Z as sz,sp.M as sm,
                       case when mp IS not null then mp.STX else CAST(NULL as float) end as mx,
                       case when mp IS not null then mp.STY else CAST(NULL as float) end as my,
                       case when mp IS not null then mp.Z   else CAST(NULL as float) end as mz,
                       case when mp IS not null then mp.M   else CAST(NULL as float) end as mm,
                       ep.STX as ex,ep.STY as ey,ep.Z as ez, ep.M as em,
                       f.hierarchy,
                       case when f.hierarchy like '%CircularString' OR mp.STX IS not null
                            then [$(owner)].[STMakeCircularLine](sp,mp,ep,15,15,15)
                            else geometry::STGeomFromText(
                                  'LINESTRING(' +
                                    FORMAT(sp.STX,'#######################0.#########################') + ' ' +
                                    FORMAT(sp.STY,'#######################0.#########################') + 
                                    case when CHARINDEX('Z',f.dimensions) > 0
                                         then ' ' + 
                                              case when sp.Z is not null
                                                   then FORMAT(sp.Z,'#######################0.#########################')
                                                   else 'NULL'
                                               end
                                         else case when CHARINDEX('M',f.dimensions) > 0 then ' NULL' else '' end
                                     end + 
                                    case when CHARINDEX('M',f.dimensions) > 0
                                         then ' ' + 
                                              case when sp.M is not null 
                                                   then FORMAT(sp.M,'#######################0.#########################')
                                                   else 'NULL'
                                                end
                                         else '' 
                                     end
                                     + ',' +
                                    FORMAT(ep.STX,'#######################0.#########################') + ' ' +
                                    FORMAT(ep.STY,'#######################0.#########################') + 
                                    case when CHARINDEX('Z',f.dimensions) > 0
                                         then ' ' + 
                                              case when ep.Z is not null
                                                   then FORMAT(ep.Z,'#######################0.#########################')
                                                   else 'NULL'
                                               end
                                         else case when CHARINDEX('M',f.dimensions) > 0 then ' NULL' else '' end
                                     end + 
                                    case when CHARINDEX('M',f.dimensions) > 0
                                         then ' ' + 
                                              case when ep.M is not null 
                                                   then FORMAT(ep.M,'#######################0.#########################')
                                                   else 'NULL'
                                                end
                                         else '' 
                                     end  +
                                  ')',sp.STSrid) 
                        end as segment
                  FROM (SELECT b.element_id,
                               b.sub_element_id,
                               b.segment_id,
                               b.hierarchy,
                               'XY' + case when b.sp.HasZ=1 then 'Z' else '' end + case when b.sp.HasM=1 then 'M' else '' end as dimensions,
                               b.sp, b.mp, b.ep
                            FROM (SELECT a.element_id, 
                                         a.sub_element_id, 
                                         gs.IntValue as segment_id, 
                                         a.hierarchy,
                                         a.geom.STPointN(gs.IntValue)   as sp,
                                         CAST(NULL AS geometry)         as mp,
                                         a.geom.STPointN(gs.IntValue+1) as ep
                                    FROM cteExtract as a
                                         cross apply
                                         dbo.generate_series(1,a.geom.STNumPoints()-1,1) as gs
                                   WHERE a.geom.STGeometryType() = 'LineString'
                                   UNION ALL
                                  SELECT c.element_id, 
                                         c.sub_element_id, 
                                         c.segment_id, 
                                         c.hierarchy,
                                         c.circular_arc.STPointN(1) as sp, 
                                         c.circular_arc.STPointN(2) as mp, 
                                         c.circular_arc.STPointN(3) as ep 
                                    FROM (SELECT b.element_id, 
                                                 b.sub_element_id, 
                                                 StringN.IntValue        as segment_id, 
                                                 b.hierarchy,
                                                 [$(owner)].[STCircularStringN](b.geom,StringN.IntValue) as circular_arc
                                            FROM cteExtract as b
                                                 CROSS APPLY
                                                 generate_series(1,[$(owner)].STNumCircularStrings(b.geom),1) as StringN
                                           WHERE b.geom.STGeometryType() = 'CircularString'
                                         ) as c
                                   UNION ALL
                                  SELECT a.element_id, 
                                         a.sub_element_id, 
                                         gs.IntValue as segment_id, 
                                         a.hierarchy, 
                                         a.geom.STPointN(gs.IntValue)   as sp, 
                                         CAST(NULL AS geometry)         as mp,
                                         a.geom.STPointN(gs.IntValue+1) as ep
                                    FROM (SELECT a.element_id, 
                                                 a.sub_element_id + 0.01 as sub_element_id,
                                                 a.hierarchy + '>ExteriorRing' as hierarchy,
                                                 a.geom.STExteriorRing() as geom 
                                            FROM cteExtract as a
                                           WHERE a.geom.STGeometryType() = 'Polygon'
                                           UNION ALL
                                          SELECT a.element_id, 
                                                 a.sub_element_id + (ir.IntValue+1 / 10.0) as sub_element_id,
                                                 a.hierarchy + '>InteriorRing' as hierarchy,
                                                 a.geom.STInteriorRingN(ir.IntValue) as geom
                                            FROM cteExtract as a 
                                                 cross apply 
                                                 dbo.generate_series(1,a.geom.STNumInteriorRing(),1) as ir
                                            WHERE a.geom.STGeometryType() = 'Polygon'
                                         ) as a
                                         CROSS APPLY
                                         dbo.generate_series(1,a.geom.STNumPoints()-1,1) as gs
                                 ) as b
                       ) as f
               ) as g
       ) as h
 WHERE (UPPER(@p_filter) = 'ALL')
    OR (UPPER(@p_filter) = 'ID'            AND @p_filter_value is not null AND h.id = CAST(@p_filter_value as integer))
    OR (UPPER(@p_filter) = 'CLOSEST'       AND @p_point is not null AND h.closest_distance = h.min_distance)
    OR (UPPER(@p_filter) = 'FURTHEST'      AND @p_point is not null AND h.closest_distance = h.max_distance)
    OR (UPPER(@p_filter) = 'X'       AND 
        @p_filter_value is not null  AND
        ROUND(@p_filter_value,@p_round_xy) between ROUND(h.sx,@p_round_xy) AND ROUND(h.ex,@p_round_xy)
       )
    OR (UPPER(@p_filter) = 'Y'       AND 
        @p_filter_value is not null  AND
        ROUND(@p_filter_value,@p_round_xy) between ROUND(h.sy,@p_round_xy) AND ROUND(h.ey,@p_round_xy)
       )
    OR (UPPER(@p_filter) = 'Z'       AND 
        @p_filter_value is not null  AND
       (ROUND(@p_filter_value,@p_round_z) between ROUND(h.sz,@p_round_z) AND ROUND(h.ez,@p_round_z)
        OR 
        ROUND(@p_filter_value,@p_round_z) between ROUND(h.ez,@p_round_z) AND ROUND(h.sz,@p_round_z)
       )
       )
    OR (UPPER(@p_filter) = 'Z_RANGE' AND 
        @p_start_value is not null AND 
        @p_end_value   is not null AND 
        ( ROUND(h.ez - h.sz,@p_round_z) < 0 and ROUND(@p_start_value,@p_round_z) between ROUND(h.ez,@p_round_z) and ROUND(h.sz,@p_round_z)
          OR
          ROUND(h.ez - h.sz,@p_round_z) > 0 and ROUND(@p_start_value,@p_round_z) between ROUND(h.sz,@p_round_z) and ROUND(h.ez,@p_round_z)
          OR
          ROUND(h.ez - h.sz,@p_round_z) < 0 and ROUND(@p_end_value,@p_round_z) between ROUND(h.ez,@p_round_z) and ROUND(h.sz,@p_round_z)
          OR
          ROUND(h.ez - h.sz,@p_round_z) > 0 and ROUND(@p_end_value,@p_round_z) between ROUND(h.sz,@p_round_z) and ROUND(h.ez,@p_round_z)
        )
       )
    OR (UPPER(@p_filter) = 'LENGTH'        AND 
        @p_filter_value is not null AND
        ROUND(@p_filter_value,@p_round_xy) between ROUND(h.cumulative_length - h.segment_length,@p_round_xy) and ROUND(h.cumulative_length,@p_round_xy)
       )
    OR (UPPER(@p_filter) = 'LENGTH_RANGE' AND 
        @p_start_value is not null AND 
        @p_end_value   is not null AND 
        -- Greatest((h.cumulative_length - h.segment_length),@p_start_value)
        case when ROUND(h.cumulative_length - h.segment_length,@p_round_xy) < ROUND(@p_start_value,@p_round_xy) then ROUND(@p_start_value,@p_round_xy) else ROUND(h.cumulative_length - h.segment_length,@p_round_xy) end 
        < 
        -- Least((h.cumulative_length - h.segment_length),@p_end_value)
        case when ROUND(h.cumulative_length,@p_round_xy) < ROUND(@p_end_value,@p_round_xy) then ROUND(h.cumulative_length,@p_round_xy) else ROUND(@p_end_value,@p_round_xy) end
       )
    OR (UPPER(@p_filter) = 'MEASURE' AND 
        @p_filter_value is not null  AND
        ( ( h.measure_range >= 0.0 AND ROUND(@p_filter_value,@p_round_m) between ROUND(h.sm,@p_round_m) and ROUND(h.em,@p_round_m))
            OR
          ( h.measure_range  < 0.0 AND ROUND(@p_filter_value,@p_round_m) between ROUND(h.em,@p_round_m) and ROUND(h.sm,@p_round_m) )
        )
       )
    OR (UPPER(@p_filter) = 'MEASURE_RANGE' AND 
        @p_start_value is not null AND 
        @p_end_value   is not null AND 
		( 
          (
            -- If range increasing then ==> Greatest(h.sm,@p_start_value) < Least(h.em,@p_end_value)
		    h.measure_range > 0 AND
            case when ROUND(h.sm,@p_round_m) < ROUND(@p_start_value,@p_round_m) then ROUND(@p_start_value,@p_round_m) else ROUND(h.sm,@p_round_m) end 
            < 
            case when ROUND(h.em,@p_round_m) < ROUND(@p_end_value,@p_round_m) then ROUND(h.em,@p_round_m) else ROUND(@p_end_value,@p_round_m) end
          )
		) OR (
          (
            -- If range decreasing then ==> Greatest(h.em,@p_end_value) < Least(h.sm,@p_start_value)
		    h.measure_range < 0 AND
            case when ROUND(h.em,@p_round_m) < ROUND(@p_end_value,@p_round_m) then ROUND(@p_end_value,@p_round_m) else ROUND(h.em,@p_round_m) end 
            < 
            case when ROUND(h.sm,@p_round_m) < ROUND(@p_start_value,@p_round_m) then ROUND(h.sm,@p_round_m) else ROUND(@p_start_value,@p_round_m) end
		  )
        )
       )
  ORDER BY h.element_id, h.sub_element_id, h.segment_id;
  RETURN;
END;
GO
