SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '************************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindArcPointByLength]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindArcPointByLength];
  PRINT 'Dropped [$(lrsowner)].[STFindArcPointByLength] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STFindArcPointByLength] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindArcPointByLength]
(
  @p_circular_arc geometry,
  @p_length       float,
  @p_offset       Float = 0.0,
  @p_round_xy     int   = 3,
  @p_round_zm     int   = 2
)
Returns geometry 
AS
/****f* LRS/STFindArcPointByLength (2012)
 *  NAME
 *   STFindArcPointByLength - Computes point on @p_circular_arc (CircularString) @p_length from start with @p_offset
 *  SYNOPSIS
 *    Function STFindArcPointByLength (
 *               @p_circular_arc geometry 
 *               @p_length       float,
 *               @p_offset       Float = 0.0,
 *               @p_round_xy     int   = 3,
 *               @p_round_zm     int   = 2
 *           )
 *   Returns Geometry (Point)
 *  DESCRIPTION
 *    Supplied with a circular linestring, a distance from the start, and an offset, 
 *    this function computes the the point on the circular arc.
 *    If the @p_offset value is <> 0, the function computes a new position for the point at a 
 *    distance of @p_offset on the left (-ve) or right (+ve) side of the circular arc.
 *    The returned vertex has its ordinate values rounded using the relevant decimal place values.
 *  INPUTS
 *    @p_circular_arc (geometry) - A circular linestring 
 *    @p_length          (float) - Distance from start vertex to required point.
 *    @p_offset          (float) - The perpendicular distance to offset the generated point.
 *                                 A negative value instructs the function to offet the point to the left (start-end),
 *                                 and a positive value to the right. 
 *    @p_round_xy          (int) - Number of decimal digits of precision for an X or Y ordinate.
 *    @p_round_zm          (int) - Number of decimal digits of precision for an Z or M ordinate.
 *  RESULT
 *    point          (geometry) - The computed point.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2017 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_dimensions    varchar(4),
    @v_length        float,
    @v_offset        Float,
    @v_round_xy      int,
    @v_round_zm      int,
    @v_circumference float,
    @v_angle         Float,
    @v_clockwise     bit,
    @v_bearing       Float,
    @v_length_ratio  float,
    @v_centre_point  geometry,
    @v_point         geometry;
  BEGIN
    IF ( @p_circular_arc is null ) 
      Return NULL;

    -- This function only supports single CircularStrings ....
    IF ( @p_circular_arc.STGeometryType() <> 'CircularString' ) 
      Return NULL;

    -- This function only supports a single CircularString with three points....
    IF ( @p_circular_arc.STNumPoints() > 3 )
      Return null;

    SET @v_offset   = ISNULL(@p_offset,0.0);
    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_length   = ISNULL(@p_length,0.0);

    IF ( @v_length > @p_circular_arc.STLength() )  
      SET @v_length = @p_circular_arc.STLength();

    -- Short circuit first point if no offset
    IF ( @v_length = 0.0 and @v_offset = 0.0) 
      Return @p_circular_arc.STPointN(1);

    -- Short circuit last point
    IF ( ROUND(@v_length,@v_round_xy+1) = ROUND(@p_circular_arc.STLength(),@v_round_xy+1) and @v_offset = 0.0 )  
      Return @p_circular_arc.STPointN(3);

    -- Compute centre of circle defining CircularString
    SET @v_centre_point = [$(cogoowner)].[STFindCircleFromArc] ( @p_circular_arc );
    -- Defines circle?
    IF (  @v_centre_point.STX = -1 
      and @v_centre_point.STY = -1 
      and @v_centre_point.Z   = -1 )
      Return null;
    
    -- Compute circumference of circle
    SET @v_circumference = 2.0 * PI() * @v_centre_point.Z;
    -- Compute the angle subtended by the arc at the centre of the circle
    SET @v_angle         = @p_circular_arc.STLength() / @v_circumference * 360.0;
    -- Compute length ratio to apply to @v_angle to locate point
    SET @v_length_ratio  = @v_length / @p_circular_arc.STLength();
    -- Apply ratio to angle
    SET @v_angle         = @v_angle * @v_length_ratio;
    -- Compute bearing from centre to first point of circular arc
    SET @v_bearing       = [$(cogoowner)].[STBearingBetweenPoints](
                             @v_centre_point,
                             @p_circular_arc.STStartPoint()
                           );
    -- Adjust bearing depending on whether CircularString is rotating anticlockwise (-1) or clockwise(1) 
    SET @v_bearing       = @v_bearing + ( @v_angle * [$(cogoowner)].[STisClockwiseArc] (@p_circular_arc));
    -- Normalise bearing
    SET @v_bearing       = [$(cogoowner)].[STNormalizeBearing](@v_bearing);
    -- Compute point
    SET @v_point         = [$(cogoowner)].[STPointFromCOGO](
                             @v_centre_point,
                             @v_Bearing,
                             @v_centre_point.Z - @v_offset,
                             @p_round_xy
                           );
    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                        + case when @p_circular_arc.HasZ=1 then 'Z' else '' end +
                        + case when @p_circular_arc.HasM=1 then 'M' else '' end;
    SET @v_point      = geometry::STPointFromText(
                         'POINT(' 
                         + 
                         [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_point.STX,
                            /* @p_Y          */ @v_point.STY,
                            /* @p_Z          */ @p_circular_arc.STPointN(1).Z + ((@p_circular_arc.STPointN(3).Z-@p_circular_arc.STPointN(1).Z)*@v_length_ratio),
                            /* @p_M          */ @p_circular_arc.STPointN(1).M + ((@p_circular_arc.STPointN(3).M-@p_circular_arc.STPointN(1).M)*@v_length_ratio),
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                         )
                         + 
                         ')',
                         @p_circular_arc.STSrid
                       );
    Return @v_point;
  END;
END;
GO



