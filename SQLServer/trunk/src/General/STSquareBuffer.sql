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
/****f* GEOPROCESSING/STSquareBuffer (2012)
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
 *    Support for Z and M ordinates is experimental: where supported the final geometry has its ZM ordinates rounded to @p_round_zm of precision.
 *     -- Simple Linestring
 *     with data as (
 *     select geometry::STGeomFromText('LINESTRING(0 0,5 0,5 10)',0) as linestring
 *     )
 *     select [$(owner)].[STSquareBuffer](a.linestring,-5.0,3,2).AsTextZM() as sqBuff from data as a
 *     GO
 *     sqBuff
 *     ---------------------------------------------
 *     POLYGON ((0 -15, 10 -15, 10 15, 0 15, 0 -15))
 *  NOTES
 *    Supports circular strings and compoundCurves.
 *  INPUTS
 *    @p_linestring (geometry) - Must be a linestring geometry.
 *    @p_distance      (float) - Buffer distance.
 *    @p_round_xy        (int) - Rounding factor for XY ordinates.
 *    @p_round_zm        (int) - Rounding factor for ZM ordinates.
 *  RESULT
 *    polygon       (geometry) - Result of square buffering a linestring.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding (Oracle).
 *    Simon Greener - Nov 2017 - Original coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_wkt               varchar(max),
    @v_GeometryType      varchar(100),
    @v_dimensions        varchar(4),
    @v_round_xy          int,
    @v_round_zm          int,
    @v_offset            float,
    @v_buffer_distance   float,
    @v_buffer_increment  float,
    @v_GeomN             int,
    @v_numGeoms          int,
    @v_sBearing          float,
    @v_eBearing          float,
    @v_start_linestring  geometry,
    @v_end_linestring    geometry,
    @v_start_point       geometry,
    @v_end_point         geometry,
    @v_point             geometry,
    @v_centre_of_circle  geometry,
    @v_split_lines       geometry,
    @v_split_geom        geometry,
    @v_side_geom         geometry,
    @v_buffer            geometry;
  Begin
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( ISNULL(ABS(@p_buffer_distance),0.0) = 0.0 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
      Return @p_linestring;

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Create buffer around linestring.
    SET @v_buffer_distance  = ABS(@p_buffer_distance);
    SET @v_buffer_increment = ABS(ROUND(1.0/POWER(10,@v_round_xy+1),@v_round_xy+1));

    -- Create ordinary buffer
    SET @v_buffer           = @p_linestring.STBuffer(@v_buffer_distance);

    -- If closed linestring then simply return buffer
    -- STEquals with precision
    --
    IF ( @p_linestring.STStartPoint().STEquals(@p_linestring.STEndPoint())=1
      OR [$(owner)].[STEquals] ( 
             @p_linestring.STStartPoint(),
             @p_linestring.STEndPoint(),
             @v_round_xy,
             @v_round_zm,
             @v_round_zm ) = 1 )
    BEGIN
      Return @v_buffer;
    END;

    IF ( @v_GeometryType = 'CompoundCurve' )
    BEGIN
      SET @v_start_linestring = @p_linestring.STCurveN(1);
      SET @v_end_linestring   = @p_linestring.STCurveN(@p_linestring.STNumCurves());
    END
    ELSE
    BEGIN
      SET @v_start_linestring = @p_linestring;
      SET @v_end_linestring   = @p_linestring;
    END;

    -- Create splitting lines at either end at 90 degrees to line direction.
    -- 
    IF ( @v_start_linestring.STGeometryType() = 'LineString' ) 
    BEGIN
      SET @v_sBearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_start_linestring.STStartPoint(),
                            @v_start_linestring.STPointN(2)
                         )
                         + 
                         (SIGN(@p_buffer_distance) * 90.0 )
                       );
      SET @v_offset= ABS(@p_buffer_distance) + @v_buffer_increment;
    END;

    IF ( @v_start_linestring.STGeometryType() = 'CircularString') 
    BEGIN
      -- Compute curve center
      SET @v_centre_of_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_start_linestring );
      -- Is collinear?
      IF ( @v_centre_of_circle.STStartPoint().STX = -1 
       and @v_centre_of_circle.STStartPoint().STY = -1 
       and @v_centre_of_circle.STStartPoint().Z   = -1 )
        RETURN @v_buffer;
      -- Line from centre to @v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_sBearing = [$(cogoowner)].[STBearingBetweenPoints] (
                          @v_centre_of_circle,
                          @v_start_linestring.STStartPoint()
                       );
      SET @v_offset = ABS(@v_centre_of_circle.Z /*Radius*/ + @p_buffer_distance) + @v_buffer_increment;
    END;

     /* Create start offset split line */
    SET @v_start_point      = [$(cogoowner)].[STPointFromCOGO] (
                                /* @p_start_point */ @v_start_linestring.STStartPoint(),
                                /* @p_dBearing    */ @v_sBearing,
                                /* @p_dDistance   */ @v_offset,
                                /* @p_round_xy    */ @v_round_xy );
    SET @v_end_point        = [$(cogoowner)].[STPointFromCOGO] (
                                /* @p_start_point */ @v_start_linestring.STStartPoint(),
                                /* @p_dBearing    */ [$(cogoowner)].[STNormalizeBearing] ( @v_sBearing + 180.0 ),
                                /* @p_dDistance   */ @v_offset,
                                /* @p_round_xy    */ @v_round_xy );
    SET @v_start_linestring = [$(owner)].[STMakeLine] (@v_start_point,@v_end_point,@v_round_xy+1,@v_round_zm);

     -- ***************************************
    -- Do same for end                        
    IF ( @v_end_linestring.STGeometryType() = 'LineString')  
    BEGIN
      SET @v_eBearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_end_linestring.STPointN(@p_linestring.STNumPoints()-1),
                            @v_end_linestring.STEndPoint()
                         )
                         +
                         (SIGN(@p_buffer_distance) * 90.0)
                       );
      SET @v_offset= ABS(@p_buffer_distance) + @v_buffer_increment;
    END;

    IF ( @v_end_linestring.STGeometryType() = 'CircularString' ) 
    BEGIN
      -- Compute curve center
      SET @v_centre_of_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_end_linestring );
      -- Is collinear?
      IF ( @v_centre_of_circle.STStartPoint().STX = -1
       and @v_centre_of_circle.STStartPoint().STY = -1 
       and @v_centre_of_circle.STStartPoint().Z   = -1 )
        RETURN @v_buffer;
      -- Line from centre to v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_eBearing = [$(cogoowner)].[STBearingBetweenPoints] (
                          @v_end_linestring.STEndPoint(),
                          @v_centre_of_circle
                       );
      SET @v_offset = ABS(@v_centre_of_circle.Z /*Radius*/ + @p_buffer_distance) + @v_buffer_increment;
    END;
    -- Create end offset right angled line
    /* Create start offset split line */
    SET @v_start_point      = [$(cogoowner)].[STPointFromCOGO] (
                                /* @p_start_point */ @v_end_linestring.STEndPoint(),
                                /* @p_dBearing    */ @v_eBearing,
                                /* @p_dDistance   */ @v_offset,
                                /* @p_round_xy    */ @v_round_xy );
    SET @v_end_point        = [$(cogoowner)].[STPointFromCOGO] (
                                /* @p_start_point */ @v_end_linestring.STEndPoint(),
                                /* @p_dBearing    */ [$(cogoowner)].[STNormalizeBearing] ( @v_eBearing + 180.0 ),
                                /* @p_dDistance   */ @v_offset,
                                /* @p_round_xy    */ @v_round_xy );
    SET @v_end_linestring   = [$(owner)].[STMakeLine] (@v_start_point,@v_end_point,@v_round_xy+1,@v_round_zm);

    -- Create split geometry 
    SET @v_split_lines = @v_start_linestring.STUnion(@v_end_linestring);

    -- Now, split buffer with modified linestring (using buffer trick) to generate two polygons
    SET @v_split_geom = @v_buffer.STDifference(@v_split_lines.STBuffer(@v_buffer_increment*2.0));

    -- Find out which polygon is the one we want.
    SET @v_point = NULL;
    IF ( @p_linestring.STNumPoints() > 2  )
    BEGIN
        SET @v_point = @p_linestring.STPointN(2);
    END
    ELSE
    BEGIN
       -- Create selection point in middle of original linestring
       SET @v_point = [$(owner)].[STCentroid_L](
                         /* @p_geometry            */ @p_linestring,
                         /* @p_multiLineStringMode */
                        /* 0=all,1=First,2=largest,3=smallest*/ 1,
                         /* @p_position_as_ratio   */ 0.5,
                         /* @p_round_xy            */ @v_round_xy,
                         /* @p_round_zm            */ @v_round_zm
                      );
    END;

    -- Now find polygon that is around the actual line
    SET @v_GeomN    = 1;
    SET @v_numGeoms = @v_split_geom.STNumGeometries();
    WHILE ( @v_GeomN <= @v_numGeoms )
    BEGIN
      IF ( @v_split_geom.STGeometryN(@v_GeomN).STContains(@v_point) = 1 )
      BEGIN
        SET @v_side_geom = @v_split_geom.STGeometryN(@v_GeomN);
        BREAK;
      END;
      SET @v_GeomN = @v_GeomN + 1;
    END;
    -- STRound removes @v_buffer_increment (0.00001) sliver trick that would otherwise be left behind in the data.
    --
     RETURN [$(owner)].[STRound] ( 
              case when @v_side_geom is null 
                   then @v_split_geom 
                   else @v_side_geom
               end,
             @v_round_xy, 
             @v_round_xy, 
             @v_round_zm,
             @v_round_zm
            );
  End;
End
GO



