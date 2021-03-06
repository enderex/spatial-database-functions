SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) Cogo($(cogoowner))';
GO

:On Error Ignore

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STFindAngleBetween]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindAngleBetween];
  PRINT 'Dropped [$(cogoowner)].[STFindAngleBetween] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STFindAngleBetween]...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindAngleBetween]
(
  @p_line      geometry,
  @p_next_line geometry,
  @p_side      int = -1
)
Returns Float
AS
/****f* COGO/STFindAngleBetween (2012)
 *  NAME
 *   STFindAngleBetween - Computes left or right angle between first and second linestrings in the direction from @p_line to @p_next_line
 *  SYNOPSIS
 *    Function STFindAngleBetween
 *               @p_line      geometry 
 *               @p_next_line geometry,
 *               @p_side      int = -1 -- Left -1; Right +1 
 *             )
 *      Return Float
 *  DESCRIPTION
 *    Supplied with a second linestring (@p_next_line) whose first point is the same as 
 *    the last point of @p_line, this function computes the angle between the two linestrings 
 *    on either the left (-1) or right (+1) side in the direction of the two segments.
 *  NOTES
 *    Only supports CircularStrings from SQL Server Spatial 2012 onwards, otherwise supports LineStrings from 2008 onwards.
 *    @p_line must be first segment whose STEndPoint() is the same as @p_next_line STStartPoint(). No other combinations are supported.
 *  INPUTS
 *    @p_line      (geometry) - A vector that touches the next vector at one end point.
 *    @p_next_line (geometry) - A vector that touches the previous vector at one end point.
 *    @p_side           (int) - The side whose angle is required; 
 *                              A negative value instructs the function to compute the left angle; 
 *                              and a positive value the right angle.
 *  RESULT
 *    angle           (float) - Left or right side angle
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - April 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_side          Float,
    @v_angle_between Float,
    @v_angle         Float,
    @v_prev_point    geometry,
    @v_mid_point     geometry,
    @v_next_point    geometry;
  BEGIN
    IF ( @p_line is null or @p_next_line is null ) 
      Return NULL;

    IF (      @p_line.STGeometryType() NOT IN ('LineString','CircularString') 
      OR @p_next_line.STGeometryType() NOT IN ('LineString','CircularString') 
       )
      Return NULL;

    -- Because we support circularStrings, we support only single segments ....
    IF ( (      @p_line.STGeometryType() = 'LineString'     and      @p_line.STNumPoints() > 2 ) 
      OR ( @p_next_line.STGeometryType() = 'LineString'     and @p_next_line.STNumPoints() > 2 ) 
      OR (      @p_line.STGeometryType() = 'CircularString' and      @p_line.STNumPoints() > 3 )
      OR ( @p_next_line.STGeometryType() = 'CircularString' and @p_next_line.STNumPoints() > 3 ) )
      Return null;

    SET @v_side = ISNULL(@p_side,-1);

    -- Get intersection(mid) point
    SET @v_mid_point = @p_line.STEndPoint();

    -- Intersection point must be shared.
    IF ( @v_mid_point.STEquals(@p_next_line.STStartPoint())=0 )
      return NULL;

    -- Get previous and next points of 3 point angle.
    IF ( @p_line.STGeometryType()='CircularString' ) 
    BEGIN
      SET @v_prev_point = [$(cogoowner)].[STComputeTangentPoint](@p_line,     'END',  8);
      SET @v_next_point = [$(cogoowner)].[STComputeTangentPoint](@p_next_line,'START',8);
    END
    ELSE
    BEGIN
      SET @v_prev_point = @p_line.STStartPoint(); 
      SET @v_next_point = @p_next_line.STEndPoint();
    END;

    SET @v_angle        = [$(cogoowner)].[STDegrees] ( 
                             [$(cogoowner)].[STSubtendedAngleByPoint] (
                               /* @p_start  */ @v_prev_point,
                               /* @p_centre */ @v_mid_point,
                               /* @p_end    */ @v_next_point
                             ) 
                          );

    SET @v_angle_between = case when @v_angle < 0 and @v_side < 0 /*left */ then (           ABS( @v_angle ) )
                                when @v_angle < 0 and @v_side > 0 /*right*/ then ( 360.0 +        @v_angle ) 
                                when @v_angle > 0 and @v_side < 0 /*left */ then ( 360.0 + ( -1 * @v_angle ) )
                                when @v_angle > 0 and @v_side > 0 /*right*/ then (           ABS( @v_angle ) )
                                when @v_side = 0                  /*None */ then 0.0
                                else 0.0
                            end;

    Return @v_angle_between;
  END;
END;
GO

