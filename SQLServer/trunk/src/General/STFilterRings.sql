SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(owner)].[STFilterRings]') AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STFilterRings];
  PRINT 'Dropped [$(owner)].[STFilterRings] ...';
END;
Go

PRINT 'Creating [$(owner)].[STFilterRings] ...';
Go

CREATE FUNCTION [$(owner)].[STFilterRings]
(
  @p_geometry geometry,
  @p_area     Float
)
Returns geometry
As
/****f* GEOPROCESSING/STFilterRings (2008)
 *  NAME
 *    STFilterRings -- Removes rings from polygon/multipolygon below supplied area.
 *  SYNOPSIS
 *    Function [$(owner)].[STFilterRings] (
 *               @p_geometry geometry,
 *               @p_area     float
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    This function allows a user to remove the inner rings of a polygon/multipolygon based on an area value.
 *    Will remove both outer and inner rings.
 *  INPUTS
 *    @p_geometry (geometry) - Polygon or Multipolygon geometry object.
 *    @p_area        (float) - Area in square SRID units below which an inner ring is removed.
 *  EXAMPLE
 *    SELECT [$(owner)].[STFilterRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),2).AsTextZM() as geom
 *    GO
 *    geom
 *    ------------------------------------------------------------------
 *    POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0), (5 5, 5 7, 7 7, 7 5, 5 5))
 *  RESULT
 *    (multi)polygon (geometry) -- Input geometry with rings possibly filtered out.
 *  NOTES
 *    Depends on STExtract function.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding.
 *    Simon Greener - Jan 2015 - Port to TSQL SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
     @v_filtered_geom geometry;
  Begin
    If ( @p_geometry is NULL ) 
      return null;
    IF ( @p_geometry.STGeometryType() NOT IN ('CurvePolygon','Polygon','MultiPolygon') )
      return @p_geometry;
    SELECT @v_filtered_geom = a.outer_rings.STDifference(f.inner_rings)
      FROM (SELECT geometry::UnionAggregate(e.geom) as outer_rings 
              FROM [$(owner)].[STExtract](@p_geometry,1) as e
             WHERE e.sid = 1
               AND e.geom.STArea() > @p_area
              ) as a,
           (SELECT geometry::UnionAggregate(d.geom) as inner_rings
              FROM (SELECT e.geom
                      FROM [$(owner)].[STExtract](@p_geometry,1) as e
                     WHERE e.sid <> 1
                       AND e.geom.STArea() > @p_area
                   ) as d
           ) f;
    RETURN @v_filtered_geom;
  End;
End
GO

PRINT 'Testing [$(owner)].[STFilterRings] ...';
go

select geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0) as geom
GO

select [$(owner)].[STFilterRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),2) as geom
GO

select a.geom.STArea() as area, a.geom
  from (Select geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((30 30,50 30,50 50,30 50,30 30)), ((0 30,20 30,20 50,0 50,0 30)), ((30 0,31 0,31 1,30 1,30 0)))',0) as geom) as a
GO

select e.geom.STArea() as area, e.geom
  from [$(owner)].[STExtract](
          [$(owner)].[STFilterRings](
             geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((30 30,50 30,50 50,30 50,30 30)), ((0 30,20 30,20 50,0 50,0 30)), ((30 0,31 0,31 1,30 1,30 0)))',0),2.5),1) as e
GO


