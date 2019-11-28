SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
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
  @p_geom geometry
)
RETURNS TABLE
AS
/****f* GEOPROCESSING/STSegmentize (2008)
 *  NAME
 *   STSegmentize - Dumps all vertices of supplied geometry object to SQL rowset
 *  SYNOPSIS
 *   Function [$(owner)].[STSegmentize] (
 *       @p_geometry  geometry 
 *    )
 *    Returns Table
 *  DESCRIPTION
 *    This function segments the supplied geometry into 2-point linestrings or 3 point CircularStrings.
 *    The returned data includes all the metadata about the segmented linestring:
 *    - Segment identifiers (ie from 1 through n);
 *    - Start/Mid/End Coordinates as ordinates;
 *    - Length of vector.
 *    - Geometry representation of segment.
 *  NOTES
 *    - Function supports COMPOUNDCURVES and CIRCULARSTRINGs
 *    - COMPOUNDCURVES are broken in to the component elements, with each processed accordingly
 *    - CIRCULARSTRINGs are broken into individual CIRCULARSTRING sub-elements (vectors).
 *  INPUTS
 *    @p_geometry (geometry) - Any non-point geometry object
 *  RESULT
 *    Table of with following.
 *     id                  (int) - Unique identifier starting at segment 1.
 *     element_id          (int) - Top level element identifier eg 1 for first polygon in multiPolygon.
 *     sub_element_id      (int) - SubElement identifier of subelement of element with parts eg OuterRing of Polygon
 *     vector_id           (int) - Unique identifier for all segments of a specific element.
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
 *     length            (float) - Length of this segment in SRID units
 *     cumulative_length (float) - Length of this segment in SRID units
 *     segment        (geometry) - Geometry representation of segment.
 *  EXAMPLE
 *    SELECT v.* 
 *      FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) ) as v;
 *    GO
 *    id element_id sub_element_id vector_id sx sy     sz   sm   mx my mz   mm   ex ey     ez   em   segment_length   cumulative_length segment
 *    1  1          1              1         0  0      NULL NULL 0  4  NULL NULL 3  6.3246 NULL NULL 8.07248268970323 8.07248268970323  0x....
 *    2  1          1              2         3  6.3246 NULL NULL 5  5  NULL NULL 6  3      NULL NULL 4.68822179023796 12.7607044799412  0x....
 *    3  1          1              3         6  3      NULL NULL 5  0  NULL NULL 0  0      NULL NULL 8.83208735675195 21.5927918366931  0x....
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - November 2019, Complete re-write of original
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
RETURN
WITH geoms AS (
SELECT f.element_id,
       f.geom as geom
  FROM (select gs.IntValue as element_id,
               case when @p_geom.STGeometryType() = 'CompoundCurve'
                    then @p_geom.STCurveN(gs.IntValue)
                    else @p_geom.STGeometryN(gs.IntValue)
                end as geom
          from dbo.Generate_Series(
                     1,
                     case when @p_geom.STGeometryType() = 'CompoundCurve'
                          then @p_geom.STNumCurves()
                          else @p_geom.STNumGeometries()
                      end,
                      1
               ) as gs
       ) as f
 where f.geom.STGeometryType() <> 'Point'
)
SELECT TOP (100) PERCENT
       g.id,
       g.element_id, 
       g.sub_element_id, 
       g.vector_id,
       g.sx,g.sy,g.sz,g.sm,
       g.mx,g.my,g.mz,g.mm,
       g.ex,g.ey,g.ez,g.em,
       g.segment.STLength() as segment_length,
       SUM(g.segment.STLength()) OVER (order by g.id) as cumulative_length,
       g.segment
  FROM (SELECT f.id, f.element_id, f.sub_element_id, f.vector_id,
               sp.STX as sx,sp.STY as sy,sp.Z as sz,sp.M as sm,
               case when mp IS not null then mp.STX else CAST(NULL as float) end as mx,
               case when mp IS not null then mp.STY else CAST(NULL as float) end as my,
               case when mp IS not null then mp.Z   else CAST(NULL as float) end as mz,
               case when mp IS not null then mp.M   else CAST(NULL as float) end as mm,
               ep.STX as ex,ep.STY as ey,ep.Z as ez, ep.M as em,
               case when f.geomType = 'CircularString'
                    then [$(owner)].[STMakeCircularLine](sp,mp,ep,15,15,15)
                    else geometry::STGeomFromText('LINESTRING(' +
                            FORMAT(sp.STX,'#######################0.#########################') + ' ' +
                            FORMAT(sp.STY,'#######################0.#########################') + 
                            case when sp.HasZ=1 then ' ' + case when sp.Z is not null then FORMAT(sp.Z,'#######################0.#########################') else 'NULL' end 
                                 else case when sp.HasZ=1 then ' NULL' else '' end 
                             end +
                            case when sp.HasM=1 then ' ' + case when sp.M is not null then FORMAT(sp.M,'#######################0.' + LEFT( '#########################',15)) else 'NULL' end 
                                 else '' end +
                            ',' +
                            FORMAT(ep.STX,'#######################0.#########################') + ' ' +
                            FORMAT(ep.STY,'#######################0.#########################') + 
                            case when ep.HasZ=1 then ' ' + case when ep.Z is not null then FORMAT(ep.Z,'#######################0.#########################') else 'NULL' end 
                                 else case when ep.HasZ=1 then ' NULL' else '' end 
                             end +
                            case when ep.HasM=1 then ' ' + case when ep.M is not null then FORMAT(ep.M,'#######################0.#########################') else 'NULL' end 
                                 else '' 
                             end +
                            ')',sp.STSrid) 
                end as segment
          FROM (SELECT row_number() over (order by b.element_id, b.sub_element_id, b.id) as id,
                       b.element_id,
                       b.sub_element_id,
                       b.vector_id,
                       b.geomType,
                       b.sp, b.mp, b.ep
                    FROM (SELECT gs.IntValue as id, 
                                 a.element_id, 
                                 1 as sub_element_id, 
                                 gs.IntValue as vector_id, 
                                 a.geom.STGeometryType()        as geomType,
                                 a.geom.STPointN(gs.IntValue)   as sp,
                                 CAST(NULL AS geometry)         as mp,
                                 a.geom.STPointN(gs.IntValue+1) as ep
                            FROM geoms as a
                                 cross apply
                                 dbo.generate_series(1,a.geom.STNumPoints()-1,1) as gs
                           WHERE a.geom.STGeometryType() = 'LineString'
                           UNION ALL
                          SELECT row_number() over (order by StringN.IntValue) as id, 
                                 b.element_id, 
                                 1                       as sub_element_id, 
                                 StringN.IntValue        as vector_id, 
                                 b.geom.STGeometryType() as geomType,
                                 [$(owner)].[STCircularStringN](b.geom,StringN.IntValue).STPointN(1) as sp, 
                                 [$(owner)].[STCircularStringN](b.geom,StringN.IntValue).STPointN(2) as mp, 
                                 [$(owner)].[STCircularStringN](b.geom,StringN.IntValue).STPointN(3) as ep 
                            FROM geoms as b
                                 CROSS APPLY
                                 generate_series(1,[$(owner)].STNumCircularStrings(b.geom),1) as StringN
                           WHERE b.geom.STGeometryType() = 'CircularString'
                           UNION ALL
                          SELECT gs.IntValue as id, 
                                 a.element_id, 
                                 a.sub_element_id, 
                                 gs.IntValue as vector_id, 
                                 a.geom.STGeometryType()        as geomType, 
                                 a.geom.STPointN(gs.IntValue)   as sp, 
                                 CAST(NULL AS geometry)         as mp,
                                 a.geom.STPointN(gs.IntValue+1) as ep
                            FROM (SELECT 1 as id, 
                                         a.element_id, 
                                         1 as sub_element_id,
                                         a.geom.STExteriorRing() as geom 
                                    FROM geoms as a
                                   WHERE a.geom.STGeometryType() = 'Polygon'
                                   UNION ALL
                                  SELECT ir.IntValue as id, 
                                         a.element_id, 
                                         ir.IntValue+1 as sub_element_id,
                                         a.geom.STInteriorRingN(ir.IntValue) as geom
                                    FROM geoms as a 
                                         cross apply 
                                         dbo.generate_series(1,a.geom.STNumInteriorRing(),1) as ir
                                    WHERE a.geom.STGeometryType() = 'Polygon'
                                 ) as a
                                 CROSS APPLY
                                 dbo.generate_series(1,a.geom.STNumPoints()-1,1) as gs
                         ) as b
                ) as f
          ) as g
  ORDER BY g.id,g.element_id, g.sub_element_id, g.vector_id;
GO

