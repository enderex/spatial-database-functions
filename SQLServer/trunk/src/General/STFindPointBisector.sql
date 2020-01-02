SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO


PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id(N'[$(cogoowner)].[STFindPointBisector]') 
              AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindPointBisector];
  PRINT 'Dropped [$(cogoowner)].[STFindPointBisector] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STFindPointBisector] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindPointBisector]
(
  @p_line      geometry /* LineString/CircularString */,
  @p_next_line geometry /* LineString/CircularString */,
  @p_offset    Float = 0.0,
  @p_round_xy  int   = 3,
  @p_round_z   int   = 2,
  @p_round_m   int   = 1
)
Returns geometry 
AS
/****m* COGO/STFindPointBisector (2012)
 *  NAME
 *   FindPointBisector - Computes offset point on the bisector between two linestrings.
 *  SYNOPSIS
 *    Function STFindPointBisector
 *               @p_line      geometry 
 *               @p_next_line geometry,
 *               @p_offset    Float = 0.0,
 *               @p_round_xy  int   = 3,
 *               @p_round_z   int   = 2,
 *               @p_round_m   int   = 1
 *             )
 *      Return Geometry (Point)
 *  DESCRIPTION
 *    Supplied with a second linestring (@p_next_line) whose first point is the same as 
 *    the last point of @p_line, this function computes the bisector between the two linestrings 
 *    and then creates a new vertex at a distance of @p_offset from the shared intersection point. 
 *    If an @p_offset value of 0.0 is supplied, the intersection point is returned. 
 *    If the @p_offset value is <> 0, the function computes a new position for the point at a 
 *    distance of @p_offset on the left (-ve) or right (+ve) side of the linestrings.
 *    The returned vertex has its ordinate values rounded using the relevant decimal place values.
 *  NOTES
 *    Only supports CircularStrings from SQL Server Spatial 2012 onwards, otherwise supports LineStrings from 2008 onwards.
 *  INPUTS
 *    @p_line      (geometry) - A vector that touches the next vector at one end point.
 *    @p_next_line (geometry) - A vector that touches the previous vector at one end point.
 *    @p_offset       (float) - The perpendicular distance to offset the point generated using p_ratio.
 *                              A negative value instructs the function to offet the point to the left (start-end),
 *                              and a positive value to the right. 
 *    @p_round_xy       (int) - Number of decimal digits of precision for an X or Y ordinate.
 *    @p_round_z        (int) - Number of decimal digits of precision for an Z ordinate.
 *    @p_round_m        (int) - Number of decimal digits of precision for an M ordinate.
 *  RESULT
 *    point        (geometry) - New point on bisection point or along bisector line with optional perpendicular offset.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2013 - Original coding.
 *    Simon Greener - December 2019 - Fixed bug with Z/M handling.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_dimensions    varchar(4),
    @v_round_xy      int,
    @v_round_z       int,
    @v_round_m       int,
    @v_angle         Float,
    @v_bearing       Float,
    @v_offset        Float,
	@v_deflection_Angle float,
	@v_first_line    geometry,
	@v_second_line   geometry,
    @v_point         geometry,
    @v_prev_point    geometry,
    @v_intersection_point geometry,
    @v_next_point    geometry;
  BEGIN
    IF ( @p_line is null or @p_next_line is null ) 
      Return NULL;

    IF (      @p_line.STGeometryType() NOT IN ('LineString','CircularString','CompoundCurve') 
      OR @p_next_line.STGeometryType() NOT IN ('LineString','CircularString','CompoundCurve') 
       )
      Return NULL;

	SET @v_first_line  = @p_line;
	SET @v_second_line = @p_next_line;
    SET @v_round_xy    = ISNULL(@p_round_xy,3);
    SET @v_round_z     = ISNULL(@v_round_z ,2);
    SET @v_round_m     = ISNULL(@v_round_m ,1);
	SET @v_offset      = ISNULL(@p_offset,  0);
    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_line.HasZ=1 then 'Z' else '' end +
                       + 'M';

	IF ( @p_line.STGeometryType() = 'CompoundCurve')
	BEGIN 
      -- Extract last element of first line
      SET @v_first_line = @p_line.STCurveN(@p_line.STNumCurves());
	  IF ( @v_first_line.STGeometryType() = 'CircularString')
      BEGIN
        IF ( @v_first_line.STNumPoints() > 3 ) 
          SET @v_first_line= [$(owner)].[STCircularStringN](
                                 @v_first_line,
                                 [$(owner)].[STNumCircularStrings](@v_first_line)
                             );
        END;
	END;

    IF ( @v_first_line.STGeometryType() = 'LineString' and @v_first_line.STNumPoints() > 2 )
	  SET @v_first_line = [$(owner)].[STMakeLine](
                             @v_first_line.STPointN(@v_first_line.STNumPoints()-1),
                             @v_first_line.STEndPoint(),
                             @v_round_xy,
                             @v_round_m
                          );

	IF ( @p_next_line.STGeometryType() = 'CompoundCurve')
	BEGIN
      -- Extract first element of second line
	  SET @v_second_line = @p_next_line.STCurveN(1);
      IF ( @v_second_line.STGeometryType() = 'CircularString')
      BEGIN
	    IF ( @v_second_line.STNumPoints() > 3 ) 
	      SET @v_second_line = [$(owner)].[STCircularStringN](@v_second_line,1);
	  END;
	END;

      IF ( @v_second_line.STGeometryType() = 'LineString' and @v_second_line.STNumPoints() > 2 )
	  SET @v_second_line = [$(owner)].[STMakeLine](
                             @v_second_line.STStartPoint(),
                             @v_second_line.STPointN(2),
                             @v_round_xy,
                             @v_round_m
                          );

    -- This function only handles start/end connected linestrings.
	IF ( @v_first_line.STEndPoint().STEquals(@v_second_line.STStartPoint())  = 0 )
	 RETURN NULL;

    SET @v_intersection_point = @v_first_line.STEndPoint();

    -- Offset vectors from intersection point
    IF ( @v_first_line.STGeometryType()='CircularString' )
	  SET @v_first_line = [$(owner)].[STMakeLine](
                            [$(cogoowner)].[STComputeTangentPoint](@v_first_line,'END',@v_round_xy),
	                        @v_intersection_point,
							@v_round_xy,
							@v_round_z
                          );

    IF ( @v_second_line.STGeometryType() = 'CircularString' )
      SET @v_second_line= [$(owner)].[STMakeLine](
	                        @v_intersection_point,
                            [$(cogoowner)].[STComputeTangentPoint](@v_second_line,'START',@v_round_xy),
							@v_round_xy,
							@v_round_z
                          );

	-- Compute deflection angle
	SET @v_deflection_Angle = [$(cogoowner)].[STFindDeflectionAngle](
	                              @v_first_line,
								  @v_second_line
                              );

	-- If negative then acute to left, else if positive 
	IF ( @v_deflection_Angle < 0 )
	BEGIN
	  IF (  @v_offset < 0 ) -- Same direction and deflection
        SET @v_angle = ( (180.0 - ABS(@v_deflection_angle)) / 2.0 )
	  ELSE
        SET @v_angle = ( -1 * (180.0 + ABS(@v_deflection_angle)) / 2.0 );
	END
	ELSE -- @v_deflection_angle > 0
	BEGIN
	  IF ( @v_offset < 0 )
        SET @v_angle = (180.0 + ABS(@v_deflection_angle)) / 2.0
	  ELSE
        SET @v_angle = -1 * (180.0 - ABS(@v_deflection_angle)) / 2.0;
	END;

	-- Bearing to offset point
    SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] (
	                    [$(cogoowner)].[STBearingBetweenPoints] (
                           @v_intersection_point,
                           @v_first_line.STStartPoint()
                        )
                        +
                        @v_angle
                     );

    -- Need to compute bearing between these two on correct side base on p_offset (-ve/+ve)
    SET @v_point   = [$(cogoowner)].[STPointFromCOGO] (
                          @v_intersection_point,
                          @v_Bearing,
                          ABS(@v_offset),
                          @v_round_xy
                      );

    -- Set any Z or M measures (@v_dimensions determines ordinates written)
    SET @v_point = geometry::STPointFromText(
                        'POINT(' 
                        + 
                        [$(owner)].[STPointAsText] (
                          /* @p_dimensions */ @v_dimensions,
                          /* @p_X          */ @v_point.STX,
                          /* @p_Y          */ @v_point.STY,
                          /* @p_Z          */ @p_line.STEndPoint().Z,
                          /* @p_M          */ @p_line.STEndPoint().M,
                          /* @p_round_x    */ @v_round_xy,
                          /* @p_round_y    */ @v_round_xy,
                          /* @p_round_z    */ @v_round_z,
                          /* @p_round_m    */ @v_round_m
                        )
                        + 
                        ')',
                        @v_first_line.STSrid
                     );
    Return @v_point;
  END;
END;
GO

