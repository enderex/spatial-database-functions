USE [$(usedbname)]
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[dbo].[STSegmentize]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [dbo].[STSegmentize];
  PRINT 'Dropped [dbo].[STSegmentize] ...';
END;
GO

PRINT 'Creating [dbo].[STSegmentize] ...';
GO

-- Needs work for recursive geometries such as CIRCULAR string within GEOMETRYCOLLECTION
CREATE FUNCTION [dbo].[STSegmentize](@p_geom geometry)
RETURNS TABLE
AS
-- In Line Table Valued Function
RETURN
WITH geoms AS (
SELECT row_number() over (order by f.geomN) as geomn,
       @p_geom.STGeometryType() as mainType,
       f.geom as geom
  FROM (select gs.IntValue as geomN,
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
       g.id,g.element_id, g.sub_element_id, g.vector_id,
       sx,sy,sz,sm,
       mx,my,mz,mm,
       ex,ey,ez,em,
       g.segment, 
       SUM(g.segment.STLength()) OVER (order by g.id) as cumulative_length,
       g.segment.STLength() as length
  FROM (SELECT f.id, f.element_id, f.sub_element_id, f.vector_id,
               sp.STX as sx,sp.STY as sy,sp.Z as sz,sp.M as sm,
               case when mp IS not null then mp.STX else CAST(NULL as float) end as mx,
               case when mp IS not null then mp.STY else CAST(NULL as float) end as my,
               case when mp IS not null then mp.Z   else CAST(NULL as float) end as mz,
               case when mp IS not null then mp.M   else CAST(NULL as float) end as mm,
               ep.STX as ex,ep.STY as ey,ep.Z as ez, ep.M as em,
               geometry::STGeomFromText('LINESTRING(' +
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
               as segment
          FROM (SELECT row_number() over (order by b.element_id, b.sub_element_id, b.id) as id,
                       b.element_id,
                       b.sub_element_id,
                       row_number() over (order by b.element_id, b.sub_element_id)  as vector_id,
                       b.sp, b.mp, b.ep
                    FROM (SELECT gs.IntValue as id, 
                                 case when a.mainType = 'CompoundCurve' then 1 else a.geomn end as element_id, 
                                 a.geomN as sub_element_id, 
                                 gs.IntValue as vector_id, 
                                 a.geom.STPointN(gs.IntValue)   as sp,
                                 CAST(NULL AS geometry)         as mp,
                                 a.geom.STPointN(gs.IntValue+1) as ep
                            FROM geoms as a
                                 cross apply
                                 dbo.generate_series(1,a.geom.STNumPoints()-1,1) as gs
                           WHERE a.geom.STGeometryType() = 'LineString'
                           UNION ALL
                          SELECT row_number() over (order by b.geomn) as id, 
                                 case when b.mainType = 'CompoundCurve' then 1 else b.geomn end as element_id, 
                                 b.geomN as sub_element_id, 
                                 b.geomN as vector_id, 
                                 b.geom.STPointN(1) as sp, 
                                 b.geom.STPointN(2) as mp,
                                 b.geom.STPointN(3) as ep
                            FROM geoms as b
                           WHERE b.geom.STGeometryType() = 'CircularString'
                           UNION ALL
                          SELECT gs.IntValue as id, a.geomn as element_id, a.id as sub_element_id, gs.IntValue as vector_id, 
                                 a.geom.STPointN(gs.IntValue)   as sp, 
                                 CAST(NULL AS geometry)         as mp,
                                 a.geom.STPointN(gs.IntValue+1) as ep
                            FROM (SELECT 1 as id, a.geomn, a.geom.STExteriorRing() as geom 
                                    FROM geoms as a
                                   WHERE a.geom.STGeometryType() = 'Polygon'
                                   UNION ALL
                                  SELECT ir.IntValue as id, a.geomn, a.geom.STInteriorRingN(ir.IntValue) as geom
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

PRINT 'Testing [dbo].[STSegmentize] ...';
GO

-- NOT SUPPORTED DECLARE @p_geom geometry = geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326454.7 5455793.7 1,326621.3 5455813.7 2,326455.4 5455796.6 3,326454.7 5455793.7 4)))',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2, 3 3)',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('LINESTRING(0 1 2 2.1, 2 3 2.1 3.4, 4 5 2.3 5.4, 6 7 2.2 6.7)',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('POLYGON((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7))',28356);
--DECLARE @p_geom geometry = geometry::STGeomFromText('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('CIRCULARSTRING(0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0)',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5, 10 -10,15 -15)',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('COMPOUNDCURVE((3 5, 3 3), CIRCULARSTRING(3 3, 5 1, 7 3), (7 3, 7 5), CIRCULARSTRING(7 5, 5 7, 3 5))',0);
--DECLARE @p_geom geometry = geometry::STGeomFromText('COMPOUNDCURVE ((4 4, 3 3, 2 2, 0 0),CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0))',0);

/*
-- STSegmentize wrapper
select  v.*
  from [dbo].[STSegmentize](
  geometry::STGeomFromText(
         'GEOMETRYCOLLECTION(
                  LINESTRING(0 0,20 0,20 20,0 20,0 0), 
                  CURVEPOLYGON(
                       COMPOUNDCURVE(
                               (0 -23.43778, 0 23.43778),
                               CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
                               (-90 23.43778, -90 -23.43778),
                               CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), 
                  COMPOUNDCURVE(
                          CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), 
                          (0 -23.43778, 0 23.43778)))',0)
         ) as v;
GO

with data as (
  select geometry::STGeomFromText(
         'GEOMETRYCOLLECTION(
                  LINESTRING(0 0,20 0,20 20,0 20,0 0), 
                  CURVEPOLYGON(
                       COMPOUNDCURVE(
                               (0 -23.43778, 0 23.43778),
                               CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
                               (-90 23.43778, -90 -23.43778),
                               CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), 
                  COMPOUNDCURVE(
                          CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), 
                          (0 -23.43778, 0 23.43778)))',0) as p_geom
)
SELECT row_number() over (order by f.geomN) as geomn,
       (case when f.geom.STGeometryType() = 'CompoundCurve'
            then f.geom.STCurveN(gs2.IntValue)
            else f.geom.STGeometryN(gs2.IntValue)
        end).STAsText() as geom
  FROM (select gs.IntValue as geomN,
               case when p_geom.STGeometryType() = 'CompoundCurve'
                    then p_geom.STCurveN(gs.IntValue)
                    else p_geom.STGeometryN(gs.IntValue)
                end as geom
          from data as d
               cross apply
               dbo.Generate_Series(
                     1,
                     case when p_geom.STGeometryType() = 'CompoundCurve'
                          then p_geom.STNumCurves()
                          else p_geom.STNumGeometries()
                      end,
                      1
               ) as gs
       ) as f
       cross apply
       dbo.Generate_Series(
                     1,
                     case when f.geom.STGeometryType() = 'CompoundCurve'
                          then f.geom.STNumCurves()
                          else f.geom.STNumGeometries()
                      end,
                      1
               ) as gs2
 where f.geom.STGeometryType() <> 'Point'
GO

*/
