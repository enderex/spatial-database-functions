USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STVectorize]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STVectorize];
  PRINT 'Dropped [$(owner)].[STVectorize] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STSegmentize]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STSegmentize];
  PRINT 'Dropped [$(owner)].[STSegmentize] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[_STVectorize]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION  [$(owner)].[_STVectorize];
  PRINT 'Dropped [$(owner)].[_STVectorize] ...';
END;
GO

PRINT 'Creating [$(owner)].[_STVectorize] ...'
GO 

CREATE FUNCTION [$(owner)].[_STVectorize]
(
  @p_geometry geometry,
  @p_start_id int = 1
)
RETURNS @Vectors TABLE
(
  id            int,
  element_id    int,
  subelement_id int,
  vector_id     int, 
  sx            float,  /* Start Point */
  sy            float,
  sz            float,
  sm            float,
  mx            float,  /* Mid Point */
  my            float,
  mz            float,
  mm            float,
  ex            float,  /* End Point */
  ey            float,
  ez            float,
  em            float,
  length        float,
  geom          geometry  /* Useful if vector is a circular arc */
)
AS
  /***
  *    p_start_id    (float) - Starting ID. @Vector table is indexed by a unique ID field.
  *                            That ID field normally starts at 1. But where a geometry object
  *                            contains multiple geometry types (eg GeometryCollection may contains line and polygon)
  *                            the function processes these sub objects by recursion. Where this happens, to ensure
  *                            ID values are sequential and unique the recursive call must provide the value of the 
  *                            ID at the time of the call.
  **/
Begin
  Declare
    @v_GeometryType varchar(1000),
    @v_isGeography  bit,
    @id             int,
    @vector         int,
    @subVector      int,
    @ringn          int,
    @numRings       int,
    @numPoints      int,
    @geomn          int,
    @first          int,
    @second         int,
    @line           geometry,
    @geom           geometry,
    @ring           geometry,
    @start_geom     geometry,
    @end_geom       geometry;
  Begin
    If ( @p_geometry is NULL ) 
      return;

    SET @v_GeometryType = @p_geometry.STGeometryType();

    If ( @v_GeometryType in ('Point','MultiPoint') ) 
      return;

    SET @v_isGeography = [$(owner)].[STIsGeographicSrid](@p_geometry.STSrid);
    SET @id            = ISNULL(@p_start_id,1);

    IF ( @v_GeometryType = 'LineString' )
    BEGIN
      SET @vector = 0;
      SET @first  = 1;
      SET @second = 2;
      WHILE ( @second <= @p_geometry.STNumPoints() )
      BEGIN
        SET @start_geom = @p_geometry.STPointN(@first);
        SET @first      = @first  + 1;
        SET @end_geom   = @p_geometry.STPointN(@second);
        SET @second     = @second + 1;
        SET @vector     = @vector + 1;
        IF ( @start_geom.STEquals(@end_geom) = 0 ) 
        BEGIN
          SET @line = [$(owner)].[STMakeLine](@start_geom, @end_geom,15,15);
          INSERT INTO @Vectors ( 
                   [id],[element_id],[subelement_id],[vector_id],
                   [sx],[sy],[sz],[sm],
                   [ex],[ey],[ez],[em],
                   [length],[geom]
          ) VALUES ( @id,
                   1,
                   0,
                   @vector,
                   @start_geom.STX,@start_geom.STY, @start_geom.Z,@start_geom.M,
                     @end_geom.STX,  @end_geom.STY,   @end_geom.Z,  @end_geom.M,
                   case when @v_isGeography=1
                        then geography::STGeomFromText(@line.AsTextZM(),@line.STSrid).STLength()
                        else @line.STLength()
                    end,
                   @line
          );
        END;
        SET @id = @id + 1;
      END;
      RETURN;
    END;

    IF ( @v_GeometryType = 'CircularString' )
    BEGIN
      SET @geomN  = 1;
      WHILE ( @geomN <= @p_geometry.STNumCurves() )
      BEGIN
        SET @geom   = @p_geometry.STCurveN(@geomN);
        SET @vector = @vector + 1;
        INSERT INTO @Vectors ( 
                   [id],[element_id],[subelement_id],[vector_id],
                   [sx],[sy],[sz],[sm],
                   [mx],[my],[mz],[mm],
                   [ex],[ey],[ez],[em],
                   [length],[geom]
        ) VALUES ( @id     /*            id */,
                   1       /*    element_id */,
                   @geomN  /* subelement_id */,
                   @id     /*     vector_id */,
                   @geom.STPointN(1).STX,@geom.STPointN(1).STY,@geom.STPointN(1).Z,@geom.STPointN(1).M,
                   @geom.STPointN(2).STX,@geom.STPointN(2).STY,@geom.STPointN(2).Z,@geom.STPointN(2).M,
                   @geom.STPointN(3).STX,@geom.STPointN(3).STY,@geom.STPointN(3).Z,@geom.STPointN(3).M,
                   case when @v_isGeography=1
                        then geography::STGeomFromText(@geom.AsTextZM(),@geom.STSrid).STLength()
                        else @geom.STLength()
                    end,
                   @geom);
        SET @geomN = @geomN + 1;
        SET @id    = @id    + 1;
      END;  
      RETURN;
    END;

    IF ( @v_GeometryType IN ('CompoundCurve') )
    BEGIN
      -- Made up of N x CircularCurves and M x LineStrings.
      SET @vector = 1;
      SET @geomN  = 1;
      WHILE ( @geomn <= @p_geometry.STNumCurves() )
      BEGIN
        SET @geom = @p_geometry.STCurveN(@geomN);
        INSERT INTO @Vectors ( 
                   [id],[element_id],[subelement_id],[vector_id],
                   [sx],[sy],[sz],[sm],
                   [mx],[my],[mz],[mm],
                   [ex],[ey],[ez],[em],
                   [length],[geom]
                   )
            SELECT @ID,
                   1   /* element_id */,
                   @geomN,
                   @vector,
                   [sx],[sy],[sz],[sm],
                   [mx],[my],[mz],[mm],
                   [ex],[ey],[ez],[em],
                   [length],[geom].MakeValid()
              FROM [$(owner)].[_STVectorize](@geom,@id);
        SET @id = @id + @@ROWCOUNT;  -- ROWCOUNT is surrogate for last [ID]
        SET @geomn  = @geomn + 1;
      END; 
      RETURN;
    END;

    IF ( @v_GeometryType = 'MultiLineString' ) 
    BEGIN
      SET @vector = 0;
      SET @geomn  = 1;
      WHILE ( @geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @geom      = @p_geometry.STGeometryN(@geomn);
        SET @first     = 1;
        SET @second    = 2;
        SET @subVector = 0;
        WHILE ( @second <= @geom.STNumPoints() )
        BEGIN
          SET @start_geom = @geom.STPointN(@first);
          SET @first      = @first  + 1;
          SET @end_geom   = @geom.STPointN(@second);
          SET @second     = @second + 1;
          SET @vector     = @vector + 1;
          SET @subVector  = @subVector + 1;
          IF ( @start_geom.STEquals(@end_geom) = 0 )
          BEGIN
            SET @line = [$(owner)].[STMakeLine](@start_geom,@end_geom,15,15);
            INSERT INTO @Vectors (
                     [id],
                     [element_id],
                     [subelement_id],
                     [vector_id],
                     [sx],[sy],[sz],[sm],
                     [ex],[ey],[ez],[em],
                     [length],[geom]
            ) VALUES (@id,
                     @geomn,
                     @ringn,
                     @subVector,
                     @start_geom.STX,@start_geom.STY, @start_geom.Z, @start_geom.M,
                       @end_geom.STX,  @end_geom.STY,   @end_geom.Z,   @end_geom.M,
                     case when @v_isGeography=1
                          then geography::STGeomFromText(@line.AsTextZM(),@line.STSrid).STLength()
                          else @line.STLength()
                      end,
                     @line
            );
          END;
          SET @id    = @id    + 1;
        END;
        SET @geomn = @geomn + 1;
      END; 
      RETURN;
    END;

    IF ( @v_GeometryType = 'Polygon' )
    BEGIN
      SET @vector   = 0;
      SET @ringn    = 1;
      SET @numRings = 1 /* Exterior Ring */ 
                      + 
                      @p_geometry.STNumInteriorRing();

      WHILE ( @ringn <= @numRings )
      BEGIN

        IF ( @ringn = 1 )
          SET @geom = @p_geometry.STExteriorRing()
        ELSE
          SET @geom = @p_geometry.STInteriorRingN(@ringn - 1);

        SET @first  = 1;
        SET @second = 2;
        SET @subVector = 0;
        WHILE ( @second <= @geom.STNumPoints() )
        BEGIN

          SET @start_geom = @geom.STPointN(@first);
          SET @end_geom   = @geom.STPointN(@second);
          SET @vector     = @vector + 1;
          SET @subVector  = @subVector + 1;
          IF ( @start_geom.STEquals(@end_geom) = 0 ) 
          BEGIN
            SET @line = [$(owner)].[STMakeLine](@start_geom, @end_geom,15,15);
            INSERT INTO @Vectors (
                     [id],
                     [element_id],
                     [subelement_id],
                     [vector_id],
                     [sx],[sy],[sz],[sm],
                     [ex],[ey],[ez],[em],
                     [length],[geom]
            ) VALUES ( @id,
                     1,
                     @ringn,
                     @subVector,
                     @start_geom.STX,@start_geom.STY, @start_geom.Z, @start_geom.M,
                       @end_geom.STX,  @end_geom.STY,   @end_geom.Z,   @end_geom.M,
                     case when @v_isGeography=1
                          then geography::STGeomFromText(@line.AsTextZM(),@line.STSrid).STLength()
                          else @line.STLength()
                      end,
                     @line
            );
          END;
          SET @first  = @first  + 1;
          SET @second = @second + 1;
          SET @id     = @id     + 1;
        END;
        SET @ringn = @ringn + 1;
      END; 
      RETURN;
    END;

    IF ( @v_GeometryType IN ('CurvePolygon') )
    BEGIN
      SET @ringn    = 1;
      SET @numRings = 1 /* Exterior Ring */ + @p_geometry.STNumInteriorRing();
      WHILE ( @ringn <= @numRings )
      BEGIN
        IF ( @ringn = 1 )
          SET @geom = @p_geometry.STExteriorRing()
        ELSE
          SET @geom = @p_geometry.STInteriorRingN(@ringn - 1);
        INSERT INTO @Vectors ( 
               [id],
               [element_id],
               [subelement_id],
               [vector_id],
               [sx],[sy],[sz],[sm],
               [mx],[my],[mz],[mm],
               [ex],[ey],[ez],[em],
               [length],[geom]
        )
        SELECT [id],
               1 /* element_id */,
               @ringN,
               [vector_id],
               [sx],[sy],[sz],[sm],
               [mx],[my],[mz],[mm],
               [ex],[ey],[ez],[em],
               [length],[geom]
          FROM [$(owner)].[_STVectorize](@geom,@id);
        SET @id     = @id + @@ROWCOUNT;  -- ROWCOUNT is surrogate for last [ID]
        SET @ringn  = @ringn + 1;
      END; 
      RETURN;
    END;

    IF ( @v_GeometryType = 'MultiPolygon' )
    BEGIN
      SET @geomn  = 1;
      WHILE ( @geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @geom     = @p_geometry.STGeometryN(@geomn);
        INSERT INTO @Vectors (
                    [id],
                    [element_id],
                    [subelement_id],
                    [vector_id],
                    [sx],[sy],[sz],[sm],
                    [mx],[my],[mz],[mm],
                    [ex],[ey],[ez],[em],
                    [length],[geom] )
             SELECT [ID],
                    @geomn   /* element_id */,
                    [subelement_id],
                    [vector_id],
                    [sx],[sy],[sz],[sm],
                    [mx],[my],[mz],[mm],
                    [ex],[ey],[ez],[em],
                    [length],[geom]
              FROM [$(owner)].[_STVectorize](@geom,@id);
         SET @id    = @id + @@ROWCOUNT;  -- ROWCOUNT is surrogate for last [ID]
         SET @geomn = @geomn + 1;
      END; 
      RETURN;
    END;
  
    IF ( @v_GeometryType = 'GeometryCollection' )
    BEGIN
      SET @geomn  = 1;
      WHILE ( @geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @geom = @p_geometry.STGeometryN(@geomn);      
        INSERT INTO @Vectors ( 
                    [id],
                    [element_id],
                    [subelement_id],
                    [vector_id],
                    [sx],[sy],[sz],[sm],
                    [mx],[my],[mz],[mm],
                    [ex],[ey],[ez],[em],
                    [length],[geom]
                   )
            SELECT [ID],
                   @geomN /* element_id */,
                   [subelement_id],
                   [vector_id],
                   [sx],[sy],[sz],[sm],
                   [mx],[my],[mz],[mm],
                   [ex],[ey],[ez],[em],
                   [length],[geom]
              FROM [$(owner)].[_STVectorize](@geom,@id);
        SET @id    = @id + @@ROWCOUNT;  -- ROWCOUNT is surrogate for last [ID]
        SET @geomn = @geomn + 1;
      END;
      RETURN;
    END;
  End;
  RETURN;
End
GO

PRINT 'Creating [$(owner)].[STVectorize] ...'
GO 

CREATE FUNCTION [$(owner)].[STVectorize]
(
  @p_geometry geometry
)
RETURNS @Vectors TABLE
(
  id            int,
  element_id    int,
  subelement_id int,
  vector_id     int, 
  sx            float,  /* Start Point */
  sy            float,
  sz            float,
  sm            float,
  mx            float,  /* Mid Point */
  my            float,
  mz            float,
  mm            float,
  ex            float,  /* End Point */
  ey            float,
  ez            float,
  em            float,
  length        float,
  geom          geometry  /* Useful if vector is a circular arc */
)
AS
/****f* GEOPROCESSING/STVectorize (2008)
 *  NAME
 *   STVectorize - Dumps all vertices of supplied geometry object to ordered array.
 *  SYNOPSIS
 *   Function STVectorize (
 *       @p_geometry  geometry 
 *    )
 *    Returns @Vector Table (
 *      id             int,
 *      element_id     int,
 *      subelement_id  int,
 *      vector_id      int,
 *      sx             float,  
 *      sy             float,
 *      sz             float,
 *      sm             float,
 *      mx             float,  
 *      my             float,
 *      mz             float,
 *      mm             float,
 *      ex             float, 
 *      ey             float,
 *      ez             float,
 *      em             float,
 *      length         float,
 *      geom           geometry
 *    )  
 *  EXAMPLE
 *    SELECT e.[id], e.[element_id], e.[subelement_id], e.[vector_id], 
 *           e.[sx], e.[sy], e.[ex], e.[ey], 
 *           e.length, geom.STAsText() as geomWKT
 *     FROM [$(owner)].[STVectorize] (geometry::STGeomFromText(
 *          'MULTIPOLYGON( ((200 200, 400 200, 400 400, 200 400, 200 200)),
 *                         ((0 0, 100 0, 100 100, 0 100, 0 0),(40 40,60 40,60 60,40 60,40 40)) )',0)) as e
 *    GO
 *    id element_id subelement_id vector_id sx  sy  ex  ey  length geomWKT
 *    -- ---------- ------------- --------- --  --  --  --  ------ -------
 *     1 1          1             1         200 200 400 200 200    LINESTRING (200 200, 400 200)
 *     2 1          1             2         400 200 400 400 200    LINESTRING (400 200, 400 400)
 *     3 1          1             3         400 400 200 400 200    LINESTRING (400 400, 200 400)
 *     4 1          1             4         200 400 200 200 200    LINESTRING (200 400, 200 200)
 *     5 2          1             1           0   0 100   0 100    LINESTRING (0 0, 100 0)
 *     6 2          1             2         100   0 100 100 100    LINESTRING (100 0, 100 100)
 *     7 2          1             3         100 100   0 100 100    LINESTRING (100 100, 0 100)
 *     8 2          1             4           0 100   0   0 100    LINESTRING (0 100, 0 0)
 *     9 2          2             1          40  40  60  40  20    LINESTRING (40 40, 60 40)
 *    10 2          2             2          60  40  60  60  20    LINESTRING (60 40, 60 60)
 *    11 2          2             3          60  60  40  60  20    LINESTRING (60 60, 40 60)
 *    12 2          2             4          40  60  40  40  20    LINESTRING (40 60, 40 40)
 *  DESCRIPTION
 *    This function segments the supplied geometry into 2-point linestrings or 3 point CircularStrings. 
 *    The returned data includes all the metadata about the segmented linestring:
 *    - Segment identifiers (ie from 1 through n);
 *    - Start/Mid/End Coordinates as ordinates;
 *    - Length of vector.
 *    - Geometry representation of segment.
 *  INPUTS
 *    @p_geometry (geometry) - Any non-point geometry object
 *  RESULT
 *    Table (Array) of Vectors:
 *     id             (int)      - Unique identifier starting at segment 1.
 *     element_id     (int)      - Top level element identifier eg 1 for first polygon in multiPolygon.
 *     subelement_id  (int)      - SubElement identifier of subelement of element with parts eg OuterRing of Polygon
 *     vector_id      (int)      - Unique identifier for all segments of a specific element.
 *     sx             (float)    - Start Point X Ordinate 
 *     sy             (float)    - Start Point Y Ordinate 
 *     sz             (float)    - Start Point Z Ordinate 
 *     sm             (float)    - Start Point M Ordinate
 *     mx             (float)    - Mid Point X Ordinate (Only if CircularString)
 *     my             (float)    - Mid Point Y Ordinate (Only if CircularString)
 *     mz             (float)    - Mid Point Z Ordinate (Only if CircularString)
 *     mm             (float)    - Mid Point M Ordinate (Only if CircularString)
 *     ex             (float)    - End Point X Ordinate 
 *     ey             (float)    - End Point Y Ordinate 
 *     ez             (float)    - End Point Z Ordinate 
 *     em             (float)    - End Point M Ordinate 
 *     length         (float)    - Length of this segment in SRID units
 *     geom           (geometry) - Geometry representation of segment.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2008, Original Coding; January 2017 - Support for Circular Curve objects and subobjects.
 *  COPYRIGHT
 *    (c) 2008-2017 by TheSpatialDBAdvisor/Simon Greener
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  INSERT INTO @Vectors ( 
          [id],
          [element_id],
          [subelement_id],
          [vector_id],
          [sx],[sy],[sz],[sm],
          [mx],[my],[mz],[mm],
          [ex],[ey],[ez],[em],
          [length],[geom]
   )
   SELECT [id],
          [element_id],
          [subelement_id],
          [vector_id],
          [sx],[sy],[sz],[sm],
          [mx],[my],[mz],[mm],
          [ex],[ey],[ez],[em],
          [length],[geom]
     FROM [$(owner)].[_STVectorize](@p_geometry,1);
  Return;
END
GO

PRINT 'Testing .....';
GO


select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE EMPTY',0)) as v;
go
  
select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('LINESTRING(0 0,5 5)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('LINESTRING(0 0,5 5,10 10,15 15,20 20)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10),(11 11, 12 12))',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5, 10 -10,15 -15)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CIRCULARSTRING(0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0)',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE((3 5, 3 3), CIRCULARSTRING(3 3, 5 1, 7 3), (7 3, 7 5), CIRCULARSTRING(7 5, 5 7, 3 5))',0)) as v;
go

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE ((4 4, 3 3, 2 2, 0 0),CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0))',0)) as v;
GO

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(7 5 4 2, 5 7 4 2, 3 5 4 2), (3 5 4 2, 8 7 4 2))',0)) as v;
GO

select v.* 
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246), CIRCULARSTRING(3 6.3246, 0 7, -3 6.3246), CIRCULARSTRING(-3 6.3246, -1 2.1082, 0 0))',0)) as v;
GO
  
select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))',0)) as v;
GO

select v.*, v.geom.STBuffer(1) as vector
  from [$(owner)].[STVectorize](geometry::STGeomFromText('POLYGON ((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as v;
GO

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

select v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80),(85 85, 100 85, 90 90, 85 90, 85 85)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

select v.* 
  from [$(owner)].[STVectorize](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0)) as v;
GO

-- Single CurvePolygon with one interior ring
select  v.*, v.geom.STBuffer(1)
  from [$(owner)].[STVectorize](geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 5, 5 0, 0 -5, -5 0, 0 5), (-2 2, 2 2, 2 -2, -2 -2, -2 2))',0)) as v;
GO

-- GeometryCollection
select  v.*
  from [$(owner)].[STVectorize](geometry::STGeomFromText(
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
                          (0 -23.43778, 0 23.43778)))',0)) as v;
GO


