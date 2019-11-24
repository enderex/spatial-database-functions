SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STConvertToLineString]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STConvertToLineString];
  Print 'Dropped [$(owner)].[STConvertToLineString] ...';
END;
GO

PRINT 'Creating [$(owner)].[STConvertToLineString] ...';
GO

CREATE FUNCTION [$(owner)].[STConvertToLineString] 
(
  @p_geometry_collection geometry
)
Returns geometry
AS
/****f* EDITOR/STConvertToLineString (2008)
 *  NAME
 *    STConvertToLineString -- Creates a (multi)linestring from supplied GeometryCollection geometry's (multi)linestring objects.
 *  SYNOPSIS
 *    Function STConvertToLineString (
 *               @p_geometry_collection geometry
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [dbo].STConvertToLineString(geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,1 1),MULTILINESTRING((3 3,8 8),(9 9,20 20)))'',0) as line;
 *    LINE
 *    LINESTRING(0 0,10 10)
 *  DESCRIPTION
 *    Function creates linestring from linestrings within supplied @p_geometry_collection (GeometryCollection).
 *  NOTES
 *    Only LineString/MultiLinestring/CircularString/CompoundString geometries within @p_geometry_collection supported 
 *  INPUTS
 *    @p_geometry_collection (geometry) - Not null GeometryCollection containing some linear geometry types.
 *  RESULT
 *    (Multi)LineString -- (Multi)LineString from provided GeometryCollection's linear geometries.
 *  EXAMPLE
 *    With gc As (
 *      select geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
 *       union all
 *      select geometry::STGeomFromText('GEOMETRYCOLLECTION (MULTILINESTRING((0 0,20 0),(20 20,0 20,0 0)))', 0) as geom
 *       union all
 *      select geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
 *       union all
 *      select geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0),LINESTRING(1 1,2 2),LINESTRING(3 3,19 19),POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
 *       union all
 *      select geometry::STGeomFromText('GEOMETRYCOLLECTION(MULTILINESTRING((0 0,20 0),(20 20,0 20,0 0)), LINESTRING(1 1,2 2),LINESTRING(3 3,19 19),POINT(0 0),POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
 *    )
 *    select [dbo].[STConvertToLineString](geom).STAsText() as geomWKT
 *      from gc as a
 *    go
 *
 *    geomWKT
 *    ---------------------------------------------------------------------------
 *    LINESTRING EMPTY
 *    MULTILINESTRING ((0 0, 20 0), (20 20, 0 20, 0 0))
 *    LINESTRING (0 0, 20 0, 20 20, 0 20, 0 0)
 *    MULTILINESTRING ((0 0, 20 0, 20 20, 0 20, 0 0), (1 1, 2 2), (3 3, 19 19))
 *    MULTILINESTRING ((0 0, 20 0), (20 20, 0 20, 0 0), (1 1, 2 2), (3 3, 19 19))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August  2018 - Original TSQL Coding for SQL Server.
 *    Simon Greener - October 2019 - Fixed bug with single MultiLineString in Geometry Collection.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  DECLARE
    @v_geomn int,
    @v_rgeom geometry,
    @v_geom  geometry;
  BEGIN
    IF (@p_geometry_collection is null)
      return geometry::STGeomFromText('LINESTRING EMPTY',0);

    IF (@p_geometry_collection.STGeometryType() 
             IN ('LineString',
                 'MultiLineString', 
                 'CircularString',
                 'CompoundCurve') )
      Return @p_geometry_collection;

    IF (@p_geometry_collection.STGeometryType() <> 'GeometryCollection' )
      Return geometry::STGeomFromText('LINESTRING EMPTY',@p_geometry_collection.STSrid);

    SET @v_geomn = 1;
    while ( @v_geomn <= @p_geometry_collection.STNumGeometries() ) 
    BEGIN
      SET @v_geom = @p_geometry_collection.STGeometryN(@v_geomn);
      IF ( @v_geom.STGeometryType() IN ('LineString',
                                        'MultiLineString', 
                                        'CircularString',
                                        'CompoundCurve') )
      BEGIN
        IF ( @v_geomn = 1 ) 
          SET @v_rgeom = @v_geom;
        ELSE
          SET @v_rgeom = [$(owner)].[STAppend](@v_rgeom,@v_geom,8,8);         
      END;
      SET @v_geomn = @v_geomn + 1;
    END;
    Return case when (@v_rgeom is null)
                then geometry::STGeomFromText('LINESTRING EMPTY',@p_geometry_collection.STSrid)
                else @v_rgeom 
            end;
  END;
END
GO

PRINT 'Testing STConvertToLineString ...'
GO

With gc As (
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION (MULTILINESTRING((0 0,20 0),(20 20,0 20,0 0)))', 0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0),LINESTRING(1 1,2 2),LINESTRING(3 3,19 19),POINT(0 0), POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
   union all
  select geometry::STGeomFromText('GEOMETRYCOLLECTION(MULTILINESTRING((0 0,20 0),(20 20,0 20,0 0)), LINESTRING(1 1,2 2),LINESTRING(3 3,19 19),POINT(0 0),POLYGON((0 0,10 0,10 10,0 10,0 0)) )',0) as geom
)
SELECT [$(owner)].[STConvertToLineString](geom) as geom,
       [$(owner)].[STConvertToLineString](geom).STAsText() as geomWKT
  from gc as a
go

