SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STExtract]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STExtract];
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
/****f* GEOPROCESSING/STExtract (2008)
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
 *    If @p_sub_geom is set to 1, any subelements of a subelement are extracted.
 *  NOTES
 *    This version is for SQL Server 2008 only.
 *  INPUTS
 *    @p_geometry (geometry) - Polygon or Multipolygon geometry object.
 *    @p_sub_geom    (float) - Extract elements (individual circular arcs) of a compound subelement.
 *  EXAMPLE
 *    SELECT t.*
 *      FROM [$(owner)].[STExtract](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),0).AsTextZM() as t
 *    GO
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
    @v_sub_n        int,
    @v_geom_n       int,
    @geom           geometry;
  Begin
    If ( @p_geometry is NULL ) 
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

/* STCurveN not in 2008 
    IF ( @v_GeometryType IN ('CircularCurve','CompoundCurve') )
    BEGIN
      IF ( @p_sub_geom = 0 ) 
      BEGIN
        INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             VALUES ( 1, 0, @p_geometry );
      RETURN;
      END
      ELSE
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
     END 
    END;
*/ 
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
      IF ( @p_sub_geom = 1 )
      BEGIN
        SET @v_sub_n  = 0;
        WHILE ( @v_sub_n < ( 1 + @p_geometry.STNumInteriorRing() ) )
        BEGIN
          IF ( @v_sub_n = 0 )
            SET @geom = @p_geometry.STExteriorRing()
          ELSE
            SET @geom = @p_geometry.STInteriorRingN(@v_sub_n);
          IF ( @v_geometryType = 'CurvePolygon' )
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
      END
      ELSE
      BEGIN
        INSERT INTO @geometries ( [gid],[sid],[geom] ) 
             VALUES ( 1,
                      0,
                      @p_geometry); 
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
END;
Go

PRINT 'Testing [$(owner)].[STExtract] ....';
GO

select 'POINT' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('POINT(0 0)',0),1) as gElem union all
select 'MPONT' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0),1) as gElem union all
select 'LINES' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0),1) as gElem union all
select 'MLINE' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),1) as gElem union all
select 'POLYI' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),1) as gElem union all
select 'MPLYO' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0),1) as gElem union all
select 'MPLYI' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0),1) as gElem union all
select 'CPLY0' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0),0) as gElem union all
select 'CPLY1' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0),1) as gElem union all
select 'GEOC0' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0),0) as gElem union all
select 'GEOC1' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0),1) as gElem;
GO

