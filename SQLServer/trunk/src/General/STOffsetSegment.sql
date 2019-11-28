SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STOffsetSegment]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STOffsetSegment];
  Print 'Dropped [$(owner)].[STOffsetSegment]...';
END;
GO

Print 'Creating [$(owner)].[STOffsetSegment]...';
GO

CREATE FUNCTION [$(owner)].[STOffsetSegment]
(
  @p_linestring geometry,
  @p_offset     Float,
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns geometry 
AS
/****f* GEOPROCESSING/STOffsetSegment (2012)
 *  NAME
 *    STOffsetSegment -- Creates a line at a fixed offset from the input 2 point LineString or 3 point CircularString.
 *  SYNOPSIS
 *    Function STOffsetSegment (
 *               @p_linestring geometry,
 *               @p_offset     float, 
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             
 *     Returns geometry
 *  EXAMPLE
 *    WITH data AS (
 *     SELECT geometry::STGeomFromText('CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3)',0) as segment
 *     UNION ALL
 *     SELECT geometry::STGeomFromText('LINESTRING (-3 6.3 1.1 9.3, 0 0 1.4 16.3)',0) as segment
 *  )
 *  SELECT 'Before' as text, d.segment.AsTextZM() as rGeom from data as d
 *  UNION ALL
 *  SELECT 'After' as text, [$(owner)].STOffsetSegment(d.segment,1,3,2).AsTextZM() as rGeom from data as d;
 *  GO
 *  DESCRIPTION
 *    This function creates a parallel line at a fixed offset to the supplied 2 point LineString or 3 point CircularString.
 *    To create a line on the LEFT of the segment (direction start to end) supply a negative @p_distance; 
 *    a +ve value will create a line on the right side of the segment.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision, and its ZM ordinates rounded to @p_round_zm of precision.
 *  NOTES
 *    A Segment is defined as a simple two point LineString geometry or three point CircularString geometry. 
 *  INPUTS
 *    @p_linestring  (geometry) - Must be a simple LineString or CircularString.
 *    @p_offset         (float) - if < 0 then linestring is created on left side of original; if > 0 then offset linestring it to right side of original.
 *    @p_round_xy         (int) - Rounding factor for XY ordinates.
 *    @p_round_zm         (int) - Rounding factor for ZM ordinates.
 *  RESULT
 *    offset segment (geometry) - On left or right side of supplied segment at required distance.
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
    @v_gtype           varchar(max),
    @v_wkt             varchar(max),
    @v_dimensions      varchar(4),
    @v_round_xy        int,
    @v_round_zm        int,
    @v_subtended_angle float,
    @v_bearing         float,
    @v_offset          float,
    @v_sign            int,
    @v_delta_x         float,
    @v_delta_y         float,
    @v_circle          geometry,
    @v_start_point     geometry,
    @v_mid_point       geometry,
    @v_end_point       geometry;
  Begin
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( ABS(ISNULL(@p_offset,0.0)) = 0.0 )
      Return @p_linestring;

    SET @v_gtype = @p_linestring.STGeometryType();
    IF ( @v_gtype NOT IN ('LineString','CircularString' ) )
      Return @p_linestring;

    IF ( @v_gtype = 'LineString' and @p_linestring.STNumPoints() <> 2 )
      Return @p_linestring;

    IF ( @v_gtype = 'CircularString' and @p_linestring.STNumPoints() <> 3 and @p_linestring.STNumCurves() <> 1)
      Return @p_linestring;

    -- Set flag for STPointFromText
    SET @v_dimensions  = 'XY' 
                         + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                         + case when @p_linestring.HasM=1 then 'M' else '' end;
    SET @v_round_xy    = ISNULL(@p_round_xy,3);
    SET @v_round_zm    = ISNULL(@p_round_zm,2);
    SET @v_sign        = SIGN(@p_offset);
    SET @v_offset      = ABS(@p_offset);

    IF ( @v_gtype = 'LineString' ) 
    BEGIN
      -- Compute common bearing as radians not degrees ...
      SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints] (
                           @p_linestring.STStartPoint(),
                           @p_linestring.STEndPoint()
                       );

      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                          @v_bearing 
                          + 
                          (@v_sign * 90.0) -- If left, then -90 else 90
                       );

      -- Compute first offset point
      SET @v_start_point = [$(cogoowner)].[STPointFromCOGO] ( 
                             @p_linestring.STStartPoint(),
                             @v_bearing,
                             @v_offset, -- Has to be +ve
                             @v_round_xy
                           );

      -- Create deltas to apply to End Ordinate...
      SET @v_delta_x = @v_start_point.STX - @p_linestring.STStartPoint().STX;
      SET @v_delta_y = @v_start_point.STY - @p_linestring.STStartPoint().STY;

      -- Now create offset linestring
      SET @v_wkt = 'LINESTRING ('
                 +
                 [$(owner)].[STPointAsText] (
                   /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                   /* @p_X          */ @v_start_point.STX,
                   /* @p_Y          */ @v_start_point.STY,
                   /* @p_Z          */ @p_linestring.STStartPoint().Z,
                   /* @p_M          */ @p_linestring.STStartPoint().M,
                   /* @p_round_x    */ @v_round_xy,
                   /* @p_round_y    */ @v_round_xy,
                   /* @p_round_z    */ @v_round_zm,
                   /* @p_round_m    */ @v_round_zm
                 )
                 +
                 ','
                 +
                 [$(owner)].[STPointAsText] (
                   /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                   /* @p_X          */ @p_linestring.STEndPoint().STX + @v_delta_x,
                   /* @p_Y          */ @p_linestring.STEndPoint().STY + @v_delta_y,
                   /* @p_Z          */ @p_linestring.STEndPoint().Z,
                   /* @p_M          */ @p_linestring.STEndPoint().M,
                   /* @p_round_x    */ @v_round_xy,
                   /* @p_round_y    */ @v_round_xy,
                   /* @p_round_z    */ @v_round_zm,
                   /* @p_round_m    */ @v_round_zm
                 )
                 +
                 ')';
      RETURN geometry::STGeomFromText(@v_wkt,
                                      @p_linestring.STSrid);
    END;

    -- ###################################################
    -- Now we are processing a CircularCurve
    -- 

    -- Compute curve center
    -- 
    SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @p_linestring );

    -- Is collinear?
    IF ( @v_circle.STX = -1 
     and @v_circle.STY = -1 
     and @v_circle.Z   = -1 )
    BEGIN
      Return [$(owner)].[STDeleteN] (
                /* @p_geometry */ @p_linestring,
                /* @p_position */ 2,
                /* @p_round_xy */ @p_round_xy,
                /* @p_round_zm */ @p_round_zm
             )
    END;

    -- Compute rotation of circular arc (from starting point) to ensure offset is applied correctly to the radius
    -- 
    SET @v_subtended_angle = [$(cogoowner)].[STSubtendedAngle] (
                                @p_linestring.STStartPoint().STX,
                                @p_linestring.STStartPoint().STY,
                                @v_circle.STX,
                                @v_circle.STY,
                                @p_linestring.STEndPoint().STX,
                                @p_linestring.STEndPoint().STY
                             );

    --     If @v_subtended_angle is -ve, the centre point is on right, and the circularString curves to right; 
    -- And if @v_subtended_angle is +ve, the centre point is on left,  and the circularString curves to left.
    -- 
    -- Therefore:
    --
    --     If @v_subtended_angle is -ve (right):
    --        If @v_sign is -ve (left) Then
    --           @v_offset should be radius + v_offset.
    --        Else @v_sign is +ve (right) 
    --           @v_offset should be radius - v_offset (check no < 0).
    --
    --     If @v_subtended_angle is +ve (right) 
    --        IF @v_sign is -ve (left) THEN
    --           @v_offset should be radius - v_offset (check no < 0).
    --        Else @v_sign is +ve (right)
    --           @v_offset should be radius + v_offset
    --
    SET @v_offset = case when @v_subtended_angle < 0
                         then case when @v_sign < 0 
                                   then @v_circle.Z + @v_offset 
                                   else @v_circle.Z - @v_offset
                               end
                         else case when @v_sign < 0 
                                   then @v_circle.Z - @v_offset
                                   else @v_circle.Z + @v_offset 
                               end
                     end;

    -- Check if curve will degenerate into a single point
    IF ( @v_offset <= 0.0 )
      RETURN geometry::Point(@v_circle.STX,
                             @v_circle.STY,
                             @p_linestring.STSrid);

    -- Now compute new circularString points
    --
    -- Start Point
    --
    SET @v_bearing     = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_circle,
                            @p_linestring.STStartPoint()
                         );
    SET @v_start_point = [$(cogoowner)].[STPointFromCOGO] ( 
                            @v_circle,
                            @v_bearing,
                            @v_offset,
                            @v_round_xy
                       );
    -- Mid Point
    --
    SET @v_bearing     = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_circle,
                            @p_linestring.STPointN(2)
                         );
    SET @v_mid_point   = [$(cogoowner)].[STPointFromCOGO] ( 
                            @v_circle,
                            @v_bearing,
                            @v_offset,
                            @v_round_xy
                         );
    -- End Point
    --
    SET @v_bearing     = [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_circle,
                            @p_linestring.STEndPoint()
                         );
    SET @v_end_point   = [$(cogoowner)].[STPointFromCOGO] ( 
                            @v_circle,
                            @v_bearing,
                            @v_offset,
                            @v_round_xy
                         );

    -- #######################################################
    -- Create CircularString to return.
    SET @v_wkt = 'CIRCULARSTRING ('
                 +
                 [$(owner)].[STPointAsText] (
                    /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                    /* @p_X          */ @v_start_point.STX,
                    /* @p_Y          */ @v_start_point.STY,
                    /* @p_Z          */ @p_linestring.STStartPoint().Z,
                    /* @p_M          */ @p_linestring.STStartPoint().M,
                    /* @p_round_x    */ @v_round_xy,
                    /* @p_round_y    */ @v_round_xy,
                    /* @p_round_z    */ @v_round_zm,
                    /* @p_round_m    */ @v_round_zm
                )
                +
                ','
                +
                [$(owner)].[STPointAsText] (
                    /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                    /* @p_X          */ @v_mid_point.STX,
                    /* @p_Y          */ @v_mid_point.STY,
                    /* @p_Z          */ @p_linestring.STPointN(2).Z,
                    /* @p_M          */ @p_linestring.STPointN(2).M,
                    /* @p_round_x    */ @v_round_xy,
                    /* @p_round_y    */ @v_round_xy,
                    /* @p_round_z    */ @v_round_zm,
                    /* @p_round_m    */ @v_round_zm
               )
               +
               ','
               +
               [$(owner)].[STPointAsText] (
                    /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                    /* @p_X          */ @v_end_point.STX,
                    /* @p_Y          */ @v_end_point.STY,
                    /* @p_Z          */ @p_linestring.STEndPoint().Z,
                    /* @p_M          */ @p_linestring.STEndPoint().M,
                    /* @p_round_x    */ @v_round_xy,
                    /* @p_round_y    */ @v_round_xy,
                    /* @p_round_z    */ @v_round_zm,
                    /* @p_round_m    */ @v_round_zm
               )
               +
               ')';

    -- Now return circular arc
    Return geometry::STGeomFromText(@v_wkt,
                                    @p_linestring.STSrid);
  End;
End;
GO

