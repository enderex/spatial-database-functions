USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: Cogo Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STBearing]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STBearing];
  PRINT 'Dropped [$(cogoowner)].[STBearing] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STBearingBetweenPoints]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STBearingBetweenPoints];
  PRINT 'Dropped [$(cogoowner)].[STBearingBetweenPoints] ...';
END;
GO

IF  EXISTS (SELECT * 
            FROM sys.objects
           WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STPointFromBearingAndDistance]') 
             AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STPointFromBearingAndDistance];
  Print 'Dropped [$(cogoowner)].[STPointFromBearingAndDistance] ...';
END;
GO

IF  EXISTS (SELECT * 
            FROM sys.objects
           WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STPointFromCOGO]') 
             AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STPointFromCOGO];
  Print 'Dropped [$(cogoowner)].[STPointFromCOGO] ...';
END;
GO

Print 'Creating Functions:';
Print '1. STBearing ...'
GO

CREATE FUNCTION [$(cogoowner)].[STBearing] 
(
  @p_dE1 Float,
  @p_dN1 Float,
  @p_dE2 Float,
  @p_dN2 Float
)
Returns Float
AS
/****f* COGO/STBearing (2008)
 *  NAME
 *    STBearing -- Returns a (Normalized) bearing in Degrees between two non-geodetic (XY) coordinates
 *  SYNOPSIS
 *    Function STBearing (
 *               @p_dE1 float,
 *               @p_dN1 float,
 *               @p_dE2 float,
 *               @p_dN2 float
 *             )
 *     Returns float 
 *  USAGE
 *    SELECT [$(cogoowner)].[STBearing](0,0,45,45) as Bearing;
 *    Bearing
 *    45
 *  DESCRIPTION
 *    Function that computes the bearing from the supplied start point (@p_dx1) to the supplied end point (@p_dx2).
 *    The result is expressed as a whole circle bearing in decimal degrees.
 *  INPUTS
 *    @p_dE1 (float) - X ordinate of start point.
 *    @p_dN1 (float) - Y ordinate of start point.
 *    @p_dE2 (float) - Z ordinate of start point.
 *    @p_dN2 (float) - M ordinate of start point.
 *  RESULT
 *    decimal degrees (float) - Bearing between point 1 and 2 from 0-360.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @dBearing Float,
    @dEast    Float,
    @dNorth   Float;
  Begin
    If (@p_dE1 IS NULL OR
        @p_dN1 IS NULL OR
        @p_dE2 IS NULL OR
        @p_dE1 IS NULL ) 
      Return NULL;

    If ( (@p_dE1 = @p_dE2) AND 
         (@p_dN1 = @p_dN2) ) 
      Return NULL;

    SET @dEast  = @p_dE2 - @p_dE1;
    SET @dNorth = @p_dN2 - @p_dN1;
    If ( @dEast = 0.0 ) 
    Begin
      If ( @dNorth < 0.0 ) 
        SET @dBearing = PI();
      Else
        SET @dBearing = 0.0;
    End
    Else
    Begin
      SET @dBearing = -aTan(@dNorth / @dEast) + PI() / CAST(2.0 as float);
    End;
          
    IF ( @dEast < 0.0 ) 
      SET @dBearing = @dBearing + PI();

    -- Turn radians into degrees
    SET @dBearing = @dBearing * CAST(180.0 as float) / PI();
    -- Normalize bearing ...
    Return case when @dBearing < 0.0
                then @dBearing + CAST(360.0 as float)
                when @dBearing >= 360.0
                then @dBearing - CAST(360.0 as float)
                else @dBearing
            end;
    End
End;
GO

Print '2. Creating STBearingBetweenPoints.';
GO

CREATE FUNCTION [$(cogoowner)].[STBearingBetweenPoints] 
(
  @p_start_point geometry,
  @p_end_point   geometry
)
Returns Float
AS
/****f* COGO/STBearingBetweenPoints (2008)
 *  NAME
 *    STBearingBetweenPoints -- Returns a (Normalized) bearing in Degrees between two non-geodetic (XY) geometry points
 *  SYNOPSIS
 *    Function STBearingBetweenPoints (
 *               @p_start_point geometry,
 *               @p_end_point   geometry
 *             )
 *     Returns float 
 *  USAGE
 *    SELECT [$(cogoowner)].[STBearingBetweenPoints] (
 *             geometry::Point(0,0,0),
 *             geometry::Point(45,45,0) 
 *           ) as Bearing;
 *    Bearing
 *    45
 *  DESCRIPTION
 *    Function that computes the bearing from the supplied start point to the supplied end point.
 *    The result is expressed as a whole circle bearing in decimal degrees.
 *  INPUTS
 *    @p_start_point (geometry) - Start point.
 *    @p_end_point   (geometry) - End point.
 *  RESULT
 *    decimal degrees (float) - Bearing between point 1 and 2 from 0-360.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2008 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  If (@p_start_point IS NULL OR @p_end_point IS NULL)
    Return NULL;
  Return [$(cogoowner)].[STBearing] (
            @p_start_point.STStartPoint().STX,
            @p_start_point.STStartPoint().STY,
            @p_end_point.STStartPoint().STX,
            @p_end_point.STStartPoint().STY
         );
End;
GO

Print '3. STPointFromBearingDistance ....';
GO

CREATE FUNCTION [$(cogoowner)].[STPointFromBearingAndDistance] 
(
  @p_dStartE   Float,
  @p_dStartN   Float,
  @p_dBearing  Float,
  @p_dDistance Float,
  @p_round_xy  int = 3,
  @p_srid      int = 0 
)
RETURNS geometry
AS
/****f* COGO/STPointFromBearingAndDistance (2008)
 *  NAME
 *    STPointFromBearingAndDistance -- Returns a projected point given starting point, a bearing in Degrees, and a distance (geometry SRID units).
 *  SYNOPSIS
 *    Function STPointFromBearingAndDistance (
 *               @p_dStartE   float,
 *               @p_dStartN   float,
 *               @p_dBearing  float,
 *               @p_dDistance float
 *               @p_round_xy  int = 3,
 *               @p_srid      int = 0 
 *             )
 *     Returns float 
 *  USAGE
 *    SELECT [$(cogoowner)].[STPointFromBearingAndDistance] (0,0,45,100,3,0).STAsText() as endPoint;
 *    endPoint
 *    POINT (70.711 70.711)
 *  DESCRIPTION
 *    Function that computes a new point given a starting coordinate, a whole circle bearing and a distance (SRID Units).
 *    Returned point's XY ordinates are rounded to @p_round_xy decimal digits of precision.
 *    @p_SRID is the SRID of the supplied start point.
 *  INPUTS
 *    @p_dStartE   (float) - Easting of starting point.
 *    @p_dStartN   (float) - Northing of starting point.
 *    @p_dBearing  (float) - Whole circle bearing between 0 and 360 degrees.
 *    @p_dDistance (float) - Distance in SRID units from starting point to required point.
 *    @p_round_xy    (int) - XY ordinates decimal digitis of precision.
 *    @p_srid        (int) - SRID associated with @p_dStartE/p_dStartN.
 *  RESULT
 *    point    (geometry) - Point
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @dBearing   Float,
    @dAngle1    Float,
    @dAngle1Rad Float,
    @dDeltaN    Float,
    @dDeltaE    Float,
    @dEndE      Float,
    @dEndN      Float,
    @v_round_xy int = ISNULL(@p_round_xy,3),
    @v_srid     int = ISNULL(@p_srid    ,0);
  BEGIN
    IF ( @p_dStartE   IS NULL OR
         @p_dStartN   IS NULL OR
         @p_dBearing  IS NULL OR
         @p_dDistance IS NULL )
      RETURN NULL;

    SET @dBearing = ABS(@p_dBearing);

    -- First calculate dDeltaE and dDeltaN
    IF ( @dBearing < CAST(90.0 as float) )
    BEGIN
      SET @dAngle1    = CAST(90.0 as float) - @dBearing;
      SET @dAngle1Rad = @dAngle1 * PI() / CAST(180.0 as float)
      SET @dDeltaE    = Cos(@dAngle1Rad) * @p_dDistance;
      SET @dDeltaN    = Sin(@dAngle1Rad) * @p_dDistance;
      -- Calculate the easting and northing of the end point
      SET @dEndE      = @p_dStartE + @dDeltaE;
      SET @dEndN      = @p_dStartN + @dDeltaN;
      RETURN geometry::Point(ROUND(@dEndE,@v_round_xy),ROUND(@dEndN,@v_round_xy), @v_srid);
    END;

    IF ( @dBearing < CAST(180.0 as float) )
    BEGIN
      SET @dAngle1    = @dBearing - CAST(90.0 AS float);
      SET @dAngle1Rad = @dAngle1 * PI() / CAST(180.0 AS float);
      SET @dDeltaE    = Cos(@dAngle1Rad) * @p_dDistance;
      SET @dDeltaN    = Sin(@dAngle1Rad) * @p_dDistance * -1;
      -- Calculate the easting and northing of the end point
      SET @dEndE      = @p_dStartE + @dDeltaE;
      SET @dEndN      = @p_dStartN + @dDeltaN;
      RETURN geometry::Point(ROUND(@dEndE,@v_round_xy),ROUND(@dEndN,@v_round_xy), @v_srid);
    END;

    IF ( @dBearing < CAST(270.0 AS float) )
    BEGIN
      SET @dAngle1    = CAST(270.0 AS float) - @dBearing;
      SET @dAngle1Rad = @dAngle1 * PI() / CAST(180.0 AS float);
      SET @dDeltaE    = Cos(@dAngle1Rad) * @p_dDistance * -1;
      SET @dDeltaN    = Sin(@dAngle1Rad) * @p_dDistance * -1;
      -- Calculate the easting and northing of the end point
      SET @dEndE      = @p_dStartE + @dDeltaE;
      SET @dEndN      = @p_dStartN + @dDeltaN;
      RETURN geometry::Point(ROUND(@dEndE,@v_round_xy),ROUND(@dEndN,@v_round_xy), @v_srid);
    END;

    IF ( @dBearing <= CAST(360.0 AS float) )
    BEGIN
      SET @dAngle1    = @dBearing - CAST(270.0 AS float);
      SET @dAngle1Rad = @dAngle1 * PI() / CAST(180.0 as float);
      SET @dDeltaE    = Cos(@dAngle1Rad) * @p_dDistance * -1;
      SET @dDeltaN    = Sin(@dAngle1Rad) * @p_dDistance;
      -- Calculate the easting and northing of the end point
      SET @dEndE      = @p_dStartE + @dDeltaE;
      SET @dEndN      = @p_dStartN + @dDeltaN;
      RETURN geometry::Point(ROUND(@dEndE,@v_round_xy),ROUND(@dEndN,@v_round_xy), @v_srid);
    End;
    Return null;
  END;
END
GO

Print '4. STPointFromCogo (wrapper) ...'
GO

CREATE FUNCTION [$(cogoowner)].[STPointFromCOGO] 
(
  @p_Start_point geometry,
  @p_dBearing    Float,
  @p_dDistance   Float,
  @p_round_xy    int = 3
)
RETURNS geometry
AS
/****f* COGO/STPointFromCOGO (2008)
 *  NAME
 *    STPointFromCOGO -- Returns a projected point given starting point, a bearing in Degrees, and a distance (geometry SRID units).
 *  SYNOPSIS
 *    Function STPointFromCOGO (
 *               @p_Start_Point geometry,
 *               @p_dBearing    float,
 *               @p_dDistance   float
 *               @p_round_xy    int = 3
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(cogoowner)].[STPointFromCOGO] (geometry::Point(0,0,0),45,100,3).STAsText() as endPoint;
 *    endPoint
 *    POINT (70.711 70.711)
 *  DESCRIPTION
 *    Is a wrapper function over STPointFromBearingAndDistance.
 *    Function that computes a new point given a starting coordinate, a whole circle bearing and a distance (SRID Units).
 *    Returned point's XY ordinates are rounded to @p_round_xy  decimal digits of precision.
 *    SRID of the returned geometry is the SRID supplied start point.
 *  INPUTS
 *    @p_Start_Point (geometry) - Starting point.
 *    @p_dBearing       (float) - Whole circle bearing between 0 and 360 degrees.
 *    @p_dDistance      (float) - Distance in SRID units from starting point to required point.
 *    @p_round_xy         (int) -    XY ordinates decimal digitis of precision.
 *  RESULT
 *    point          (geometry) - Point
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return [$(cogoowner)].[STPointFromBearingAndDistance] (
          /* @p_dStartE   */ @p_start_point.STX,
          /* @p_dStartN   */ @p_start_point.STY,
          /* @p_dBearing  */ @p_dBearing,
          /* @p_dDistance */ @p_dDistance,
          /* @p_round_xy  */ @p_round_xy,
          /* @p_srid      */ @p_start_point.STSrid
       );
END
GO

Print '*****************************';
Print 'Testing ...';
GO

select [$(cogoowner)].[STBearing](0,0,45,45) as Bearing
GO

select [$(cogoowner)].[STPointFromBearingAndDistance](0,0,45,100,3,0).STAsText()
GO

select g.IntValue as bearing, 
       [$(cogoowner)].[STPointFromBearingAndDistance](0,0,g.IntValue,100,3,0).AsTextZM() as point
  from [$(owner)].[GENERATE_SERIES] (0,350,10) as g;
GO

SELECT [$(cogoowner)].[STPointFromCOGO] (geometry::Point(0,0,0),45,100,3).STAsText() as endPoint;
GO

