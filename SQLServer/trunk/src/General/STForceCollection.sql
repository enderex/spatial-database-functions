SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STForceCollection]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STForceCollection];
  PRINT 'Dropped [$(owner)].[STForceCollection] ...';
END;
GO

PRINT 'Creating [$(owner)].[STForceCollection] ...';
GO

CREATE FUNCTION [$(owner)].[STForceCollection] (
  @p_polygon         geometry,
  @p_linestrings     int = 0, /* 0 means polygons will be GC elements, otherwise LINESTRINGS */
  @p_multilinestring int = 0
)
Returns geometry
As
/****f* GEOPROCESSING/STForceCollection (2008)
 *  NAME
 *    STForceCollection -- Creates a square buffer to left or right of a linestring.
 *  SYNOPSIS
 *    Function [$(owner)].[STForceCollection] (
 *       @p_polygon         geometry,
 *       @p_linestrings     int = 0, -- 0 means polygons will be GC elements, otherwise LINESTRINGS
 *       @p_multilinestring int = 0
 *    )
 *    Returns geometry
 *  DESCRIPTION
 *    This function extracts the rings of a polygon and returns them within a GeometryCollection or a MultLineString.
 *    Polygons rings as polygons can only be returned in a GeometryCollection.
 *    Polygon rings can be converted to LineStrings and returned in a GeometryCollection with no checking of validity by SQL Server Spatial.
 *    Polygon rings can be converted to LineStrings and returned in a MultiLineStrings but are subject to validition by SQL Server Spatial.
 *    If @p_linestrings = 0 and @p_multilinestring is 1 the function changes to @p_multilinestring 0 as polygons cannot be returned in a MultiLineString.
 *  NOTES
 *    1. Supports CompoundCurves in polygon rings
 *    2. See PostGIS's ST_ForceCollection 
 *  INPUTS
 *    @p_polygon    (geometry) - Must be a Polygon geometry.
 *    @p_linestrings     (int) - Rings are to be converted to LineStrings if 1, otherwise Polygons.
 *    @p_multilinestring (int) - Return rings using GeometryCollection (0) or MultiLineString (1)
 *  RESULT
 *    collection    (geometry) - Either MultiLineString or GeometryCollection.
 *  EXAMPLE
 *    select [$(owner)].[STForceCollection](
 *                 geometry::STGeomFromText('POLYGON ((98.4 883.585, 115.729 ... 101.533 902.06))',0),
 *              0,
 *              0
 *           ).AsTextZM() as gCollection;
 *    GO
 *    
 *    gCollection
 *    GEOMETRYCOLLECTION (POLYGON ((97.705 885.823, 93.766 886.819,....()
 *    
 *    select [$(owner)].[STForceCollection](
 *                 geometry::STGeomFromText('POLYGON ((98.4 883.585, 115.729 ... 101.533 902.06))',0),
 *              1,
 *              0
 *           ).AsTextZM() as gCollection;
 *    GO
 *    
 *    gCollection
 *    GEOMETRYCOLLECTION (LINESTRING (97.705 885.823, 93.766 886.819, ... 101.533 902.06))
 *    
 *    select [$(owner)].[STForceCollection](
 *             geometry::STGeomFromText('POLYGON ((97.705 885.823, 93.766 886.819, 109.224 898.931, 97.705 885.823))',0),               
 *             1,
 *             1
 *           ).STAsText() as gCollection;
 * 
 *    gCollection
 *    MULTILINESTRING ((97.705 885.823, 93.766 886.819, 109.224 898.931, 97.705 885.823))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Oct 2019 - Original coding (Oracle).
 *  COPYRIGHT
 *    (c) 2012-2019 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
******/
Begin
  DECLARE
    @v_wkt             varchar(max),
    @v_ring_wkt        varchar(max),
    @v_linestrings     integer,
    @v_multilinestring integer,
   @v_egeom           geometry,
    @v_return_geom     geometry;
  BEGIN
    IF (@p_polygon is null ) 
     Return @p_polygon;
   IF (@p_polygon.STGeometryType() <> 'Polygon' )
     Return @p_polygon;
    SET @v_multilinestring = COALESCE(@p_multilinestring,0);
    SET @v_linestrings     = case when @v_multiLineString = 1
                                  then 1
                                  else COALESCE(@p_linestrings,0)
                              end;
    SET @v_wkt = case when @v_multilinestring = 0 
                      then 'GEOMETRYCOLLECTION('
                      else 'MULTILINESTRING('
                  end;

    DECLARE cExplodeRings
     CURSOR FAST_FORWARD 
        FOR
     SELECT e.Geom as eGeom
      FROM [$(owner)].[STExplode] (@p_polygon) as e;

    OPEN cExplodeRings;

    FETCH NEXT 
     FROM cExplodeRings 
     INTO @v_egeom;
           
    -- Check if any filtered segments were returned.
    -- 
    IF ( @@FETCH_STATUS <> 0 ) 
    BEGIN
      -- Nothing to do.
      CLOSE      cExplodeRings;
      DEALLOCATE cExplodeRings;
      RETURN NULL; 
    END;

    WHILE ( @@FETCH_STATUS = 0 )
    BEGIN
      IF ( @v_eGeom is not null ) 
      BEGIN
        SET @v_ring_wkt = @v_egeom.AsTextZM();
        IF ( @v_multilinestring = 1 )
        BEGIN
          SET @v_ring_wkt = REPLACE(REPLACE(REPLACE(@v_egeom.AsTextZM(),'POLYGON ((','('),')),((','),('),'))',')');
        END
        ELSE
        BEGIN
          IF ( @v_linestrings = 1 )
            SET @v_ring_wkt = REPLACE(REPLACE(REPLACE(@v_egeom.AsTextZM(),'POLYGON ((','LINESTRING ('),')),((','),('),'))',')');
        END;
        SET @v_wkt = @v_wkt + 
                     CASE WHEN ( @v_wkt not in ('GEOMETRYCOLLECTION(','MULTILINESTRING(') ) THEN ',' ELSE '' END +
                     @v_ring_WKT;
      END;
      FETCH NEXT 
       FROM cExplodeRings 
       INTO @v_eGeom;
    END;
    CLOSE      cExplodeRings;
    DEALLOCATE cExplodeRings;
    SET @v_return_geom = geometry::STGeomFromText(
                                    case when @v_wkt IS NULL OR @v_wkt = 'GEOMETRYCOLLECTION('  
                                         then 'GEOMETRYCOLLECTION EMPTY'
                                         when @v_wkt = 'MULTILINESTRING('
                                         then 'MULTILINESTRING EMPTY'
                                         else @v_wkt + ')'
                                     end,
                                     @p_polygon.STSrid
                                 );
    RETURN @v_return_geom;
  END;
End;
GO


