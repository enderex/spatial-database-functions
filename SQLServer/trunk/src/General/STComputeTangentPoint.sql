SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id(N'[$(cogoowner)].[STComputeTangentPoint]') 
              AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STComputeTangentPoint];
  PRINT 'Dropped [$(cogoowner)].[STComputeTangentPoint] ...';
END;
GO

PRINT 'Create STComputeTangentPoint ...';
GO

CREATE FUNCTION [$(cogoowner)].[STComputeTangentPoint]
(
  @p_circular_arc geometry,
  @p_position     varchar(5) = 'START' /* or 'END' */,
  @p_round_xy     int = 3
)
Returns geometry /* point */
AS
/****m* COGO/STComputeTangentPoint (2012)
 *  NAME
 *    STComputeTangentPoint -- Computes point that would define a tandential line at the start or end of a circular arc
 *  SYNOPSIS
 *    Function STComputeTangentPoint ( 
 *               @p_circular_arc geometry,
 *               @p_position     varchar(5) = 'START', -- or 'END'
 *               @p_round_xy     int = 3
 *             )
 *     Returns geometry
 *    SELECT [$(cogoowner)].[STComputeTangentPoint](100, 0.003);
 *  DESCRIPTION
 *    There is a need to be able to compute an angle between a linestring and a circularstring. 
 *    To do this, one needs to compute a tangential line at the start or end of a circularstring.
 *    This function computes point that would define a tandential line at the start or end of a circular arc.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *    Only supports SQL Server Spatial 2012 onwards as 2008 does not support CircularString
 *  TODO
 *    Enable creating of tangent at mid point of circularstring (@p_position=MID).
 *    Enable creating of tangent at a distance along the circularstring.
 *  INPUTS
 *    @p_circular_arc (geometry) - CircularString.
 *    @p_position     (varchar5) - Requests tangent point for 'START' or 'END' of circular arc.
 *    @p_round_xy     (int)      - Decimal degrees of precision for XY ordinates.
 *  RESULT
 *    point           (geometry) - A tangent point that combined with the start or end of the circularstring creates a tangential line.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - Feb 2015 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_round_xy       int = ISNULL(@p_round_xy,3),
    @v_start          bit,
    @v_bearing        float,
    @v_shortest_point geometry,
    @v_circular_point geometry,
    @v_tangent_point1 geometry,
    @v_tangent_point2 geometry,
    @v_centre         geometry;
  BEGIN
    IF (@p_circular_arc is null) 
      Return NULL;

    IF (@p_circular_arc.STGeometryType() <> 'CircularString' ) 
      Return NULL;

    SET @v_start = CASE WHEN ISNULL(UPPER(@p_position),'START')='START'
                    THEN 1
                    ELSE 0
                END;

    -- Compute centre of circle defining CircularString
    SET @v_centre = [$(cogoowner)].[STFindCircleFromArc] ( @p_circular_arc );

    -- Do we have a circle?
    IF (  @v_centre.STX = -1 
      and @v_centre.STY = -1 
      and @v_centre.Z   = -1 )
     Return null;

    SET @v_circular_point = CASE WHEN @v_start=1 
                                 THEN @p_circular_arc.STPointN(1) 
                                 ELSE @p_circular_arc.STPointN(3)
                             END;

    -- Get bearing from start/end to centre
    SET @v_bearing = [$(cogoowner)].[STBearing] (
                        @v_circular_point.STX,
                        @v_circular_point.STY,
                        @v_centre.STX,
                        @v_centre.STY
                     );

    -- Compute tangent new point
    -- Two options: compute and chose between
    -- 
    SET @v_tangent_point1 = [$(cogoowner)].[STPointFromBearingAndDistance](
                              @v_circular_point.STX,
                              @v_circular_point.STY,
                              [$(cogoowner)].[STNormalizeBearing](@v_bearing - 90.0),
                              @v_centre.Z,
                              ISNULL(@v_round_xy,3),
                              @p_circular_arc.STSrid
                           );
    SET @v_tangent_point2 = [$(cogoowner)].[STPointFromBearingAndDistance](
                              @v_circular_point.STX,
                              @v_circular_point.STY,
                              [$(cogoowner)].[STNormalizeBearing](@v_bearing + 90.0),
                              @v_centre.Z,
                              ISNULL(@v_round_xy,3),
                              @p_circular_arc.STSrid
                           );
    -- Which one is the right one?
    SET @v_shortest_point = case when @v_tangent_point1.ShortestLineTo(@p_circular_arc).STLength()
                                    < @v_tangent_point2.ShortestLineTo(@p_circular_arc).STLength()
                                 then @v_tangent_point1
                                 else @v_tangent_point2
                            end;
    RETURN @v_shortest_point;
  END;
END;
GO


