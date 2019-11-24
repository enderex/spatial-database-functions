SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: COGO=$(cogoowner) owner=$(owner)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STExtractPolygon]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STExtractPolygon];
  PRINT 'Dropped [$(owner)].[STExtractPolygon] ...';
END;
GO

-- ************************************************************************************

PRINT 'Creating [$(owner)].[STExtractPolygon] ...';
GO

CREATE FUNCTION [$(owner)].[STExtractPolygon] 
(
  @p_geometry geometry
)
Returns geometry
AS
/****f* GEOPROCESSING/STExtractPolygon (2012)
 *  NAME
 *    STExtractPolygon -- Extracts polygons from GeometryCollection
 *  SYNOPSIS
 *    Function [$(owner)].[STExtractPolygon] (
 *               @p_geometry geometry
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    This function allows a user to extract polygons from a GeometryCollection.
 *    Useful where result of an STIntersection between two polygons results in points, lines and polygons.
 *    If input is already a polygon it is returned unchanged.
 *  INPUTS
 *    @p_geometry (geometry) - CurvePolygon, Polygon, MultiPolygon or GeometryCollection geometry objects.
 *  NOTES
 *    Depends on STExtract.
 *  EXAMPLE
 *    -- Result of STIntersection() between two overlapping polygons can result in points, lines and polygons.
 *    -- Extract only polygons...
 *    WITH data As (
 *    SELECT geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) as geoma,
 *           geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0) as geomb
 *    )
 *    SELECT CAST('POLY A' as varchar(12)) as source, d.geoma.AsTextZM() as geoma from data as d
 *    union all
 *    SELECT 'POLY B' as source, d.geomb.AsTextZM() as geomb from data as d
 *    union all
 *    SELECT 'Intersection' as source, d.geoma.STIntersection(d.geomb).AsTextZM() as geom FROM data as d
 *    union all
 *    SELECT 'RESULT' as source, [$(owner)].[STExtractPolygon](d.geoma.STIntersection(d.geomb)).AsTextZM() as geom FROM data as d;
 *    GO
 *    source       geoma
 *    ------------ -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *    POLY A       POLYGON ((100 0, 400 0, 400 480, 160 480, 160 400, 240 400, 240 300, 100 300, 100 0))
 *    POLY B       POLYGON ((-175 0, 100 0, 0 75, 100 75, 100 200, 200 325, 200 525, -175 525, -175 0))
 *    Intersection GEOMETRYCOLLECTION (POLYGON ((160 400, 200 400, 200 480, 160 480, 160 400)), POLYGON ((100 200, 180 300, 100 300, 100 200)), LINESTRING (100 200, 100 75), POINT (100 0))
 *    RESULT       MULTIPOLYGON (((160 400, 200 400, 200 480, 160 480, 160 400)), ((100 200, 180 300, 100 300, 100 200)))
 *  RESULT
 *    (multi)polygon - Polygon or MultiPolygon object including CUrvePolygons..
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
     @v_geom geometry;
  Begin
    If ( @p_geometry is NULL ) 
      return null;
    IF ( @p_geometry.STGeometryType() NOT IN ('CurvePolygon','Polygon','MultiPolygon','GeometryCollection') )
      return null;
    IF ( @p_geometry.STGeometryType() IN ('CurvePolygon','Polygon','MultiPolygon') )
      return @p_geometry;
    IF ( @p_geometry.STGeometryType() IN ('GeometryCollection') )
    BEGIN
      -- Need to extract and append any polygons that may be in the GeometryCollection
      --
      SELECT @v_geom = geometry::CollectionAggregate(e.[geom])
        FROM [$(owner)].[STExtract](@p_geometry,0) as e
       WHERE e.[geom].STGeometryType() IN ('CurvePolygon','Polygon');
      IF ( @v_geom IS NOT NULL AND @v_geom.STNumGeometries() > 0 ) 
      BEGIN
        IF ( @v_geom.STNumGeometries() = 1 )
        BEGIN
          -- Get rid of GeometryCollection WKT token wrapper
          --
          SET @v_geom = geometry::STGeomFromText(REPLACE(REPLACE(@v_geom.STAsText(),'GEOMETRYCOLLECTION (','')+'$',')$',''),@v_geom.STSrid);
        END
        ELSE
        BEGIN
          IF ( CHARINDEX('CURVEPOLYGON',@v_geom.STAsText()) = 0 )
          BEGIN
             -- Replace all internal POLYGON WKT tokens with nothing
             -- Then replace starting GeometryCollection token with MultiPolygon
             --
             SET @v_geom = geometry::STGeomFromText(REPLACE(REPLACE(UPPER(@v_geom.STAsText()),'POLYGON',''),'GEOMETRYCOLLECTION','MULTIPOLYGON'),@v_geom.STSrid);
          END;
        END;
      END;
    END;
    RETURN @v_geom;
  End;
End
Go

Print '************************************';
Print 'Testing [$(owner)].[STExtractPolygon] ...';
GO

Print 'All these return null as non of inputs are polygons ....';
go

select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('POINT(0 0)',0)).STAsText() as ePoly union all
select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0)).STAsText() as ePoly union all
select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0)).STAsText() as ePoly union all
select [$(owner)].[STExtractPolygon](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)).STAsText() as ePoly
GO

-- These should extract only the polygons within the GeometryCollection
-- (The second is wrapped as a GeometryCollection as a MultiPolygon cannot be constructed that includes a CurvePolygon
--
select e.gid, e.sid, e.geom.STAsText() as geomWKt
  from [$(owner)].[STExtract](
         [$(owner)].[STExtractPolygon](
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
                          (0 -23.43778, 0 23.43778)
                  ),
                  POLYGON ((100 200, 180.00 300.00, 100 300, 100 200)), 
                  LINESTRING (100 200, 100 75), 
                  POINT (100 0))',0
             )
           ),
		 0) as e
GO

PRINT '*********************************************';
PRINT 'Test the intersection between two polygons...';
GO

WITH data As (
SELECT geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) as geoma,
       geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0) as geomb
)
SELECT CAST('POLY A' as varchar(12)) as source, d.geoma.AsTextZM() as geoma from data as d
union all
SELECT 'POLY B' as source, d.geomb.AsTextZM() as geomb from data as d
union all
SELECT 'Intersection' as source, d.geoma.STIntersection(d.geomb).AsTextZM() as geom FROM data as d
union all
SELECT 'RESULT' as source, [$(owner)].[STExtractPolygon](d.geoma.STIntersection(d.geomb)).AsTextZM() as geom FROM data as d;
GO

