USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(lrsowner)].[STFindArcPointByMeasure]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindArcPointByMeasure];
  PRINT 'Dropped [$(lrsowner)].[STFindArcPointByMeasure] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STFindArcPointByMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindArcPointByMeasure]
(
  @p_circular_arc geometry /* CircularString */,
  @p_measure      float,
  @p_offset       Float = 0.0,
  @p_round_xy     int   = 3,
  @p_round_zm     int   = 2
)
Returns geometry 
AS
/****f* LRS/STFindArcPointByMeasure (2012)
  *  NAME
  *   STFindArcPointByMeasure - Computes point on circular arc @p_measure from start with offset
  *  SYNOPSIS
  *    Function STFindArcPointByMeasure (
  *        @p_circular_arc geometry 
  *        @p_measure      float,
  *        @p_offset       Float = 0.0,
  *        @p_round_xy     int   = 3,
  *        @p_round_zm     int   = 2
  *      )
  *      Return Geometry (Point)
  *  DESCRIPTION
  *    Supplied with a circular linestring, a measured distance from the start, and an offset, 
  *    this function computes the point on the circular arc.
  *    If the @p_offset value is <> 0, the function computes a new position for the point at a 
  *    distance of @p_offset on the left (-ve) or right (+ve) side of the circular arc.
  *    The returned vertex has its ordinate values rounded using the relevant decimal place values.
  *  INPUTS
  *    @p_circular_arc (geometry) - A circular linestring 
  *    @p_measure         (float) - Measured distance from start vertex to required point.
  *    @p_offset          (float) - The perpendicular distance to offset the generated point.
  *                                 A negative value instructs the function to offet the point to the left (start-end),
  *                                 and a positive value to the right. 
  *    @p_round_xy          (int) - Number of decimal digits of precision for an X or Y ordinate.
  *    @p_round_zm          (int) - Number of decimal digits of precision for an Z or M ordinate.
  *  RESULT
  *    point          (geometry)          - The computed point.
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
    @v_round_xy      int,
    @v_round_zm      int,
    @v_measure       float,
    @v_length        float,
    @v_measure_ratio float,
    @v_arc_length    float,
    @v_offset        Float,
    @v_bearing       float,
    @v_angle         float,
    @v_circumference float,
    @v_centre_point  geometry,
    @v_point         geometry;
  BEGIN
    IF ( @p_circular_arc is null ) 
      Return NULL;

    IF ( @p_circular_arc.STGeometryType() <> 'CircularString' ) -- This function only supports a single CircularString ....
      Return NULL;

    IF ( @p_circular_arc.STNumCurves() > 1 )                    -- We only process a single CircularString
      Return @p_Circular_arc;

    IF ( @p_circular_arc.HasM = 0 )                             -- And we only process measured CircularStrings
      Return null;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset   = ISNULL(@p_offset,0.0);
    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                        + case when @p_circular_arc.HasZ=1 then 'Z' else '' end +
                        + case when @p_circular_arc.HasM=1 then 'M' else '' end;

    SET @v_measure = ISNULL(@p_measure,@p_circular_arc.STPointN(1).M);

    -- Check supplied measure between start and end measure
    IF ( @v_measure NOT BETWEEN @p_circular_arc.STPointN(1).M 
                            AND @p_circular_arc.STPointN(3).M )
      Return NULL;

    -- Compute arc point
    SET @v_centre_point = [$(cogoowner)].[STFindCircleFromArc] ( @p_circular_arc );

    -- Defines circle?
    IF (  @v_centre_point.STX = -1 
      and @v_centre_point.STY = -1 
      and @v_centre_point.Z   = -1 )
      Return @v_point;

    -- Compute circumference of circle
    SET @v_circumference  = CAST(2.0 as float) * PI() * @v_centre_point.Z;
    -- Compute arcLength to our measure point
    SET @v_measure_ratio  = (@p_measure - @p_circular_arc.STStartPoint().M) / ( @p_circular_arc.STEndPoint().M - @p_circular_arc.STStartPoint().M);
    SET @v_arc_length     = @p_circular_arc.STLength() * @v_measure_ratio;
    -- Compute the angle subtended by the arc at the centre of the circle
    SET @v_angle          = (@v_arc_length / @v_circumference) * CAST(360.0 as float);
    -- Compute bearing from centre to first point of circular arc
    SET @v_bearing        = [$(cogoowner)].[STBearingBetweenPoints](
                                @v_centre_point,
                                @p_circular_arc.STStartPoint()
                            );
    -- if circular arc is rotating anticlockwise we subtract the angle from the bearing
    SET @v_bearing        = @v_bearing + ( @v_angle * [$(cogoowner)].[STisClockwiseArc] (@p_circular_arc));
    -- Normalise bearing
    SET @v_bearing        = [$(cogoowner)].[STNormalizeBearing](@v_bearing);
    -- Compute point on Circular Arc
    SET @v_point          = [$(cogoowner)].[STPointFromCOGO](
                              @v_centre_point,
                              @v_Bearing,
                              @v_centre_point.Z - @v_offset,
                              15 /* Trying not to lose precision in calculations */
                            );
    -- Construct return point calculating Z ordinate if needed
    SET @v_point          = geometry::STPointFromText(
                              'POINT(' 
                              + 
                              [$(owner)].[STPointAsText] (
                                /* @p_dimensions */ @v_dimensions,
                                /* @p_X          */ @v_point.STX,
                                /* @p_Y          */ @v_point.STY,
                                /* @p_Z          */ case when @p_circular_arc.HasZ=1 
                                                         then @p_circular_arc.STPointN(1).Z + ( (@p_circular_arc.STPointN(3).Z-@p_circular_arc.STPointN(1).Z) * @v_measure_ratio)
                                                         else null
                                                     end,
                                /* @p_M          */ @p_measure,
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
END
GO

PRINT 'Testing [$(lrsowner)].[STFindArcPointByMeasure] ...';
GO

with data as (
select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindArcPointByMeasure](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.1) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M,
                               round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
                               1) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select a.linestring.STPointN(a.linestring.STNumPoints()).M as measure, 
       null as offset,
       linestring.STBuffer(0.5)
  from data as a;
GO

