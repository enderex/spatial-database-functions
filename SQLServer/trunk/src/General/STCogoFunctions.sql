SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STCreateCircle]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STCreateCircle];
  PRINT 'Dropped [$(cogoowner)].[STCreateCircle] ...';
END;
GO

-- Start Find Circle Functions ...

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STFindCircle]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindCircle];
  PRINT 'Dropped [$(cogoowner)].[STFindCircle] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STFindCircleByPoint]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindCircleByPoint];
  PRINT 'Dropped [$(cogoowner)].[STFindCircleByPoint] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STFindCircleFromArc]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindCircleFromArc];
  PRINT 'Dropped [$(cogoowner)].[STFindCircleFromArc] ...';
END;
GO

-- End Find Circle Functions ...

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STCircle2Polygon]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STCircle2Polygon];
  PRINT 'Dropped [$(cogoowner)].[STCircle2Polygon] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STOptimalCircleSegments]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STOptimalCircleSegments];
  PRINT 'Dropped [$(cogoowner)].[STOptimalCircleSegments] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STComputeChordLength]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STComputeChordLength];
  PRINT 'Dropped [$(cogoowner)].[STComputeChordLength] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STComputeArcLength]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STComputeArcLength];
  PRINT 'Dropped [$(cogoowner)].[STComputeArcLength] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STArcToChordSeparation]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STArcToChordSeparation];
  PRINT 'Dropped [$(cogoowner)].[STArcToChordSeparation] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STSubtendedAngle]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STSubtendedAngle];
  PRINT 'Dropped [$(cogoowner)].[STSubtendedAngle] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STSubtendedAngleByPoint]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STSubtendedAngleByPoint];
  PRINT 'Dropped [$(cogoowner)].[STSubtendedAngleByPoint] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STisClockwiseArc]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STisClockwiseArc];
  PRINT 'Dropped [$(cogoowner)].[STisClockwiseArc] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STisClockwiseAngle]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STisClockwiseAngle];
  PRINT 'Dropped [$(cogoowner)].[STisClockwiseAngle] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STCrossProductLength]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STCrossProductLength];
  PRINT 'Dropped [$(cogoowner)].[STCrossProductLength] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STDotProduct]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STDotProduct];
  PRINT 'Dropped [$(cogoowner)].[STDotProduct] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STCreateCircle] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STCreateCircle]
(
  @dCentreX Float,
  @dCentreY Float,
  @dRadius  Float,
  @iSrid    Int = 0,
  @iRound   Int = 3
)
Returns geometry
AS
/****f* COGO/STCreateCircle (2012)
 *  NAME
 *    STCreateCircle -- Creates Circular polygon from Centre XY, Radius, Srid and Ordinate Round
 *  SYNOPSIS
 *    Function STCreateCircle ( 
 *               @dCentreX Float,
 *               @dCentreY Float,
 *               @dRadius  Float
 *               @iSrid    int,
 *               @iRound   Int = 3
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    Given a 3 points defining a circular arc this function computes the centre and radius of the circle of 
 *    which it is a part of its circumference.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *    Only supports SQL Server Spatial 2012 onwards as 2008 does not support CURVEPOLYGONs
 *  INPUTS
 *    dCentreX   (float) : X Ordinate of centre of Circle
 *    @dCentreY  (float) : Y Ordinate of centre of Circle
 *    @dRadius   (float) : Radius of Circle
 *    @dSrid       (int) : Spatial Reference Id of geometry
 *    @iRound      (int) : Float of decimal digits for ordinates.
 *  RESULT
 *    polygon (geometry) : Circle as CURVEPOLYGON object
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - Oct 2015 - Original coding for TSQL.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @vSrid  int = ISNULL(@iSrid,0),
    @vRound int = ISNULL(@iRound,3);
  BEGIN
    RETURN geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE(CIRCULARSTRING(' +
       LTRIM(STR(round(@dCentreX - @dRadius,@vRound),24,@vRound)) + ' ' + 
       LTRIM(STR(round(@dCentreY           ,@vRound),24,@vRound)) + ',' +
       LTRIM(STR(round(@dCentreX           ,@vRound),24,@vRound)) + ' ' + 
       LTRIM(STR(round(@dCentreY - @dRadius,@vRound),24,@vRound)) + ',' +
       LTRIM(STR(round(@dCentreX + @dRadius,@vRound),24,@vRound)) + ' ' + 
       LTRIM(STR(round(@dCentreY           ,@vRound),24,@vRound)) + ',' +
       LTRIM(STR(round(@dCentreX           ,@vRound),24,@vRound)) + ' ' + 
       LTRIM(STR(round(@dCentreY + @dRadius,@vRound),24,@vRound)) + ',' +
       LTRIM(STR(round(@dCentreX - @dRadius,@vRound),24,@vRound)) + ' ' + 
       LTRIM(STR(round(@dCentreY           ,@vRound),24,@vRound)) + ')))',@iSrid);
  END;
End;
Go

PRINT 'Creating [$(cogoowner)].[STFindCircle] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindCircle] 
(
  @p_X1   float, @p_Y1 float,
  @p_X2   float, @p_Y2 float,
  @p_X3   float, @p_Y3 float,
  @p_SRID int = 0
)
Returns geometry
As
/****m* COGO/STFindCircle (2008)
 *  NAME
 *    STFindCircle -- Finds a circle's centre X and Y and Radius from three points.
 *  SYNOPSIS
 *     Function STFindCircle ( 
 *                @p_X1 float, @p_Y1 float,
 *                @p_X2 float, @p_Y2 float,
 *                @p_X3 float, @p_Y3 float,
 *                @p_SRID int)
 *       Returns Geometry
 *  DESCRIPTION
 *    Given a 3 points defining a circular arc this function computes the centre and radius of the circle of 
 *    which it is a part of its circumference.
 *  NOTES 
 *    Returns geometry POINT with X = CX, Y = CY, Z = Radius.
 *    Returns -1 as value of all parameters if three points do not define a circle.
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_X1   (Float) : X ordinate of first point on circle
 *    @p_Y1   (Float) : Y ordinate of first point on circle
 *    @p_X2   (Float) : X ordinate of second point on circle
 *    @p_Y2   (Float) : Y ordinate of second point on circle
 *    @p_X3   (Float) : X ordinate of third point on circle
 *    @p_Y3   (Float) : Y ordinate of third point on circle
 *    @p_SRID (int)   : Planar SRID value.
 *  RESULT
 *    Point (geometry) : X ordinate of centre of circle.
 *                       Y ordinate of centre of circle.
 *                       Z radius of circle.
 *                       SRID as supplied.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original coding.
 *    Simon Greener - January 2020  -- Removed call to STMakePoint to speed up funtion.
 *  COPYRIGHT
 *    (c) 2012-2020 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    @cTol      float = 0.0000001,
    @vOffset   float, 
    @vBc       float,
    @vCd       float,
    @vDet      float,
    @viDet     float,
    @vCX       float,
    @vCY       float,
    @vRadius   float,
    @center    geometry;

  IF ( @p_X1 is null or @p_Y1 is null 
    or @p_X2 is null or @p_Y2 is null 
    or @p_X3 is null or @p_Y3 is null )
   Return NULL;

  SET @vOffset =   POWER(@p_X2,2.0) + POWER(@p_Y2,2.0);
  SET @vBc     = ( POWER(@p_X1,2.0) + POWER(@p_Y1,2.0) - @vOffset ) / CAST(2.0 as float);
  SET @vCd     = ( @vOffset - POWER(@p_X3,2.0) - POWER(@p_Y3,2.0) ) / CAST(2.0 as float);
  SET @vDet    = ( @p_X1 - @p_X2 ) 
               * ( @p_Y2 - @p_Y3 )
               - ( @p_X2 - @p_X3 )
               * ( @p_Y1 - @p_Y2 ); 
  if (ABS(@vDet) < @cTol) 
    Return geometry::Parse('POINT(-1 -1 -1)');
  SET @vIdet   = CAST(1.0 as float) / @vDet;
  SET @vCX     = ( @vBc * (@p_Y2 - @p_Y3) - @vCd * (@p_Y1 - @p_Y2) ) * @viDet;
  SET @vCY     = ( @vCd * (@p_X1 - @p_X2) - @vBc * (@p_X2 - @p_X3) ) * @viDet;
  SET @vRadius = SQRT( POWER(@p_X2 - @vCX,2.0) + POWER(@p_Y2 - @vCY,2.0));
  Return geometry::STGeomFromText(
           'POINT(' + FORMAT(@vCX,    '#######################0.###############')+ ' ' + 
                      FORMAT(@vCY,    '#######################0.###############')+ ' ' + 
                      FORMAT(@vRadius,'#######################0.###############')  +
           ')'
           ,ISNULL(@p_srid,0)
         );
End;
GO

PRINT 'Creating [$(cogoowner)].[STFindCircleByPoint] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindCircleByPoint] 
(
  @p_point_1 geometry,
  @p_point_2 geometry,
  @p_point_3 geometry
)
Returns geometry
As
/****f* COGO/STFindCircleByPoint (2012)
 *  NAME
 *    STFindCircleByPoint -- Finds the circle centre X and Y and Radius for supplied three points.
 *  SYNOPSIS
 *     Function STFindCircleByPoint ( 
 *                 @p_point_1 geometry,
 *                 @p_point_2 geometry,
 *                 @p_point_3 geometry
 *              )
 *      Returns Geometry
 *  DESCRIPTION
 *    Given 3 points on circumference of a circle this function computes the centre and radius of the circle that defines it.
 *  NOTES
 *    Returns geometry POINT with X = CX, Y = CY, Z = Radius.
 *    Returns -1 as value of all parameters if three points do not define a circle.
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_point_1 (geometry) - First point on circumference of circle
 *    @p_point_2 (geometry) - Second point on circumference of circle
 *    @p_point_3 (geometry) - Third point on circumference of circle
 *  RESULT
 *    Point           (geometry) : With STX = CX, STY = CY, Z = Radius, STSrid = @p_circular_arc.STSrid
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  IF ( @p_point_1 is null or @p_point_2 is null or @p_point_3 is null  )
    Return NULL;
  IF ( @p_point_1.STGeometryType() <> 'Point' or 
       @p_point_2.STGeometryType() <> 'Point' or
       @p_point_3.STGeometryType() <> 'Point' )
    Return Null;
  IF ( ISNULL(@p_point_1.STSrid,0) <> ISNULL(@p_point_2.STSrid,0) OR
       ISNULL(@p_point_1.STSrid,0) <> ISNULL(@p_point_3.STSrid,0) ) 
    Return NULL;
  Return [$(cogoowner)].[STFindCircle] (
                      /* @p_X1   */ @p_point_1.STX, 
                      /* @p_Y1   */ @p_point_1.STY, 
                      /* @p_X2   */ @p_point_2.STX, 
                      /* @p_Y2   */ @p_point_2.STY, 
                      /* @p_X3   */ @p_point_3.STX, 
                      /* @p_Y3   */ @p_point_3.STY, 
                      /* @p_SRID */ @p_point_1.STSrid 
                    );
End;
GO

PRINT 'Creating [$(cogoowner)].[STFindCircleFromArc] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindCircleFromArc] 
(
  @p_circular_arc geometry
)
Returns geometry
As
/****f* COGO/STFindCircleFromArc (2012)
 *  NAME
 *    STFindCircleFromArc -- Finds the circle centre X and Y and Radius for supplied CircularString
 *  SYNOPSIS
 *     Function STFindCircleFromArc ( 
 *                @p_circular_arc geometry 
 *              )
 *      Returns Geometry
 *  DESCRIPTION
 *    Given a 3 point circular arc this function computes the centre and radius of the circle that defines it.
 *  NOTES
 *    Returns geometry POINT with X = CX, Y = CY, Z = Radius.
 *    Returns -1 as value of all parameters if three points do not define a circle.
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_circular_arc (geometry) : 3 Point Circular Arc geometry
 *  RESULT
 *    Point           (geometry) : With STX = CX, STY = CY, Z = Radius, STSrid = @p_circular_arc.STSrid
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @cTol      float = 0.0000001,
    @vOffset   float, 
    @vBc       float,
    @vCd       float,
    @vDet      float,
    @viDet     float,
    @vCX       float,
    @vCY       float,
    @vRadius   float,
    @center    geometry;
  Begin
    IF ( @p_circular_arc is null )
      Return NULL;
    IF ( @p_Circular_arc.STGeometryType() <> 'CircularString' )
      Return NULL;
    SET @vOffset = POWER(@p_circular_arc.STPointN(2).STX,2) 
                   + 
                   POWER(@p_circular_arc.STPointN(2).STY,2);
    SET @vBc     = POWER(@p_circular_arc.STPointN(1).STX,2) 
                   + 
                   POWER(@p_circular_arc.STPointN(1).STY,2) 
                   - 
                   @vOffset;
    SET @vBc     = @vBc / CAST(2.0 as float);
    SET @vCd     = ( @vOffset 
                   - POWER(@p_circular_arc.STPointN(3).STX,2) 
                   - POWER(@p_circular_arc.STPointN(3).STY,2)
                   );
    SET @vCd     = @vCd / CAST(2.0 as float);
    SET @vDet    = (  (@p_circular_arc.STPointN(1).STX - @p_circular_arc.STPointN(2).STX ) 
                    * (@p_circular_arc.STPointN(2).STY - @p_circular_arc.STPointN(3).STY)
                   )
                   - 
                   (  (@p_circular_arc.STPointN(2).STX - @p_circular_arc.STPointN(3).STX)
                    * (@p_circular_arc.STPointN(1).STY - @p_circular_arc.STPointN(2).STY)
                   ); 
    if (ABS(@vDet) < @cTol) 
      Return geometry::Parse('POINT(-1 -1 -1)');
    SET @vIdet   = CAST(1.0 as float) / @vDet;
    SET @vCX     =  (  (@vBc * (@p_circular_arc.STPointN(2).STY - @p_circular_arc.STPointN(3).STY))
                     - (@vCd * (@p_circular_arc.STPointN(1).STY - @p_circular_arc.STPointN(2).STY))
                    );
    SET @vCX     = @vCX * @viDet;
    SET @vCY     =  (  (@vCd * (@p_circular_arc.STPointN(1).STX - @p_circular_arc.STPointN(2).STX))
                     - (@vBc * (@p_circular_arc.STPointN(2).STX - @p_circular_arc.STPointN(3).STX))
                    );
    SET @vCY     = @vCY * @viDet;
    SET @vRadius = SQRT(
                     POWER(@p_circular_arc.STPointN(2).STX - @vCX,2) 
                     + 
                     POWER(@p_circular_arc.STPointN(2).STY - @vCY,2)
                   );
    Return [$(owner)].[STMakePoint](/* @p_x    */ @vCX, 
                                    /* @p_y    */ @vCY, 
                                    /* @p_z    */ @vRadius, 
                                    /* @p_m    */ NULL,  
                                    /* @p_srid */ @p_circular_arc.STSrid);
  END;
End;
GO

PRINT 'Creating [$(cogoowner)].[STCirclePolygon] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STCircle2Polygon] 
(
  @p_dCentreX  float,
  @p_dCentreY  float,
  @p_dRadius   float,
  @p_iSegments int,
  @p_srid      int,
  @p_round_xy  int = 3
)
Returns geometry
As
/****f* COGO/STCircle2Polygon (2008)
 *  NAME
 *    STCircle2Polygon -- Returns stroked Polygon shape from circle definition of centre XY and radius.
 *  SYNOPSIS
 *    Function STCircle2Polygon ( 
 *               @p_dCentreX  Float,
 *               @p_dCentreY  Float,
 *               @p_dRadius   Float
 *               @p_iSegments int
 *               @p_srid      int,
 *               @p_round_xy  Int = 3
 *             )
 *     Returns geometry
*   SELECT [$(cogoowner)].[STCircle2polygon](100,100,5.0,144,0,3);
 *  DESCRIPTION
 *    Given a 3 points defining a circular arc this function computes the centre and radius of the circle of 
 *    which it is a part of its circumference.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *    Created polyon geometry has required ring rotation.
 *  INPUTS
 *    @p_dCentreX  (float) : X Ordinate of centre of Circle
 *    @p_dCentreY  (float) : Y Ordinate of centre of Circle
 *    @p_dRadius   (float) : Radius of Circle
 *    @p_iSegments   (int) : Number of arc (chord) segments in circle (+ve clockwise, -ve anti-clockwise)
 *    @p_Srid        (int) : Spatial Reference Id of geometry
 *    @p_Round_xy    (int) : Precision of any XY ordinate value ie number of significant digits. If null then 3 is assumed (ie 1 mm): 3456.2345245 -> 3456.235.
 *  RESULT
 *    polygon   (geometry) : Circle as stroked polygon.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - May 2011 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @dStartX      Float,
    @dStartY      Float,
    @dX           Float,
    @dY           Float,
    @dTheta       Float,
    @dDeltaTheta  Float,
    @iSeg         int,
    @iSegments    int = CASE WHEN @p_iSegments IS NULL OR 
                                  @p_iSegments = 0     THEN 12 ELSE @p_iSegments END,
    @v_round_xy   int = ISNULL(@p_round_xy,3),
    @srid         int = CASE WHEN @p_srid      IS NULL THEN  0 ELSE @p_srid      END,
    @WKT          varchar(max);
  BEGIN
    IF ( @p_dCentreX is null OR
         @p_dCentreY is null OR
         @p_dRadius  is null )
      RETURN NULL;

    -- if @iSegments is negative then the @dDeltaTheta value will be negative and so the cirlce will be anticlockwise
    SET @dDeltaTheta  = CAST(2.0 as float) * PI() / @iSegments;
    SET @dStartX = ROUND(@p_dCentreX + @p_dRadius,@v_round_xy);
    SET @dStartY = ROUND(@p_dCentreY,             @v_round_xy);

    SET @WKT = 'POLYGON((' 
               + 
               [$(owner)].[STFormatNumber](@dStartX,@v_round_xy,'','','0') 
               + ' ' + 
               [$(owner)].[STFormatNumber](@dStartY,@v_round_xy,'','','0'); 
    -- Sign is no longer needed
    SET @iSegments = ABS(@iSegments);
    SET @dTheta = 0.0;
    SET @iSeg = 1;
    WHILE ( @iSeg <= @iSegments )
    BEGIN
      SET @dTheta = @dTheta + @dDeltaTheta;
      SET @dX = ROUND(@p_dCentreX + @p_dRadius * COS(@dTheta),@v_round_xy);
      SET @dY = ROUND(@p_dCentreY + @p_dRadius * SIN(@dTheta),@v_round_xy);
      SET @WKT = @WKT 
                 + ',' + 
                 [$(owner)].[STFormatNumber](@dX,@v_round_xy,'','','0') 
                 + ' ' + 
                 [$(owner)].[STFormatNumber](@dY,@v_round_xy,'','','0');
      SET @iSeg = @iSeg + 1;
    END;
    IF ( @dStartX <> @dX OR @dStartY <> @dY )
    BEGIN
       SET @WKT = @WKT 
                  + ',' + 
                  [$(owner)].[STFormatNumber](@dStartX,@v_round_xy,'','','0') 
                  + ' ' + 
                  [$(owner)].[STFormatNumber](@dStartY,@v_round_xy,'','','0');
    END;
    -- Terminate polygon WKT
    SET @WKT = @WKT + '))';
    RETURN geometry::STGeomFromText(@WKT,@srid);
  END;
End;
GO

PRINT 'Creating [$(cogoowner)].[STOptimalCircleSegments] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STOptimalCircleSegments]
(
  @p_dRadius               Float,
  @p_dArcToChordSeparation Float
)
Returns Int
As
/****f* COGO/STOptimalCircleSegments (2008)
 *  NAME
 *    STOptimalCircleSegments -- Computes optimal number of chord segments to stroke circle as vertex-connected polygon.
 *  SYNOPSIS
 *    Function STOptimalCircleSegments ( 
 *                @p_dRadius               Float,
 *                @p_dArcToChordSeparation Float
 *             )
 *     Returns int
 *    SELECT [$(cogoowner)].[STOptimalCircleSegments](100, 0.003);
 *  DESCRIPTION
 *    Returns the optimal integer number of circle segments for an arc-to-chord separation given the radius
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_dRadius               (float) : Radius of Circle
 *    @p_dArcToChordSeparation (float) : Distance between the midpoint of the Arc and the Chord in metres
 *  RESULT
 *    number of segments         (int) : The optimal number of segments at the given arc2chord separation
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - May 2011 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_dAngleRad              Float,
    @v_dCentreToChordMidPoint Float;
  Begin
    SET @v_dCentreToChordMidPoint = @p_dRadius - @p_dArcToChordSeparation;
    SET @v_dAngleRad              = CAST(2.0 as float) * aCos(@v_dCentreToChordMidPoint/@p_dRadius);
    Return CEILING( (CAST(2.0 as float) * PI() ) / @v_dAngleRad );
  End;
END;
GO
    
PRINT 'Creating [$(cogoowner)].[STComputeChordLength] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STComputeChordLength] 
(
  @p_dRadius Float,
  @p_dAngle  Float
)
 Returns Float
As
/****f* COGO/STComputeChordLength (2008)
 *  NAME
 *    STComputeChordLength -- Returns the length of the chord for an angle given the radius.
 *  SYNOPSIS
 *    Function STComputeChordLength ( 
 *                @p_dRadius Float,
 *                @p_dAngle  Float
 *             )
 *     Returns float
 *    SELECT [$(cogoowner)].[STComputeChordLength](100, 0.003);
 *  DESCRIPTION
 *    Returns the length of the chord subtended by an angle (degrees between 0 and 360) at the centre of a circular of radius @p_dRadius.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_dRadius   (float) : Radius of Circle.
 *    @p_dAngle    (float) : The Angle subtended at the centre of the circle in degrees between 0 and 360.
 *  RESULT
 *    ChordLength  (float) : The length of the chord in metres.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - May 2011 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_dChord    Float,
    @v_dAngleRad Float;
  Begin
    SET @v_dAngleRad = ( @p_dAngle / CAST(180.0 as float) ) * PI();
    SET @v_dChord    = CAST(2.0 as float) * @p_dRadius * SIN(@v_dAngleRad / CAST(2.0 as float) );
    Return @v_dChord;
  End;
End;
GO

PRINT 'Creating [$(cogoowner)].[STComputeArcLength] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STComputeArcLength] 
( 
  @p_dRadius Float,
  @p_dAngle  Float
)
Returns Float
As
/****f* COGO/STComputeArcLength (2008)
 *  NAME
 *    STComputeArcLength -- Returns the length of the Circular Arc subtended by @p_dAngle (degrees between 0 and 360) at the centre of a circular of radius @p_dRadius.
 *  SYNOPSIS
 *    Function STComputeArcLength ( 
 *                @p_dRadius Float,
 *                @p_dAngle  Float
 *             )
 *     Returns float
 *    SELECT [$(cogoowner)].[STComputeArcLength](100, 0.003);
 *  DESCRIPTION
 *    Returns the length of the chord subtended by the supplied angle (degrees between 0 and 360) at the centre of a circular with the given radius.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_dRadius (float) : Radius of Circle.
 *    @p_dAngle  (float) : The Angle subtended at the centre of the circle in degrees between 0 and 360.
 *  RESULT
 *    ArcLength  (float) : The length of the circular arc.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - Feb 2015 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_dArc      Float,
    @v_dAngleRad Float;
  Begin
    SET @v_dAngleRad = ( @p_dAngle / CAST(180.0 as float) ) * PI();
    SET @v_dArc      = @p_dRadius * @v_dAngleRad;
    Return @v_dArc;
  End;
End;
Go

PRINT 'Creating [$(cogoowner)].[STArcToChordSeparation] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STArcToChordSeparation] 
( 
  @p_dRadius Float,
  @p_dAngle  Float
)
Returns Float 
As
/****f* COGO/STArcToChordSeparation (2008)
 *  NAME
 *    STArcToChordSeparation -- Returns the distance between the midpoint of the Arc and the Chord for an angle given the radius
 *  SYNOPSIS
 *    Function STArcToChordSeparation ( 
 *               @p_dRadius Float,
 *               @p_dAngle  Float
 *             )
 *     Returns float
 *    SELECT [$(cogoowner)].[STArcToChordSeparation](100, 10);
 *  DESCRIPTION
 *    Chords are needed when "stroking" a circularstring to a vertex-connected linestring.
 *    To do this, one needs to compute such parameters as arc length, chord length and arc to chord separation.
 *    The arc to chord separation is important in that large values create linestring segments that clearly diverge from the cicular arc.
 *    Different values therefore given different ascetic results.
 *    This function computes the arc to chord separation (meters or in srid distance units) given a radius and an 
 *    angle (degrees 0..360) subtended at the centre of the circle defining the CircularString
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_dRadius          (float) : Radius of Circle.
 *    @p_dAngle           (float) : The Angle subtended at the centre of the circle in degrees between 0 and 360.
 *  RESULT
 *    separation distance (float) - ArcToChord separation distance.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - Feb 2015 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_dAngleRad              Float,
    @v_dCentreToChordMidPoint Float,
    @v_dArcChordSeparation    Float;
  BegiN
    SET @v_dAngleRad              = ( @p_dAngle / CAST(180.0 as float) ) * PI();
    SET @v_dCentreToChordMidPoint = @p_dRadius * COS(@v_dAngleRad/CAST(2.0 as float));
    SET @v_dArcChordSeparation    = @p_dRadius - @v_dCentreToChordMidPoint;
    Return @v_dArcChordSeparation;
  End;
End;
Go

PRINT 'Creating [$(cogoowner)].[STCrossProductLength] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STCrossProductLength]
(
  @dStartX  float,
  @dStartY  float,
  @dCentreX float,
  @dCentreY float,
  @dEndX    float,
  @dEndY    float
)
Returns Float 
AS
/****f* COGO/STCrossProductLength (2008)
 *  NAME
 *    STCrossProductLength -- Computes cross product between two vectors subtended at centre.
 *  SYNOPSIS
 *    Function STCrossProductLength ( 
 *               @dStartX  float,
 *               @dStartY  float,
 *               @dCentreX float,
 *               @dCentreY float,
 *               @dEndX    float,
 *               @dEndY    float
 *             )
 *     Returns float
 *  DESCRIPTION
 *    Computes cross product between vector Centre/Start and Centre/ENd
 *  INPUTS
 *    @dStartX      (float) - X Ordinate of end of first vector
 *    @dStartY      (float) - Y Ordinate of end of first vector
 *    @dCentreX     (float) - X Ordinate of common end point of vectors
 *    @dCentreY     (float) - Y Ordinate of common end point of vectors
 *    @dEndX        (float) - X Ordinate of end of second vector
 *    @dEndY        (float) - Y Ordinate of end of second vector
 *  RESULT
 *    cross product (float) - FLoating point cross product value
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - Feb 2011 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @dCentreStartX float,
    @dCentreStartY float,
    @dCentreEndX   float,
    @dCentreEndY   float;
  BEGIN
    --Get the vectors' coordinates.
    SET @dCentreStartX = @dStartX - @dCentreX;
    SET @dCentreStartY = @dStartY - @dCentreY;
    SET @dCentreEndX   = @dEndX   - @dCentreX;
    SET @dCentreEndY   = @dEndY   - @dCentreY;
    -- Calculate the Z coordinate of the cross product.
    Return (@dCentreStartX * @dCentreEndY) 
           - 
           (@dCentreStartY * @dCentreEndX);
  END;
End;
Go

PRINT 'Creating [$(cogoowner)].[STDotProduct] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STDotProduct]
(
  @dStartX  float,
  @dStartY  float,
  @dCentreX float,
  @dCentreY float,
  @dEndX    float,
  @dEndY    float
)
Returns Float 
AS
/****f* COGO/STDotProduct (2008)
 *  NAME
 *    STDotProduct -- Computes Dot product between two vectors subtended at centre.
 *  SYNOPSIS
 *    Function STDotProduct ( 
 *               @dStartX  float,
 *               @dStartY  float,
 *               @dCentreX float,
 *               @dCentreY float,
 *               @dEndX    float,
 *               @dEndY    float
 *             )
 *     Returns float
 *  DESCRIPTION
 *    Computes Dot product between vector Centre/Start and Centre/ENd
 *  INPUTS
 *    @dStartX    (float) - X Ordinate of end of first vector
 *    @dStartY    (float) - Y Ordinate of end of first vector
 *    @dCentreX   (float) - X Ordinate of common end point of vectors
 *    @dCentreY   (float) - Y Ordinate of common end point of vectors
 *    @dEndX      (float) - X Ordinate of end of second vector
 *    @dEndY      (float) - Y Ordinate of end of second vector
 *  RESULT
 *    Dot product (float) - FLoating point Dot product value
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *   Simon Greener - Feb 2011 - Converted to TSQL for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @dCentreStartX float,
    @dCentreStartY float,
    @dCentreEndX   float,
    @dCentreEndY   float;
  BEGIN
    --Get the vectors' coordinates.
    SET @dCentreStartX = @dStartX - @dCentreX;
    SET @dCentreStartY = @dStartY - @dCentreY;
    SET @dCentreEndX   =   @dEndX - @dCentreX;
    SET @dCentreEndY   =   @dEndY - @dCentreY;
    --Calculate the dot product.
    Return (@dCentreStartX * @dCentreEndX) 
           + 
           (@dCentreStartY * @dCentreEndY);
  END;
End;
Go

PRINT 'Creating [$(cogoowner)].[STSubtendedAngle] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STSubtendedAngle]
(
  @p_startX  float,
  @p_startY  float,
  @p_centreX float,
  @p_centreY float,
  @p_endX    float,
  @p_endY    float
)
Returns float
AS
/****f* COGO/STSubtendedAngle (2008)
 *  NAME
 *    STSubtendedAngle - Returns the angle (radians) between three points.
 *  SYNOPSIS
 *    Function STSubtendedAngle (
 *               @p_startX  float,
 *               @p_startY  float,
 *               @p_centreX float,
 *               @p_centreY float,
 *               @p_endX    float,
 *               @p_endY    float
 *             )
 *     Returns float (angle in radians)
 *  DESCRIPTION
 *    Supplied with three points, this function computes the angle from the first to the third subtended by the seconds.
 *    Angle could be positive or negative.
 *    Result is radians.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *    Always choses smallest angle ie 90 not 270
 *  INPUTS
 *    @p_startX  (float) - X ordinate of first point
 *    @p_startY  (float) - Y ordinate of first point
 *    @p_centreX (float) - X ordinate of first point
 *    @p_centreY (float) - Y ordinate of first point
 *    @p_endX    (float) - X ordinate of first point
 *    @p_endY    (float) - Y ordinate of first point
 *  RESULT
 *    angle      (float) - Subtended angle in radians.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_DotProduct   float,
    @v_CrossProduct float;
  Begin
    If (@p_centreX is null or @p_centreY is null 
     Or @p_startX  is null or @p_startY  is null 
     Or @p_endX    is null Or @p_endY    is null )  
       Return null;
    -- Get the dot product and cross product.
    SET @v_DotProduct   = [$(cogoowner)].[STDotProduct] (
                             @p_startX,  @p_startY, 
                             @p_centreX, @p_centreY, 
                             @p_EndX,    @p_EndY
                          );
    SET @v_CrossProduct = [$(cogoowner)].[STCrossProductLength] (
                             @p_startX,  @p_startY, 
                             @p_centreX, @p_centreY, 
                             @p_EndX,    @p_EndY
                          );
    --Calculate the angle in Radians.
    Return case when @v_CrossProduct = 0 and @v_DotProduct = 0 
                then 0.0
                else ATN2(@v_CrossProduct, @v_DotProduct)
            end;
  End;
End;
GO

PRINT 'Creating [$(cogoowner)].[STSubtendedAngleByPoint] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STSubtendedAngleByPoint]
(
  @p_start   geometry,
  @p_centre  geometry,
  @p_end     geometry
)
Returns float
AS
/****f* COGO/STSubtendedAngleByPoint (2008)
 *  NAME
 *    STSubtendedAngleByPoint - Returns the angle (radians) between three points.
 *  SYNOPSIS
 *    Function STSubtendedAngle (
 *               @p_start  geometry,
 *               @p_centre geometry,
 *               @p_end    geometry
 *             )
 *     Returns float (angle in radians)
 *  DESCRIPTION
 *    Supplied with three points, this function computes the angle from the first to the third subtended by the seconds.
 *    Angle could be positive or negative.
 *    Result is radians.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *    Always choses smallest angle ie 90 not 270
 *  INPUTS
 *    @p_start  (geometry) - First point
 *    @p_centre (geometry) - Second point
 *    @p_end    (geometry) - Third point
 *  RESULT
 *    angle      (float) - Subtended angle in radians.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_DotProduct   float,
    @v_CrossProduct float;
  Begin
    If (@p_centre is null 
     Or @p_start  is null 
     Or @p_end    is null )
       Return null;

    If (@p_centre.STGeometryType() <> 'Point'
     Or @p_start.STGeometryType()  <> 'Point'
     Or @p_end.STGeometryType()    <> 'Point' )
       Return null;

    -- Get the dot product and cross product.
    SET @v_DotProduct   = [$(cogoowner)].[STDotProduct] (
                             @p_start.STX,  @p_start.STY, 
                             @p_centre.STX, @p_centre.STY, 
                             @p_End.STX,    @p_End.STY
                          );

    SET @v_CrossProduct = [$(cogoowner)].[STCrossProductLength] (
                             @p_start.STX,  @p_start.STY, 
                             @p_centre.STX, @p_centre.STY, 
                             @p_End.STX,    @p_End.STY
                          );
    --Calculate the angle in Radians.
    Return case when @v_CrossProduct = 0 and @v_DotProduct = 0 
                then 0.0
                else ATN2(@v_CrossProduct, @v_DotProduct)
            end;
  End;
End;
GO

PRINT 'Creating [$(cogoowner)].[STisClockwiseAngle] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STisClockwiseAngle]
(
  @p_angle float
)
Returns bit
AS
/****f* COGO/STisClockwiseAngle (2008)
 *  NAME
 *   STisClockwiseAngle - Supplied with a positive or negative angle this function returns 1 or 0 to indicate if Clockwise (+) or AntiClockwise (-)
 *  SYNOPSIS
 *    Function STisClockwiseAngle (
 *               @p_angle float 
 *             )
 *     Returns bit 
 *  DESCRIPTION
 *    Supplied with an angle this function returns 1 if clockwise and 0 is anticlockwise.
 *  INPUTS
 *    @p_angle (float) - Angle in radians
 *  RESULT
 *    TrueFalse  (bit) - 1 if clockwise and 0 is anticlockwise.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  -- If SIGN >= 0 then clockwise, else anticlockwise
  RETURN case when ( SIGN(@p_angle) >= 0 ) then 1 else 0 end;
END;
GO

PRINT 'Creating [$(cogoowner)].[STisClockwiseArc] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STisClockwiseArc]
(
  @p_circular_arc geometry 
)
Returns int
AS
/****f* COGO/STisClockwiseArc (2008)
 *  NAME
 *   STisClockwiseArc - Supplied with a positive or negative angle this function returns 1 or 0 to indicate if Clockwise (+) or AntiClockwise (-)
 *  SYNOPSIS
 *    Function STisClockwiseArc (
 *               @p_circular_arc geometry 
 *             )
 *     Returns Int 
 *  DESCRIPTION
 *    Supplied with a single CircularString this function returns 1 if CircularString is defecting to the right (clockwise) or -1 to the left (anticlockwise).
 *  INPUTS
 *    @p_CircularArc (geometry) - Single CircularString geometry (3 points)
 *  RESULT
 *    TrueFalse  (bit) - 1 if clockwise and -1 is anticlockwise.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original TSQL coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  -- if circular arc is rotating anticlockwise we subtract the angle from the bearing
  Return case when [$(cogoowner)].[STCrossProductLength] (
                        @p_circular_arc.STPointN(1).STX,
                        @p_circular_arc.STPointN(1).STY,
                        @p_circular_arc.STPointN(2).STX,
                        @p_circular_arc.STPointN(2).STY,
                        @p_circular_arc.STPointN(3).STX,
                        @p_circular_arc.STPointN(3).STY
                   ) >= 0.0 
              then 1 
              else -1 
          end;
END;
GO

PRINT 'Creating [$(cogoowner)].[STComputeLengthToMidPoint] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STComputeLengthToMidPoint]
( 
  @p_circular_arc geometry
)
Returns Float
As
/****f* COGO/STComputeLengthToMidPoint (2012)
 *  NAME
 *    STComputeLengthToMidPoint - Returns the length of the arc defined by the first and second (mid) points of a CircularString.
 *  SYNOPSIS
 *    Function STComputeLengthToMidPoint (
 *               @p_circular_arc geometry 
 *             )
 *     Returns float (arc length)
 *  DESCRIPTION
 *    Supplied with a circular arc with 3 points, this function computes the arc length from the first to the second points.
 *  NOTES 
 *    Assumes planar projection eg UTM.
 *    Only supports SQL Server Spatial 2012 onwards as 2008 does not support CIRCULARSTRINGs
 *  TODO 
 *    Support measuring arc length from 1st to 3rd or 2nd to 3rd point
 *  INPUTS
 *    @p_circular_arc (geometry) - A Single CircularString with 3 points.
 *  RESULT
 *    length             (float) - The length of the arc in SRID units.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2017 - Original TSQL coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_centre geometry;
  Begin

  -- Must be supplied with a CircularString
  IF ( @p_circular_arc is null 
    or @p_circular_arc.STGeometryType() <> 'CircularString' ) 
      Return NULL;

  -- Compute centre of circle defining CircularString
  SET @v_centre = [$(cogoowner)].[STFindCircleFromArc](@p_circular_arc);

  -- Do we have a circle?
  IF (  @v_centre.STX = -1 
    and @v_centre.STY = -1 
    and @v_centre.Z   = -1 )
   Return null;

  -- Compute arc length
  RETURN ABS([$(cogoowner)].[STComputeArcLength] (
                 @v_centre.Z,
                 [$(cogoowner)].[STDegrees] (
                    [$(cogoowner)].[STSubtendedAngle] (
                       @p_circular_arc.STCurveN(1).STPointN(1).STX,
                       @p_circular_arc.STCurveN(1).STPointN(1).STY,
                       @v_centre.STX,  
                       @v_centre.STY,  
                       @p_circular_arc.STCurveN(1).STPointN(2).STX, 
                       @p_circular_arc.STCurveN(1).STPointN(2).STY
                    )
                ) 
             ) 
         );
  End;
End;
GO

