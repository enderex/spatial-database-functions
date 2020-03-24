SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STSquareBuffer]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STSquareBuffer];
  PRINT 'Dropped [$(owner)].[STSquareBuffer] ...';
END;
GO

PRINT 'Creating [$(owner)].[STSquareBuffer] ...';
GO

CREATE FUNCTION [$(owner)].[STSquareBuffer]
(
  @p_linestring      geometry,
  @p_buffer_distance Float, 
  @p_round_xy        int = 3,
  @p_round_zm        int = 2
)
Returns geometry 
AS
/****m* GEOPROCESSING/STSquareBuffer (2012)
 *  NAME
 *    STSquareBuffer -- Creates a square buffer to left or right of a linestring.
 *  SYNOPSIS
 *    Function STSquareBuffer (
 *               @p_linestring      geometry,
 *               @p_buffer_distance Float, 
 *               @p_round_xy        int = 3,
 *               @p_round_zm        int = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function buffers a linestring creating a square mitre at the end where a normal buffer creates a round mitre.
 *    A value of 0 will create a rounded end at the start or end point.
 *    Where the linestring either crosses itself or starts and ends at the same point, the result may not be as expected.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision.
 *  NOTES
 *    Supports circular strings and compoundCurves.
 *  INPUTS
 *    p_linestring (geometry) - Must be a linestring geometry.
 *    p_distance   (float)    - Buffer distance.
 *    p_round_xy   (int)      - Rounding factor for XY ordinates.
 *    p_round_zm   (int)      - Rounding factor for ZM ordinates.
 *  RESULT
 *    polygon      (geometry) - Result of square buffering a linestring.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding (Oracle).
 *    Simon Greener - Nov 2017 - Original coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
******/
BEGIN
  DECLARE
    @v_determine         varchar(max),
    @v_GeometryType      varchar(100),
    @v_round_xy          int,
    @v_round_zm          int,
    @v_GeomN             int,
    @v_numGeoms          int,
    @v_sBearing          float,
    @v_eBearing          float,

    @v_buffer_distance   float,
    @v_buffer_increment  float,
    @v_line_extension_distance float,

    @v_shortest_line_to  geometry,
    @v_line_remove       geometry,
    @v_linestring        geometry,
    @v_start_linestring  geometry,
    @v_end_linestring    geometry,
    @v_start_point       geometry,
    @v_end_point         geometry,
    @v_start_extension   geometry,
    @v_end_extension     geometry,
    @v_point             geometry,
    @v_centre_of_circle  geometry,
    @v_nGeom             geometry,
    @v_split_lines       geometry,
    @v_split_geom        geometry,
    @v_side_geom         geometry,
    @v_buffer_ring       geometry,
    @v_buffer            geometry;

  If ( @p_linestring is null )
    return @p_linestring;

  If ( ISNULL(ABS(@p_buffer_distance),0.0) = 0.0 )
    return @p_linestring;

  SET @v_GeometryType = @p_linestring.STGeometryType();
  -- MultiLineString Supported by alternate processing.
  IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
    return @p_linestring;

  SET @v_round_xy                = ABS(ISNULL(@p_round_xy,3));
  SET @v_round_zm                = ABS(ISNULL(@p_round_zm,2));
  SET @v_buffer_distance         = ABS(@p_buffer_distance);
  SET @v_buffer_increment        = 1.0/POWER(10,@v_round_xy-1);
  SET @v_line_extension_distance = 1.0/POWER(10,@v_round_xy+1) * 2.0;

  -- We only support 2D 
  IF ( [$(owner)].[STCoordDim](@p_linestring.STStartPoint()) > 2 )
   SET @v_linestring = [$(owner)].[STTo2D](@p_linestring)
  ELSE 
   SET @v_linestring = @p_linestring;

  -- #############################################################################################

  -- LinearRing
  -- 
  IF ( @v_linestring.STStartPoint().STEquals(@v_linestring.STEndPoint())=1
    OR [$(owner)].[STEquals] ( 
             @v_linestring.STStartPoint(),
             @v_linestring.STEndPoint(),
             @v_round_xy,
             @v_round_zm,
             @v_round_zm ) = 1 )
  BEGIN
    return @p_linestring.STBuffer(@v_buffer_distance);
  END;

  -- #######################################################################################

  SET @v_buffer      = @v_linestring.STBuffer(@v_buffer_distance);

  SET @v_buffer_ring = @v_buffer.STExteriorRing();

  -- #############################################################################################

  -- Get linestring with disappearing start/segments removed.
  --
  WITH segments as (
    SELECT s.id, 
           s.element_tag,
           s.geom as segment
      FROM [$(owner)].[STSegmentLine](@v_linestring) as s
  ), ids as (
    SELECT MIN(id) as minId, 
           MAX(id) as maxId
      FROM (SELECT /* original Line as offset segments */
                   s.[id],
                   case when s.element_tag = 'CIRCULARSTRING'
                        then 0.0
                        else ROUND([$(owner)].[STOffsetSegment] (
                               s.segment,
                               @v_buffer_distance,
                               @p_round_xy,
                               @p_round_zm
                             ).ShortestLineTo(@v_buffer_ring)
                              .STLength(),
                             @p_round_xy
                             )
                        end as Dist2Boundary
                 FROM segments s
             ) as f
       WHERE f.Dist2Boundary <= 1.0/POWER(10,@p_round_xy-1)
    )
    SELECT @v_start_linestring = mins.line,
           @v_end_linestring   = maxs.line
      FROM (SELECT s.segment as line FROM ids as i INNER JOIN segments as s ON (s.id = i.minId) WHERE s.id = i.minId) as mins,
           (SELECT s.segment as line FROM ids as i INNER JOIN segments as s ON (s.id = i.maxId) WHERE s.id = i.maxId) as maxs;

  -- #######################################################################################

  IF ( @v_start_linestring.STGeometryType() = 'CircularString' )
    SET @v_start_linestring = [$(owner)].[STCircularStringN](@v_start_linestring,1);

  IF ( @v_end_linestring.STGeometryType() = 'CircularString' )
      SET @v_end_linestring = [$(owner)].[STCircularStringN](
                                  @v_end_linestring,
                                  [$(owner)].[STNumCircularStrings](@v_end_linestring)
                              );  

  IF ( @v_start_linestring.STGeometryType() = 'LineString' )
    SET @v_start_linestring = [$(owner)].[STMakeLine](
                                    @v_start_linestring.STPointN(1),
                                    @v_start_linestring.STPointN(2),
                                    @v_round_xy,@v_round_zm
                                );
  IF ( @v_end_linestring.STGeometryType() = 'LineString' )
    SET @v_end_linestring = [$(owner)].[STMakeLine](
                               @v_linestring.STPointN(@v_linestring.STNumPoints()-1),
                               @v_linestring.STPointN(@v_linestring.STNumPoints()),
                               @v_round_xy,@v_round_zm
                            );

  -- #######################################################################################

  -- Start of LineString
  --
  -- Create splitting lines at either end at 90 degrees to line direction.
  -- 
  IF ( @v_start_linestring.STGeometryType() = 'LineString' ) 
  BEGIN
    SET @v_sBearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingAlongLine] (@v_start_linestring)
                         + 
                         90.0
                      );
  END;

  IF ( @v_start_linestring.STGeometryType() = 'CircularString') 
  BEGIN
    -- Compute curve center
    SET @v_centre_of_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_start_linestring );
    -- Is collinear?
    IF ( @v_centre_of_circle.STStartPoint().STX = -1 
     and @v_centre_of_circle.STStartPoint().STY = -1 
     and @v_centre_of_circle.STStartPoint().Z   = -1 )
      return @v_buffer;
    -- Line from centre to @v_start_point is at a tangent (90 degrees) to arc "direction" 
    -- Compute bearing
    -- 
    SET @v_sBearing = [$(cogoowner)].[STBearingBetweenPoints] (
                          @v_start_linestring.STStartPoint(),
                          @v_centre_of_circle
                       );
  END;

  -- COMMON 
  --
  -- Create start offset split line
  --
  SET @v_start_point     = [$(cogoowner)].[STPointFromCOGO] (
                              /* @p_start_point */ @v_start_linestring.STStartPoint(),
                              /* @p_dBearing    */ @v_sBearing,
                              /* @p_dDistance   */ @v_buffer_distance + @v_line_extension_distance,
                              /* @p_round_xy    */ @v_round_xy 
                           );

  SET @v_end_point     = [$(cogoowner)].[STPointFromCOGO] (
                            /* @p_start_point */ @v_start_linestring.STStartPoint(),
                            /* @p_dBearing    */ [$(cogoowner)].[STNormalizeBearing] ( @v_sBearing + 180.0 ),
                            /* @p_dDistance   */ @v_buffer_distance + @v_line_extension_distance,
                            /* @p_round_xy    */ @v_round_xy 
                         );

  SET @v_start_extension = [$(owner)].[STMakeLine] (@v_start_point,@v_end_point,@v_round_xy,@v_round_zm);

  -- #######################################################################################

  -- End of LineString

  IF ( @v_end_linestring.STGeometryType() = 'LineString')  
  BEGIN
    SET @v_eBearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingAlongLine] (@v_end_linestring)
                         +
                         90.0
                       );
  END;

  IF ( @v_end_linestring.STGeometryType() = 'CircularString' ) 
  BEGIN
    -- Compute curve center
    SET @v_centre_of_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_end_linestring );
    -- Is collinear?
    IF ( @v_centre_of_circle.STStartPoint().STX = -1
     and @v_centre_of_circle.STStartPoint().STY = -1 
     and @v_centre_of_circle.STStartPoint().Z   = -1 )
      return @v_buffer;
    -- Line from centre to v_end_point is at a tangent (90 degrees) to arc "direction" 
    -- Compute bearing
    -- 
    SET @v_eBearing = [$(cogoowner)].[STBearingBetweenPoints] (
                          @v_end_linestring.STEndPoint(),
                          @v_centre_of_circle
                      );
  END;

  -- COMMON

  -- Create end offset right angled split line

  SET @v_start_point   = [$(cogoowner)].[STPointFromCOGO] (
                            /* @p_start_point */ @v_end_linestring.STEndPoint(),
                            /* @p_dBearing    */ @v_eBearing,
                            /* @p_dDistance   */ @v_buffer_distance + @v_line_extension_distance,
                            /* @p_round_xy    */ @v_round_xy 
                         );

  SET @v_end_point     = [$(cogoowner)].[STPointFromCOGO] (
                            /* @p_start_point */ @v_end_linestring.STEndPoint(),
                            /* @p_dBearing    */ [$(cogoowner)].[STNormalizeBearing] ( @v_eBearing + 180.0 ),
                            /* @p_dDistance   */ @v_buffer_distance + @v_line_extension_distance,
                            /* @p_round_xy    */ @v_round_xy 
                         );

  SET @v_end_extension = [$(owner)].[STMakeLine] (@v_start_point,@v_end_point,@v_round_xy,@v_round_zm);

  -- ################################################################################################# 

  -- Now, split buffer with modified linestrings (using buffer trick) to split buffer in to polygons
  SET @v_split_geom  =  @v_buffer.STDifference(@v_start_extension.STBuffer(@v_buffer_increment))
                                 .STDifference(  @v_end_extension.STBuffer(@v_buffer_increment));

  -- Find out which polygon is the one we want.
  --
  SET @v_point = [$(owner)].[STOffsetPoint] (
                    @v_start_linestring,
                    0.5, /* @p_ratio */
                    0.0, /* @p_offset */
                    @v_round_xy,
                    @v_round_zm,
                    @v_round_zm
                 );

  -- Now find polygon that is around the actual line
  SET @v_GeomN    = 1;
  SET @v_numGeoms = @v_split_geom.STNumGeometries();
  WHILE ( @v_GeomN <= @v_numGeoms )
  BEGIN
    SET @v_nGeom     = @v_split_geom.STGeometryN(@v_GeomN);
    IF ( @v_nGeom.STContains(@v_point) = 1 )
    BEGIN
      SET @v_side_geom = @v_nGeom;
      BREAK;
    END;
    SET @v_GeomN = @v_GeomN + 1;
  END;

  -- STRound removes @v_buffer_increment sliver trick that would otherwise be left behind in the data.
  SET @v_side_geom = [$(owner)].[STRound] ( 
                         @v_side_geom,
                         @v_round_xy,
                         @v_round_xy,
                         @v_round_zm,
                         @v_round_zm
                     ).MakeValid();

  return @v_side_geom;
End;
GO



