SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: COGO=$(cogoowner) Owner=$(owner)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STExtract]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STExtract];
  PRINT 'Dropped [$(owner)].[STExtract] ...';
END;
GO

PRINT 'Creating [$(owner)].[STExtract] ...';
GO

CREATE FUNCTION [$(owner)].[STExtract]
(
  @p_geometry geometry,
  @p_sub_geom int = 0 
)
Returns @geometries TABLE 
(
  gid  integer,
  sid  integer,
  geom geometry
)  
AS
/****f* GEOPROCESSING/STExtract (2012)
 *  NAME
 *    STExtract -- Extracts the subelements that describe the input geometry.
 *  SYNOPSIS
 *    Function [$(owner)].[STExtract] (
 *               @p_geometry geometry,
 *               @p_sub_geom int = 0
 *             )
 *     Returns @geometries TABLE 
 *     (
 *       gid  integer,
 *       sid  integer,
 *       geom geometry
 *     )  
 *  DESCRIPTION
 *    This function allows a user to extract the subelements of the supplied geometry.
 *    Some geometries have no subelements: eg Point, LineString
 *    The subelements of a geometry change depending on the geometry type: 
 *      1. A MultiPoint only has one or more Point subelements; 
 *      2. A MultiLineString only more than one LineString subelements; 
 *      3. A Polygon has zero one or more inner rings and only one outer ring;
 *      4. A MultiPolygon has zero one or more inner rings and one or more outer rings;
 *    Some subelements can have subelements when they are Compound:
 *      1. A CircularCurve can be described by one or more three point circular arcs.
 *    If @p_sub_geom is set to 0, only single geometry elements of a multi geometry are extracted.
 *    If @p_sub_geom is set to 1, any subelements (eg ring) of a geometry (eg polygon) are extracted.
 *    If @p_sub_geom is set to 2, any subelements (CIRCULARSTRING) of a subelement (COMPOUNDCURVE) are extracted.
 *  NOTES
 *    This version is for versions of SQL Server from 2012 onwards.
 *  INPUTS
 *    @p_geometry (geometry) - Polygon or Multipolygon geometry object.
 *    @p_sub_geom    (float) - Extract elements (individual circular arcs) of a compound subelement.
 *  EXAMPLE
 *    SELECT e.gid, sid, geom.AsTextZM() as egeom
 *      FROM [$(owner)].[STExtract] (
 *                 geometry::STGeomFromText('GEOMETRYCOLLECTION (POLYGON ((100 200, 180 300, 100 300, 100 200)), LINESTRING (100 200, 100 75), POINT (100 0))',0),0) as e;
 *    GO
 *    gid sid egeom
 *    --- --- ----------------------------------------------
 *      1   0 POLYGON ((100 200, 180 300, 100 300, 100 200))
 *      2   0 LINESTRING (100 200, 100 75)
 *      3   0 POINT (100 0)
 *
 *    SELECT e.gid, sid, geom.AsTextZM() as egeom
 *      FROM [$(owner)].[STExtract] (geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0),1) as e;
 *    GO
 *    gid sid egeom
 *    --- --- ------------------------------------------
 *      1   0 LINESTRING (0 0, 5 5, 10 10, 11 11, 12 12)
 *      2   0 LINESTRING (100 100, 200 200)
 *
 *    SELECT e.gid, sid, geom.AsTextZM() as egeom
 *      FROM [$(owner)].[STExtract] (
 *              geometry::STGeomFromText('GEOMETRYCOLLECTION (COMPOUNDCURVE(CIRCULARSTRING (3 6.32, 0 7, -3 6.32),(-3 6.32, 0 0, 3 6.32)))',0),
 *               1
 *           ) as e;
 *    GO
 *    gid sid egeom
 *    --- --- -------------------------------------
 *      1   1 CIRCULARSTRING (3 6.32, 0 7, -3 6.32)
 *      1   2 LINESTRING (-3 6.32, 0 0)
 *      1   3 LINESTRING (0 0, 3 6.32)
 *  RESULT
 *    Array of subelements:
 *    gid  - Geometry Identifier (for multigeomemtry objects, the individual high level geometry objects it describes).
 *    sid  - Sub Element Identifier
 *    geom - Geometry representation of subelement.
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
    @v_GeometryType varchar(1000),
    @v_sub_geom     int,
    @v_sub_n        int,
    @v_geom_n       int,
    @geom           geometry;
  Begin
    If ( @p_geometry is NULL ) 
      return;

    SET @v_sub_geom = COALESCE(@p_sub_geom,0);
	IF ( @v_sub_geom not in (0,1,2) ) 
	  return; 

    SET @v_GeometryType = @p_geometry.STGeometryType();

    IF ( @v_GeometryType = 'Point' )
    BEGIN
      INSERT INTO @geometries ( [gid],[sid],[geom] ) 
           VALUES ( 1,
                    0,
                    @p_geometry );
      RETURN;
    END;

    IF ( @v_GeometryType = 'MultiPoint' ) 
    BEGIN
      SET @v_geom_n  = 1;
      WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
      BEGIN
        INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             VALUES ( @v_geom_n,
                      0,
                      @p_geometry.STGeometryN(@v_geom_n) );
        SET @v_geom_n = @v_geom_n + 1;
      END; 
      RETURN;
    END;

    IF ( @v_GeometryType IN ('LineString','CircularString') )
    BEGIN
      INSERT INTO @geometries ( [gid],[sid],[geom] ) 
           VALUES ( 1, 
                    0, 
                    @p_geometry );
      RETURN;
    END;

    IF ( @v_GeometryType IN ('CompoundCurve') )
    BEGIN
      IF ( @p_sub_geom in (0,1) ) 
      BEGIN
        INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             VALUES ( 1, 0, @p_geometry );
      RETURN;
      END
      ELSE
      BEGIN
	    IF (@v_sub_geom = 2) 
        BEGIN 
          SET @v_geom_n  = 1;
          WHILE ( @v_geom_n <= @p_geometry.STNumCurves() )
          BEGIN
            INSERT INTO @geometries ( [gid],[sid],[geom] ) 
                 VALUES ( 1,
                          @v_geom_n, 
                          @p_geometry.STCurveN(@v_geom_n) );
            SET @v_geom_n = @v_geom_n + 1;
          END; 
          RETURN;
        END;
      END 
    END;
    
    IF ( @v_GeometryType IN ('MultiLineString') ) 
    BEGIN
      SET @v_geom_n  = 1;
      WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
      BEGIN
        INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             SELECT @v_geom_n,
                    [sid],
                    [geom]
               FROM [$(owner)].[STExtract](@p_geometry.STGeometryN(@v_geom_n),@p_sub_geom); 
        SET @v_geom_n = @v_geom_n + 1;
      END; 
      RETURN;
    END;
    
    IF ( @v_GeometryType IN ('Polygon','CurvePolygon') )
    BEGIN
      IF ( @p_sub_geom = 0 )
      BEGIN
        INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             VALUES ( 1,
                      0,
                      @p_geometry); 
      END
	  ELSE
	  BEGIN
        SET @v_sub_n  = 0;
        WHILE ( @v_sub_n < ( 1 + @p_geometry.STNumInteriorRing() ) )
        BEGIN
          IF ( @v_sub_n = 0 )
            SET @geom = @p_geometry.STExteriorRing()
          ELSE
            SET @geom = @p_geometry.STInteriorRingN(@v_sub_n);

          IF ( @v_geometryType = 'CurvePolygon' 
               and 
               @v_sub_geom = 2)
          BEGIN
             INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             SELECT a.gid, a.sid, a.geom 
               FROM [$(owner)].[STExtract](@geom,@p_sub_geom) as a;
          END
          ELSE
          BEGIN
            INSERT INTO @geometries ( [gid],[sid],[geom] ) 
               VALUES ( 1,
                        @v_sub_n + 1,
                        geometry::STGeomFromText(
                                  CASE WHEN UPPER(@geom.STAsText()) LIKE 'LINESTRING%' 
                                       THEN REPLACE(REPLACE(UPPER(@geom.STAsText()),'LINESTRING (','POLYGON (('),')','))')
                                       WHEN UPPER(@geom.STAsText()) LIKE 'COMPOUNDCURVE%' 
                                       THEN REPLACE(UPPER(@geom.STAsText()),'COMPOUNDCURVE','CURVEPOLYGON(COMPOUNDCURVE') + ')'
                                       ELSE @geom.STAsText()
                                    END, 
                                  @p_geometry.STSrid));
          END;
          SET @v_sub_n = @v_sub_n + 1;
        END; 
      END;
      RETURN;
    END;
    
    IF ( @v_GeometryType = 'MultiPolygon' )
    BEGIN
      SET @v_geom_n  = 1;
      WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
      BEGIN
         IF ( @p_sub_geom = 0 ) 
         BEGIN
             INSERT INTO @geometries ( [gid],[sid],[geom] ) 
                  VALUES ( @v_geom_n,
                           0,
                           @p_geometry.STGeometryN(@v_geom_n)); 
         END 
         ELSE
         BEGIN
             INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             SELECT @v_geom_n,
                    [sid],
                    [geom]
               FROM [$(owner)].[STExtract](@p_geometry.STGeometryN(@v_geom_n),@p_sub_geom); 
         END; 
         SET @v_geom_n = @v_geom_n + 1;
      END; 
      RETURN;
    END;
    
    IF ( @v_GeometryType = 'GeometryCollection' )
    BEGIN
      SET @v_geom_n  = 1;
      WHILE ( @v_geom_n <= @p_geometry.STNumGeometries() )
      BEGIN
         INSERT INTO @geometries ( [gid],[sid],[geom] )
              SELECT @v_geom_n,
                     [sid],
                     [geom]
                FROM [$(owner)].[STExtract](@p_geometry.STGeometryN(@v_geom_n),@p_sub_geom);
        SET @v_geom_n = @v_geom_n + 1;
      END;
      RETURN;
    END;
  End;
  RETURN;
END
Go

-- ************************************************************************************************

PRINT 'Testing ....';
GO

select 'Single Point' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('POINT(0 0)',0),1) as gElem;
GO

select 'MultiPoint' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom
  from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0),1) as gElem;
GO

select 'Simple Single LineString' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0),1) as gElem 
GO

select 'Simple MultiLine with 3 LineStrings' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](
         geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),
         1
       ) as gElem 
GO

select 'Simple MultiPolygon with 3 Exterior Rings and 2 Interior Rings' as test,
       1 as sub_geom,
       d.gid,d.sid,d.geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText(
            'MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), 
			               ((80 80, 100 80, 100 100, 80 100, 80 80)), 
						   ((110 110, 150 110, 150 150, 110 150, 110 110)))',0),
			1) as d
GO

select 'Single Polygon with 2 Interior Rings' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](
          geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),
          1) as gElem 
GO

select 'Simple MultiPolygon with two simple Polygons (ExteriorRings)' as test,
       1 as sub_geom, gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](
          geometry::STGeomFromText(
               'MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0),
          1) as gElem 
GO

select 'Simple MultiPolygon with three Polygons with 2/0/0 Interior RIngs rings' as test,
        1 as sub_geom,
        gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](
         geometry::STGeomFromText(
           'MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0),
         1) as gElem 
GO

-- *******************
-- Compound Geometries

select 'Single Compound Curve LineString' as test,
       g.IntValue as sub_geom, 
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](0,2,1) g
       cross apply
	   [$(owner)].[STExtract](geometry::STGeomFromText(
         'COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778))',0),
         g.[IntValue]
       ) as gElem
GO

select 'Single Curve Polygon with one exterior (compound) ring' as test,
       g.IntValue as sub_elem, gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](0,2,1) g
       cross apply
       [$(owner)].[STExtract](
         geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0),
         g.IntValue
       ) as gElem 
GO

select 'Curve Polygon (circularString exterior ring) with a single interior CircularString (circle) ring' as test,
       g.IntValue as sub_elem,gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](0,2,1) g
       cross apply
       [$(owner)].[STExtract] (
          geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 4, 4 0, 8 4, 4 8, 0 4), CIRCULARSTRING(2 4, 4 2, 6 4, 4 6, 2 4))',0),
		  g.IntValue) as e;

select 'Geometry Collection with Compound elements' as test,
       g.IntValue as sub_geom, gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](2,2,1) g
       cross apply
       [$(owner)].[STExtract] (
          geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), 
                                                       CURVEPOLYGON(
                                                          COMPOUNDCURVE((0 -23.43778, 0 23.43778),
                                                                        CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
                                                                        (-90 23.43778, -90 -23.43778),
                                                                        CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), 
                                                       COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), 
                                                                     (0 -23.43778, 0 23.43778)))',0),
          g.intValue
       ) as gElem 
GO


