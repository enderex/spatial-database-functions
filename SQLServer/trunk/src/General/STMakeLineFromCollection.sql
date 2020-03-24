SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '*************************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) COGO Owner([$(cogoowner)])';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STMakeLineFromGeometryCollection]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeLineFromGeometryCollection];
  PRINT 'Dropped [$(owner)].[STMakeLineFromGeometryCollection] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STMakeLineWKTFromGeometryCollection]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeLineWKTFromGeometryCollection];
  PRINT 'Dropped [$(owner)].[STMakeLineWKTFromGeometryCollection] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STMakeLineWKTFromGeographyCollection]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeLineWKTFromGeographyCollection];
  PRINT 'Dropped [$(owner)].[STMakeLineWKTFromGeographyCollection] ...';
END;
GO

/* *************************** FUNCTIONS ************************************* */

PRINT 'Creating [$(owner)].[STMakeLineFromGeometryCollection] ...';
GO

CREATE FUNCTION [$(owner)].[STMakeLineFromGeometryCollection] 
(
  @p_geometry_collection geometry,
  @p_round_xy            int,
  @p_round_zm            int
)
Returns geometry
AS
/****f* EDITOR/STMakeLineFromGeometryCollection (2008)
 *  NAME
 *    STMakeLineFromGeometryCollection -- Creates a linestring from supplied GeometryCollection geometry.
 *  SYNOPSIS
 *    Function STMakeLineFromGeometryCollection (
 *               @p_geometry_collection geometry
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Function creates linestring from supplied Points or LineStrings, CircularString in @p_geometry_collection.
 *  INPUTS
 *    @p_geometry_collection (geometry) - Not null GeometryCollection containing valid geometry types.
 *  RESULT
 *    linestring -- LineString from provided GeometryCollection's geometries.
 *  EXAMPLE
 *    SELECT [dbo].STMakeLineFromGeometryCollection(geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0,0),POINT(10,10))',28355) as line;
 *
 *    line
 *    LINESTRING(0 0,10 10)
 *
 *    SELECT [dbo].[STMakeLineFromGeometryCollection] (
 *                    geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 5),LINESTRING(3 10,6 -5))',0),
 *                    3,
 *                    2
 *           ).STAsText() as line;
 *
 *     line
 *     MULTILINESTRING ((1 1, 3 5), (3 10, 6 -5))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Server.
 *    Simon Greener - October  2019 - Modified to support linestring and circularstring elements.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  DECLARE
    @v_wkt         varchar(max),
    @v_geomn       int,
    @v_geom        geometry,
    @v_return_geom geometry;
  BEGIN
    IF (@p_geometry_collection is null)
      return geometry::STGeomFromText('LINESTRING EMPTY',0);

    IF (@p_geometry_collection.STGeometryType() <> 'GeometryCollection' )
      Return geometry::STGeomFromText('LINESTRING EMPTY',@p_geometry_collection.STSrid);

    SET @v_wkt = 'LINESTRING (';
    SET @v_geomn = 1;
    WHILE ( @v_geomn <= @p_geometry_collection.STNumGeometries() ) 
    BEGIN
      SET @v_geom = @p_geometry_collection.STGeometryN(@v_geomn);
      IF ( @v_geom.STGeometryType() = 'Point' ) 
      BEGIN
        SET @v_wkt = @v_wkt
                     +
                     case when @v_geomn <> 1 then ', ' else '' end
                     +
                     [$(owner)].[STPointGeomAsText](@v_geom,8,8,8);
      END
      ELSE
      BEGIN
        IF ( @v_geom.STGeometryType() IN ('LineString','CircularString' ) )
          SET @v_return_geom = [$(owner)].[STAppend] (
                                        @v_return_geom,
                                        @v_geom,
                                        @p_round_xy,
                                        @p_round_zm
                               );
      END;
      SET @v_geomn = @v_geomn + 1;
    END;
    IF ( @v_return_geom is not null ) 
      Return @v_return_geom;
    IF ( @v_wkt = 'LINESTRING (' ) 
      Return geometry::STGeomFromText('LINESTRING EMPTY',@p_geometry_collection.STSrid);
    SET @v_return_geom = geometry::STGeomFromText(@v_wkt + ')',@p_geometry_collection.STSrid);
    Return @v_return_geom;
  END;
END;
GO

PRINT 'Creating [$(owner)].[STMakeLineWKTFromGeometryCollection] ...';
GO

CREATE FUNCTION [$(owner)].[STMakeLineWKTFromGeometryCollection] 
(
  @p_points geometry
)
Returns varchar(max)
AS
/****f* CREATE/STMakeLineWKTFromGeometryCollection (2008)
 *  NAME
 *    STMakeLineWKTFromGeometryCollection -- Creates a linestring from supplied GeometryCollection geometry.
 *  SYNOPSIS
 *    Function [STMakeLineWKTFromGeometryCollection] (
 *               @p_points geometry
 *             )
 *     Returns varchar(max) 
 *  USAGE
 *    SELECT [$(owner)].[STMakeLineWKTFromGeometryCollection](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0),POINT(10 10))',28355) as line;
 *    LINE
 *    LINESTRING(0 0,10 10)
 *  DESCRIPTION
 *    Function creates linestring from supplied Points in @p_points (GeometryCollection).
 *  NOTES
 *    Only Point geometries within @p_points supported (LineString etc sub-geometries ignored).
 *  INPUTS
 *    @p_points (geometry) - Not null GeometryCollection containing Point geometry types.
 *  RESULT
 *    linestring (varchar) - LineString from provided GeometryCollection's Point geometries.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  DECLARE
    @v_wkt   varchar(max),
    @v_geomn int,
    @v_geom  geometry;

  IF (@p_points is null)
    return 'LINESTRING EMPTY';

  If ( @p_points.STIsValid() = 0 ) 
    Return @p_points.AsTextZM();

  IF (@p_points.STGeometryType() IN ('LineString','MultiLineString') )
    Return @p_points.AsTextZM();

  IF (@p_points.STGeometryType() <> 'GeometryCollection' )
    Return 'LINESTRING EMPTY';

  SET @v_wkt = 'LINESTRING (';
  SET @v_geomn = 1;
  WHILE ( @v_geomn <= @p_points.STNumGeometries() ) 
  BEGIN
    SET @v_geom = @p_points.STGeometryN(@v_geomn);
    IF ( @v_geom.STGeometryType() = 'Point' ) 
    BEGIN
      SET @v_wkt = @v_wkt
                   +
                   case when @v_geomn <> 1 then ', ' else '' end
                   +
                   [$(owner)].[STPointGeomAsText](@v_geom,8,8,8);
    END;
    SET @v_geomn = @v_geomn + 1;
  END;
  IF ( @v_wkt = 'LINESTRING (' ) 
    Return 'LINESTRING EMPTY';
  SET @v_wkt = @v_wkt + ')';
  Return @v_wkt; 
END
GO

PRINT '**************************************************************';
PRINT 'Creating [$(owner)].[STMakeLineWKTFromGeographyCollection] ...';
GO

CREATE FUNCTION [$(owner)].[STMakeLineWKTFromGeographyCollection] 
(
  @p_points geography
)
Returns varchar(max)
AS
/****f* CREATE/STMakeLineWKTFromGeographyCollection (2008)
 *  NAME
 *    STMakeLineWKTFromGeographyCollection -- Creates a linestring from supplied GeometryCollection geography.
 *  SYNOPSIS
 *    Function [STMakeLineWKTFromGeographyCollection] (
 *               @p_points geography
 *             )
 *     Returns varchar(max) 
 *  USAGE
 *    SELECT [$(owner)].[STMakeLineWKTFromGeographyCollection](geography::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0),POINT(10 10))',28355) as line;
 *    LINE
 *    LINESTRING(0 0,10 10)
 *  DESCRIPTION
 *    Function creates linestring from supplied Points in @p_points (GeometryCollection).
 *  NOTES
 *    Only Point geometries within @p_points supported (LineString etc sub-geometries ignored).
 *  INPUTS
 *    @p_points (geography) - Not null GeometryCollection containing Point geography types.
 *  RESULT
 *    linestring (varchar) - LineString from provided GeometryCollection's Point geometries.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  DECLARE
    @v_dimensions varchar(4),
    @v_wkt        varchar(max),
    @v_geogn      int,
    @v_geog       geography;
  BEGIN
    IF (@p_points IS NULL)
      Return 'LINESTRING EMPTY';

    IF (@p_points.STGeometryType() IN ('LineString','MultiLineString') )
      Return @p_points.AsTextZM();

    IF (@p_points.STGeometryType() <> 'GeometryCollection' )
      Return 'LINESTRING EMPTY';

    SET @v_dimensions  = 'XY' 
                         + case when @p_points.HasZ=1 then 'Z' else '' end 
                         + case when @p_points.HasM=1 then 'M' else '' end;
    SET @v_wkt = 'LINESTRING (';
    SET @v_geogn = 1;
    while ( @v_geogn <= @p_points.STNumGeometries() ) 
    BEGIN
      SET @v_geog = @p_points.STGeometryN(@v_geogn);
      IF ( @v_geog.STGeometryType() = 'Point' ) 
      BEGIN
        SET @v_wkt = @v_wkt
                     +
                     case when @v_geogn <> 1 then ', ' else '' end
                     +
                     [$(owner)].[STPointAsText](
                        @v_dimensions,
                        @v_geog.Long,
                        @v_geog.Lat,
                        @v_geog.Z,
                        @v_geog.M,
                        12,12,12,12);
      END;
      SET @v_geogn = @v_geogn + 1;
    END;
    IF ( @v_wkt = 'LINESTRING (' ) 
      Return 'LINESTRING EMPTY';
    SET @v_wkt = @v_wkt + ')';
    Return @v_wkt; 
  END;
END;
GO

