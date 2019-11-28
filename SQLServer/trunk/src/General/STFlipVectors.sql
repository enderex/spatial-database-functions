SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STFlipVectors]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STFlipVectors];
  Print 'Dropped [$(owner)].[STFlipVectors] ...';
END;
GO

PRINT 'Creating [$(owner)].[STFlipVectors] ...'
GO

CREATE FUNCTION [$(owner)].[STFlipVectors] (
  @p_line_collection geometry
)
RETURNS geometry
AS
/****f* GEOPROCESSING/STFlipVectors (2008)
 *  NAME
 *    STFlipVectors - Turns linestring and polygon rings into vectors and then flips each vector until all point in the same direction.
 *  SYNOPSIS
 *    Function STFlipVectors (
 *       @p_geometry geometry
 *    )
 *     Returns geometry
 *  EXAMPLE
 *    With gc As (
 *    select geometry::STGeomFromText(
 *    'GEOMETRYCOLLECTION(
 *    POLYGON((10 0,20 0,20 20,10 20,10 0)),
 *    POLYGON((20 0,30 0,30 20,20 20,20 0)),
 *    POINT(0 0))',0) as geom
 *    )
 *    select v.sx,v.sy,v.ex,v.ey,count(*)
 *      from gc as a
 *           cross apply
 *           [$(owner)].[STVectorize] (
 *             [$(owner)].[STFlipVectors] ( a.geom )
 *           ) as v
 *     group by v.sx,v.sy,v.ex,v.ey
 *    go
 *  DESCRIPTION
 *    This function extracts all vectors from supplied linestring/polygon rings, and then flips each vector until all point in the same direction.
 *    This function is useful for such operations as finding "slivers" between two polygons that are supposed to share a boundary.
 *    Once the function has flipped the vectors the calling function can analyse the vectors to do things like find duplicate segment
 *    which are part of a shared boundaries that are exactly the same (no sliver).
 *  INPUTS
 *    @p_geometry (geometry) - Any geometry containing linestrings.
 *  RETURN
 *    geometry (GeometryCollection) - The set of flipped vectors.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE 
    @v_flipped_segments geometry;

  IF ( @p_line_collection is null )
    Return geometry::STGeomFromText('LINESTRING EMPTY',@p_line_collection.STSrid);

  IF ( @p_line_collection.STGeometryType() IN ('Point','MultiPoint') )
    Return geometry::STGeomFromText('LINESTRING EMPTY',@p_line_collection.STSrid);


  -- Reorder The Vectors of the input line collection (can be multiPolygon/Polygon/LineString/MultiLineString
  select @v_flipped_segments = 
         geometry::CollectionAggregate(
             [$(owner)].[STMakeLine] (
                      geometry::Point(D.Start_X,D.Start_Y,@p_line_collection.STSrid),
                      geometry::Point(D.End_X,D.End_Y,    @p_line_collection.STSrid),
                      15,
                      15)
              )
    from (select Case When C.SX <= C.EX Then C.SX Else C.EX End As Start_X,
                 Case When C.SX <= C.EX Then C.EX Else C.SX End As End_X,
                 Case When C.SX <  C.EX Then C.SY 
                      Else Case When C.SX = C.EX 
                                Then case when C.EY < C.SY then C.EY Else C.SY end
                                Else C.EY 
                            End
                  End As Start_Y,
                 case when C.SX < C.EX then C.EY 
                      Else Case When C.SX = C.EX 
                                Then case when C.EY < C.SY then C.SY Else C.EY end
                                ELSE c.SY 
                            END
                  End As End_Y
            from [$(owner)].[STVectorize] ( @p_line_collection ) as c
         ) as D;
  RETURN @v_flipped_segments;
END;
GO

