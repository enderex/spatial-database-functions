SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STCollectionAppend]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(Owner)].[STCollectionAppend]
  PRINT 'Dropped [$(owner)].[STCollectionAppend] ...';
END;
GO

/* *************************** FUNCTIONS ************************************* */

Print 'Creating [$(owner)].[STCollectionAppend] ...';
GO

CREATE FUNCTION [$(owner)].[STCollectionAppend]
(
  @p_collection geometry,
  @p_geometry   geometry,
  @p_position   integer = 0
)
returns geometry 
as
/****m* EDITOR/STCollectionAppend (2012)
 *  NAME
 *    STCollectionAppend -- Appends geometry to end of the geometry collection.
 *  SYNOPSIS 
 *    Function [$(owner)].[STCollectionAppend] (
 *               @p_collection geometry,
 *               @p_geometry   geometry,
 *               @p_position   integer
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    While the geometry::CollectionAggregate does the same as this, 
 *    adding geometry objects to a GeometryCollection in a more programmatic environment.
 *    Normally, the first parameter, @p_collection should be a GeometryCollection,
 *    If it is not, the function converts it to a GeometryCollection.
 *    The second parameter should be a single geometry eg Polygon, LineString, Point.
 *    If it is a GeometryCollection all its elements are appended. 
 *    Both parameters must have the same SRID and coordinate dimensionality ie XY, XYZ etc
 *    The @p_position parameter indicates whether @p_geometry should be added to the beginning (0)
 *    or end (1) of @p_collection
 *  INPUTS
 *    @p_collection (geometry) - Normally a GeometryCollection.
 *    @p_geometry   (geometry) - Normally a single geometry object.
 *    @p_position   (Integer)  - Write at start (0) or end (1)
 *  RESULT
 *    Appended collection  (geometry) - New GeometryCollection with geometry appended
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - March 2020 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2020 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_GeometryType1 varchar(100),
    @v_GeometryType2 varchar(100),
    @v_Dimensions    varchar(4),
    @v_Dimensions2   varchar(4),
    @v_position      integer,
    @v_i             integer,
    @v_s_temp        varchar(max),
    @v_wkt           varchar(max),
    @v_1_wkt         varchar(max),
    @v_2_wkt         varchar(max),
    @v_geometry      geometry;
  BEGIN
    If ( @p_collection is null and @p_geometry is null )
      Return NULL;

    If ( @p_collection is not null and @p_geometry is null )
      Return @p_collection;

    If ( @p_collection is not null and @p_geometry is null )
      Return @p_collection;

    IF ( @p_geometry is not null AND @p_geometry.STIsValid()=0 )
      RETURN @p_collection;

    IF ( @p_collection is null and @p_geometry is not null )
    BEGIN
      SET @v_wkt = 'GEOMETRYCOLLECTION(' 
                   +
                   @p_geometry.AsTextZM()
                   +
                   ')';
      Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    END;

    If ( @p_collection.STSrid<>@p_geometry.STSrid )
      Return @p_collection;

    -- Check dimensions
    SET @v_dimensions = 'XY' 
                        + case when @p_collection.HasZ=1 then 'Z' else '' end +
                        + case when @p_collection.HasM=1 then 'M' else '' end ;
    SET @v_dimensions2 = 'XY' 
                         + case when @p_geometry.HasZ=1 then 'Z' else '' end +
                         + case when @p_geometry.HasM=1 then 'M' else '' end ;
    IF ( @v_dimensions <> @v_Dimensions2 )
      Return @p_collection;

    SET @v_position = case when ISNULL(@p_position,0) in (0,1) then ISNULL(@p_position,0) else 0 end;

    SET @v_GeometryType1 = @p_collection.STGeometryType();
    IF (@v_GeometryType1 <> 'GeometryCollection') 
    Begin
      SET @v_1_wkt = @p_collection.AsTextZM();
    END
    ELSE
    BEGIN
      SET @v_s_temp = @p_collection.AsTextZM();
      SET @v_1_wkt = SUBSTRING(@v_s_temp,
                               CHARINDEX('(',@v_s_temp)+1,
                               LEN(@v_s_temp)-CHARINDEX('(',@v_s_temp)-1
                     );
    END;

    -- Same again for @p_geonmetry_2
    SET @v_GeometryType2 = @p_geometry.STGeometryType();
    SET @v_geometry      = @p_geometry;

    IF (@v_GeometryType2 <> 'GeometryCollection') 
    Begin
      SET @v_2_wkt = @p_geometry.AsTextZM();
    END
    ELSE
    BEGIN
      SET @v_s_temp = @p_geometry.AsTextZM();
      SET @v_2_wkt = SUBSTRING(@v_s_temp,
                               CHARINDEX('(',@v_s_temp)+1,
                               LEN(@v_s_temp)-CHARINDEX('(',@v_s_temp)-1
                     );
    END;

    -- Append and return
    --
    IF ( @v_position = 0 )
      SET @v_wkt = 'GEOMETRYCOLLECTION('+@v_2_wkt+','+@v_1_wkt+')'
    ELSE
      SET @v_wkt = 'GEOMETRYCOLLECTION('+@v_1_wkt+','+@v_2_wkt+')';

    -- Return geometry
    Return geometry::STGeomFromText(@v_wkt,@p_collection.STSrid);
  End;
END
GO

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('POINT(0 0)',0),
  geometry::STGeomFromText('POINT(1 1)',0),
  1
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('POINT(1 1)',0),
  1
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  NULL,
  geometry::STGeomFromText('POINT(1 1)',0),
  0
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('LINESTRING EMPTY',0),
  geometry::STGeomFromText('POINT(1 1)',0),
  0
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('POINT(1 1)',0),
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  0
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('LINESTRING(0 0,1 1)',0),
  1
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('POLYGON((0 0,1 0,1 1,0 1,0 0))',0),
  0
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('POLYGON((0 0,1 1,1 0,0 1,0 0))',0),
  0
).AsTextZM();

select [$(owner)].[STCollectionAppend](
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0))',0),
  geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(1 1),LINESTRING(1 1,2 2))',0),
  1
).AsTextZM();

