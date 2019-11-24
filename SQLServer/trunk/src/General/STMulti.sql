SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STMulti]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STMulti];
  PRINT 'Dropped [$(owner)].[STMulti] ...';
END;
GO

PRINT 'Creating [$(owner)].[STMulti] ...';
GO

CREATE FUNCTION [$(owner)].[STMulti]
(
  @p_geometry geometry
)
  RETURNS geometry
As
/****f* EDITOR/STMulti (2012)
 *  NAME
 *    STMulti -- Function that return @p_geometry as a MULTI* geometry
 *  SYNOPSIS
 *    Function STMulti (
 *               @p_geometry geometry
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Returns @p_geometry as a MULTI* geometry. 
 *    For example: POINT -> MULTIPOINT
 *    If @p_geometry is already a MULTI*, it is returned unchanged.
 *    For example: MULTIPOINT -> MULTIPOINT
 *    MULTI returned only contains 1 geometry so STNumGeometries will return 1.
 *  NOTES
 *    CircularString input geometry is returned as a GEOMETRYCOLLECTION as it 
 *    cannot be returned as a MUTLICURVE as it is not instantiable. Additionally,
 *    one cannot construct a MULTILINESTRING containing it MUTLILINESTRING(CIRCULARSTRING(....)).
 *  INPUTS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *  RESULT
 *    geometry    (geometry) - Input geometry converted to MULTI geometry.
 *  EXAMPLE
 *    USE GISDB
 *    GO
 *    
 *    SELECT f.mGeom.AsTextZM() as mGeom, f.mGeom.STNumGeometries() as numGeometries
 *      FROM (SELECT [dbo].[STMulti](geometry::STPointFromText('POINT(0 0)',0)) as mGeom
 *             UNION ALL
 *            SELECT [dbo].[STMulti](geometry::STGeomFromText ('POLYGON ((0 0,10 0,10 10,0 10,0 0))',0)) as mgeom
 *             UNION ALL
 *            SELECT [dbo].[STMulti](geometry::STGeomFromText ('LINESTRING(0 0,10 10,20 20)',0)) as mgeom
 *             UNION ALL
 *            SELECT [dbo].[STMulti](geometry::STGeomFromText('CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872)',0)) as mgeom
 *    	 ) as f;
 *    GO
 *
 *    mGeom                                                                  numGeometries
 *    MULTIPOINT ((0 0))                                                                 1
 *    MULTIPOLYGON (((0 0, 10 0, 10 10, 0 10, 0 0)))                                     1
 *    MULTILINESTRING ((0 0, 10 10, 20 20))                                              1
 *    GEOMETRYCOLLECTION (CIRCULARSTRING (9.962 -0.872, 10.1 0, 9.962 0.872))            1
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original TSQL Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
     @v_GeometryType varchar(100) = '',
     @v_wkt          varchar(max) = '';

    If ( @p_geometry is NULL ) 
      RETURN NULL;

    SET @v_GeometryType = @p_geometry.STGeometryType();
    IF ( @v_GeometryType IN ('MultiPolygon','GeometryCollection','MultiPoint','MultiCurve','MultiLineString','CompoundCurve') ) BEGIN
      RETURN @p_geometry;
    END;
    SET @v_wkt = @p_geometry.AsTextZM();
    SET @v_wkt = case when @v_geometryType = 'CircularString' then @v_wkt 
                      else REPLACE(@v_wkt,UPPER(@v_geometryType),'')
                  end;
    SET @v_wkt = case when @v_geometryType = 'Point'          then 'MULTIPOINT'
                      when @v_geometryType = 'Polygon'        then 'MULTIPOLYGON'
                      when @v_geometryType = 'LineString'     then 'MULTILINESTRING'
                      when @v_geometryType = 'CircularString' then 'GEOMETRYCOLLECTION' -- MULTICURVE not instantiable
                  end + '(' + @v_wkt + ')';
    RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
End;
GO

PRINT 'Testing [$(owner)].[STMulti] ...';
GO

select [$(owner)].[STMulti](geometry::STGeomFromText('POINT(1 1 1 1)',0)) as wkt
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0)) as WKT
GO
Select [$(owner)].[STMulti](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0)) as wkt
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0)) as WKT
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872)',0)) as wkt;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('POLYGON((1 1,10 1,10 10,1 10,1 1),(2 2,9 2,9 9,2 9,2 2))',0)) as wkt;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0)) as WKT;
GO
select [$(owner)].[STMulti](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872))',0)) as wkt;
go

SELECT f.mGeom.AsTextZM() as mGeom, f.mGeom.STNumGeometries() as numGeometries
  FROM (SELECT [$(owner)].[STMulti](geometry::STPointFromText('POINT(0 0)',0)) as mGeom
         UNION ALL
        SELECT [$(owner)].[STMulti](geometry::STGeomFromText ('POLYGON ((0 0,10 0,10 10,0 10,0 0))',0)) as mgeom
         UNION ALL
        SELECT [$(owner)].[STMulti](geometry::STGeomFromText ('LINESTRING(0 0,10 10,20 20)',0)) as mgeom
         UNION ALL
        SELECT [$(owner)].[STMulti](geometry::STGeomFromText('CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872)',0)) as mgeom
	 ) as f;


