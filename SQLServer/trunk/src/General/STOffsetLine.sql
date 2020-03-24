SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: COGO=$(cogoowner) owner=$(owner)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STOffsetLine]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STOffsetLine];
  PRINT 'Dropped [$(owner)].[STOffsetLine] ...';
END;
GO

PRINT 'Creating [$(owner)].[STOffsetLine] ...';
GO

CREATE FUNCTION [$(owner)].[STOffsetLine]
(
  @p_linestring geometry,
  @p_distance   Float, /* -ve is left and +ve is right */
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns geometry 
AS
/****f* GEOPROCESSING/STOffsetLine (2012)
 *  NAME
 *    STOffsetLine -- Creates a line at a fixed offset from the input line.
 *  SYNOPSIS
 *    Function [$(owner)].[STOffsetLine] (
 *               @p_linestring geometry,
 *               @p_distance   float, 
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a parallel line at a fixed offset to the supplied line.
 *    Supports simple linestrings and multilinestrings.
 *    To create a line on the LEFT of the linestring (direction start to end) supply a negative p_distance; 
 *    a +ve value will create a line on the right side of the linestring.
 *    Where the linestring either crosses itself or starts and ends at the same point, the result may not be as expected.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision.
 *    Support M ordinates is experimental: where supported the final geometry has its M ordinates rounded to @p_round_zm of precision.
 *  NOTES
 *    Does not currently support circular strings or compoundCurves.
 *    Uses STOneSidedBuffer.
 *    Z and M ordinates are not supported and where exist will be removed.
 *  INPUTS
 *    @p_linestring (geometry) - Must be a (Multi)linestring geometry.
 *    @p_distance   (float)    - if < 0 then linestring is created on left side of original; if > 0 then offset linestring it to right side of original.
 *    @p_round_xy   (int)      - Rounding factor for XY ordinates.
 *    @p_round_zm   (int)      - Rounding factor for ZM ordinates.
 *  RESULT
 *    linestring    (geometry) - On left or right side of supplied line at required distance.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding (Oracle).
 *    Simon Greener - Nov 2017 - Original coding for SQL Server.
 *    Simon Greener - Oct 2019 - Large scale rewrite. Rename from STParallel to STOffsetLine.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
******/
BEGIN
  DECLARE
    @v_GeometryType      varchar(100),
    @v_round_xy          int,
    @v_round_zm          int,
    @v_isCCW             bit,
    @v_is_collinear      bit,
    @v_nGeom             int,
    @v_geomN             geometry,
    @v_ccw_linestring    geometry,
    @v_interior_rings    geometry,
    @v_exterior_rings    geometry,
    @v_linestring        geometry,
    @v_linestring_buffer geometry,
    @v_side_buffer       geometry,
    @v_result_geom       geometry;
  Begin
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_linestring.STIsValid() = 0 ) 
      Return @p_linestring;

    If ( ISNULL(ABS(@p_distance),0.0) = 0.0 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType NOT IN ('LineString','MultiLineString') ) -- 'CompoundCurve','CircularString' ) )
      Return @p_linestring;

    SET @v_round_xy   = ISNULL(@p_round_xy,3);
    SET @v_round_zm   = ISNULL(@p_round_zm,2);

    SET @v_nGeom = 1;
    WHILE (@v_nGeom <= @p_linestring.STNumGeometries() ) 
    BEGIN
      -- Get simple LinearRing.
      --
      SET @v_geomN = @p_linestring.STGeometryN(@v_nGeom)

      -- Check for simplicity
      --
      IF ( @v_geomN.STNumPoints() = 2 )
      BEGIN
        SET @v_linestring = [$(owner)].[STOffsetSegment] ( 
                                  @v_geomN,
                                  @p_distance,
                                  @v_round_xy,
                                  @v_round_zm
                               )
        IF ( @v_result_geom is null )
          SET @v_result_Geom = @v_linestring
        ELSE
          SET @v_result_geom = @v_result_geom.STUnion(@v_linestring);
        SET @v_nGeom = @v_nGeom + 1;
        CONTINUE;
      END;

      -- TOBEDONE: Fix collinear threshold value
      IF ( [$(owner)].[STIsCollinear] ( @v_geomN,0.00001 ) = 1 )
      BEGIN
        SELECT @v_linestring = geometry::CollectionAggregate(
                                 [$(owner)].[STOffsetSegment] ( 
                                   v.geom,
                                   @p_distance,
                                   @v_round_xy,
                                   @v_round_zm
                                 )
                               )
          FROM [$(owner)].[STVectorize] ( @v_geomN ) as v;
        SET @v_linestring = [$(owner)].[STMakeLineFromGeometryCollection] (
                              @v_linestring,
                              @v_round_xy,
                              @v_round_zm
                            );
        IF ( @v_result_geom is null )
          SET @v_result_Geom = @v_linestring
        ELSE
          SET @v_result_geom = @v_result_geom.STUnion(@v_linestring);
        SET @v_nGeom = @v_nGeom + 1;
        CONTINUE;
      END;

      SET @v_ccw_linestring = [$(owner)].[STInsertN] (
                                 @v_geomN,
                                 @v_geomN.STStartPoint(),
                                 -1 /* Append at End */,
                                 @v_round_xy,
                                 @v_round_zm
                              );
      SET @v_isCCW = [$(owner)].[STisCCW] ( @v_ccw_linestring );

      -- If LinearRing then do not modify it
      SET @v_linestring = CASE WHEN ( @v_geomN.STStartPoint().STEquals(@v_geomN.STEndPoint()) = 1 )
                               THEN @v_geomN
                               ELSE [$(owner)].[STRemoveOffsetSegments] (
                                      @v_geomN.CurveToLineWithTolerance ( 0.5, 1 ),
                                      @p_distance,
                                      @v_round_xy, 
                                      @v_round_zm 
                                    )
                            END;

      IF ( @v_linestring.STNumPoints() = 2 ) 
      BEGIN
        SET @v_linestring = [$(owner)].[STOffsetSegment] ( 
                                  @v_linestring,
                                  @p_distance,
                                  @v_round_xy,
                                  @v_round_zm
                               );
        IF ( @v_result_geom is null )
          SET @v_result_Geom = @v_linestring
        ELSE
          SET @v_result_geom = @v_result_geom.STUnion(@v_linestring);
        SET @v_nGeom = @v_nGeom + 1;
        CONTINUE;
      END;

      SET @v_linestring = [$(owner)].[STRound] ( 
                             @v_linestring, 
                             @v_round_xy, 
                             @v_round_xy, 
                             @v_round_zm,
                             @v_round_zm 
                          );

      -- STOneSidedBuffer rounds ordinates of its result
      SET @v_side_buffer = [$(owner)].[STOneSidedBuffer] ( 
                              /* @p_linestring      */ @v_linestring, 
                              /* @p_buffer)distance */ @p_distance, 
                              /* @p_square          */ 1, 
                              /* @p_round           */ @v_round_xy, 
                              /* @p_round_zm        */ @v_round_zm 
                           ).CurveToLineWithTolerance ( 0.5, 1 );

      -- Inner rings are always part of offset line. 
      SELECT @v_interior_rings = geometry::UnionAggregate(f.eGeom)
       FROM (SELECT v.geom.STExteriorRing() as eGeom
               FROM [$(owner)].[STExtract](@v_side_buffer,1) as v
              WHERE v.sid <> 1 /* Interior ring */
             ) as f;

      -- Because we are processing a single linestring we will only get a single polygon back
      -- But in case
      IF ( @v_side_buffer.STGeometryType() = 'Polygon' )
        SET @v_exterior_rings = @v_side_buffer.STExteriorRing()
      ELSE
        SELECT @v_exterior_rings = geometry::UnionAggregate(f.eGeom)
         FROM (SELECT v.geom.STExteriorRing() as eGeom
                  FROM [$(owner)].[STExtract](@v_side_buffer,1) as v
                  WHERE v.sid = 1 /* Exterior rings */
                ) as f;

       -- Remove original line and any artifaces created in STOneSidedBuffer
       SET @v_linestring_buffer = [$(owner)].[STRound] (
                                       @v_linestring.STBuffer(ROUND(1.0/POWER(10,@v_round_xy-1),@v_round_xy+1)),
                                       @v_round_xy+2,
                                       @v_round_xy+2,
                                       @v_round_zm,
                                       @v_round_zm 
                                  );
         
       SELECT @v_result_geom =  [$(owner)].[STMakeLineFromMultiPoint] (
                geometry::STGeomFromText('MULTIPOINT (' + STRING_AGG(REPLACE(geometry::Point(g.x,g.y,0).STAsText(),'POINT ',''),',' ) WITHIN GROUP (ORDER BY g.uid ASC) + ')',0)
              )
         FROM (SELECT d1.uid, d1.x, d1.y
                 FROM [$(owner)].[STVertices](@v_side_buffer) as d1
               EXCEPT
               SELECT d1.uid, d1.x, d1.y
                 FROM [$(owner)].[STVertices](/* Exterior ring */ @v_exterior_rings) as d1
                WHERE d1.point.STIntersects(@v_linestring_buffer) = 1
             ) g;

      -- Check and fix rotation.
      -- STOneSidedBuffer creates polygon that has CCW rotation for Exterior Ring and CW for Interior ring.
      -- May be different from original linestring.
      -- 1. ExteriorRing
      IF ( @v_isCCW <> 1 )
        SET @v_result_geom = [$(owner)].[STReverse] ( 
                               @v_result_geom, 
                               @v_round_xy, 
                               @v_round_zm 
                             );

      -- 2. InteriorRings
      IF ( @v_isCCW = 1 AND @v_interior_rings is not null and @v_interior_rings.STNumPoints() > 0 )
        SET @v_result_geom = @v_result_geom.STUnion(
                               [$(owner)].[STReverse] ( 
                                 @v_interior_rings, 
                                 @v_round_xy, 
                                 @v_round_zm 
                               )
                             );

      SET @v_nGeom = @v_nGeom + 1;
     END; /* While Loop */
     Return @v_result_geom;
  END;
END;
GO

