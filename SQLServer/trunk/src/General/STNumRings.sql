SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STNumRings]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
 DROP FUNCTION [$(owner)].[STNumRings];
 PRINT 'Dropped [$(owner)].[STNumRings] ...';
END;
GO

PRINT 'Creating [$(owner)].[STNumRings] ...';
GO

CREATE FUNCTION [$(owner)].[STNumRings]
(
  @p_geometry geometry
)
Returns int
As
/****f* INSPECT/STNumRings (2012)
 *  NAME
 *    STNumRings -- Function that returns a count of the number of rings of the supplied polygon object.
 *  SYNOPSIS
 *    Function STNumRings (
 *               @p_geometry geometry,
 *             )
 *     Returns int 
 *  USAGE
 *    SELECT [$(owner)].[STNumRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as numRings
 *    NumRings
 *    3
 *  DESCRIPTION
 *    This function returns the number of rings describing the supplied polygon geometry object.
 *    Supports Polygon, MultiPolygon and CurvePolygon objects.
 *  INPUTS
 *    @p_geometry (geometry) - Supplied polygon geometry.
 *  RESULT
 *    Number of Rings (int) - N where N = 1 or more.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2012 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(100),
    @v_geom         geometry,
    @v_geomn        int = 0,
    @v_ringn        int = 0;
  Begin
    IF ( @p_geometry is null )
       Return 0;

    SET @v_GeometryType = @p_geometry.STGeometryType();

    If ( @v_GeometryType in ('Point','MultiPoint','LineString','MultiLineString' ) )
       Return 0;

    IF ( @v_GeometryType IN ('Polygon','CurvePolygon') )
    BEGIN
      SET @v_ringn = 1 + @p_geometry.STNumInteriorRing();
    END;

    IF ( @v_GeometryType = 'MultiPolygon' )
    BEGIN
      SET @v_geomn  = 1;
      WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @v_geom  = @p_geometry.STGeometryN(@v_geomn);
        SET @v_ringn = @v_ringn + 1 + @v_geom.STNumInteriorRing();
        SET @v_geomn = @v_geomn + 1;
      END; 
    END;

    IF ( @v_GeometryType = 'GeometryCollection' ) 
    BEGIN
      SET @v_geomn  = 1;
      WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
      BEGIN
         SET @v_ringn = @v_ringn + [$(owner)].[STNumRings](@p_geometry.STGeometryN(@v_geomn));
         SET @v_geomn = @v_geomn + 1;
      END;
    END;
    RETURN @v_ringn;
  End;
End
Go

PRINT 'Testing [$(owner)].[STNumRings] ...';
GO

select 'Point' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('POINT(0 0)',0)) as numRings
union all
select 'MultiPoint' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0)) as numRings
union all
select 'LineString' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0)) as numRings
union all
select 'MultiLineString' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as numRings
union all
select 'Polygon Outer' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0))',0)) as numRings
union all
select 'Polygon' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as numRings
union all
select 'MultiPolygon' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as numRings
union all
select 'CurvePolygon' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0)) as numRings
union all
select 'GeometryCollection' as gtype, [$(owner)].[STNumRings](geometry::STGeomFromText('GEOMETRYCOLLECTION(CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0)) as numRings
GO


