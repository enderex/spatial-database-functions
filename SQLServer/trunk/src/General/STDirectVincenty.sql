use $(usedbname)
go

SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(cogoowner)].[STDirectVincenty]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STDirectVincenty];
  Print 'Dropped [$(cogoowner)].[STDirectVincenty] ...';
END;
GO

Print 'Creating [$(cogoowner)].[STDirectVincenty] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STDirectVincenty](
  @p_point    geography,
  @p_startBearing float,
  @p_distance     float
)
Returns geography
As
/****f* COGO/STDirectVincenty (2008)
 *  NAME
 *    STDirectVincenty -- Vincenty Direct Solution of Geodesics on the Ellipsoid
 *  SYNOPSIS
 *    Function [$(owner)].[STDirectVincenty] (
 *       @p_point      geography,
 *       @p_initialBearing float,
 *       @p_distance       float
 *    )
 *    Returns geography
 *  DESCRIPTION
 *    Computes a destination point given a start point, and initial bearing, and a distance.
 *    Calculated on an ellipsoidal earth model using direct solution of geodesics on the ellipsoid devised by Thaddeus Vincenty.
 *  NOTES
 *    1. From: T Vincenty, "Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of
 *    nested equations", Survey Review, vol XXIII no 176, 1975. www.ngs.noaa.gov/PUBS_LIB/inverse.pdf.
 *    2. Ellipsoid parameters are taken from sys.spatial_reference_systems.
 *    3. The semi-major axis of the ellipse, a, becomes the equatorial radius of the ellipsoid: 
 *       the semi-minor axis of the ellipse, b, becomes the distance from the centre to either pole. 
 *       These two lengths completely specify the shape of the ellipsoid.
 *  INPUTS
 *    @p_point      (geography) - Latitude/Longitude Point
 *    @p_initialBearing (float) - Initial bearing in degrees from north.
 *    @p_distance       (float) - Distance along bearing in metres.
 *  RESULT
 *    point         (geography) - Destination point, bearing and distance from @p_point.
 *  EXAMPLE
 *    select [cogo].[STDirectVincenty](geography::Point(-42.5,147.23,4326),90.0,100.0).STAsText() as newPoint
 *    GO
 *
 *    newPoint
 *    POINT (147.23121655963791 -42.499999993543213)
 *
 *    select [cogo].[STDirectVincenty](geography::Point(55.634269978244,12.051864414446,4326),0.0,10.0).STAsText() as newPoint
 *    GO
 *
 *    newPoint
 *    POINT (12.051864414446 55.634359797125562)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Mike Gavaghan (mike@gavaghan.org) - Original Java coding (originally called "STDirectVincenty")
 *    Simon Greener - October 2019 - Ported to SQL Server TSQL.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 *    MIT Licence
 ******/
Begin
  Declare
    @A                    float,
    @B                    float,
    @C                    float,
    @L                    float,
    @semiMajorAxis        float = 6378137, -- wgs84
    @semiMajorAxisSquared float,
    @semiMajorAxislpha1   float,
    @semiMajorAxislpha2   float,
    @semiMinorAxis        float = 6356752.314245, -- wgs84
    @semiMinorAxisSquared float,
    @f                    float = 1.0/298.257223563, -- wgs84
    @a_f                  varchar(100),
    @cos2Alpha            float,
    @cos2SigmaM2          float,
    @cosAlpha1            float,
    @cosSigma             float,
    @cosSigmaM2           float,
    @cosSignma            float,
    @cosU1                float,
    @deltaSigma           float,
    @lambda               float,
    @latitude             float,
    @longitude            float,
    @phi1                 float,
    @phi2                 float,
    @prevSigma            float,
    @s                    float,
    @sOverbA              float,
    @sigma                float,
    @sigma1               float,
    @sigmaM2              float,
    @sin2Alpha            float,
    @sinAlpha             float,
    @sinAlpha1            float,
    @sinSigma             float,
    @sinU1                float,
    @tanU1                float,
    @uSquared             float;

    -- allow alternative ellipsoid to be specified
    SET @a_f = [$(cogoowner)].[STEllipsoidParameters] ( @p_point.STSrid ); 
    IF ( @a_f is not null AND LEN(@a_f) > 0 ) 
    BEGIN
      SET @a = CAST(SUBSTRING(@a_f,1,CHARINDEX(',',@a_f)-1) as float);
      SET @a = ISNULL(@a,6378137);
      SET @f = 1.0 / CAST(SUBSTRING(@a_f,CHARINDEX(',',@a_f)+1,100) as float);
      SET @f = ISNULL(@f,1.0/298.257223563);
      SET @b = @a - @a * @f ;
    END;
    SET @semiMajorAxisSquared = @semiMajorAxis * @semiMajorAxis;
    SET @semiMinorAxisSquared = @semiMinorAxis * @semiMinorAxis;

    SET @phi1               = Radians(@p_point.Lat);
    SET @semiMajorAxislpha1 = Radians(@p_startBearing);
    SET @cosAlpha1          = COS(@semiMajorAxislpha1);
    SET @sinAlpha1          = SIN(@semiMajorAxislpha1);
    SET @s                  = @p_distance;
    SET @tanU1              = (1.0 - @f) * TAN(@phi1);
    SET @cosU1              = 1.0 / sqrt(1.0 + @tanU1 * @tanU1);
    SET @sinU1              = @tanU1 * @cosU1;

      -- eq. 1
    SET @sigma1    = ATN2(@tanU1, @cosAlpha1);
      -- eq. 2
    SET @sinAlpha  = @cosU1 * @sinAlpha1;
    SET @sin2Alpha = @sinAlpha * @sinAlpha;
    SET @cos2Alpha = 1 - @sin2Alpha;
    SET @uSquared  = @cos2Alpha * (@semiMajorAxisSquared - @semiMinorAxisSquared) / @semiMinorAxisSquared;
    -- eq. 3
    SET @A         = 1 + (@uSquared / 16384) * (4096 + @uSquared * (-768 + @uSquared * (320 - 175 * @uSquared)));
    -- eq. 4
    SET @B         = (@uSquared / 1024) * (256 + @uSquared * (-128 + @uSquared * (74 - 47 * @uSquared)));
    -- iterate until there is a negligible change in sigma
    SET @sOverbA   = @s / (@semiMinorAxis * @A);
    SET @sigma     = @sOverbA;
    SET @prevSigma = @sOverbA;
    WHILE (1=1 ) 
    BEGIN
      -- eq. 5
      SET @sigmaM2     = 2.0 * @sigma1 + @sigma;
      SET @cosSigmaM2  = COS(@sigmaM2);
      SET @cos2SigmaM2 = @cosSigmaM2 * @cosSigmaM2;
      SET @sinSigma    = SIN(@sigma);
      SET @cosSignma   = COS(@sigma);
      -- eq. 6
      SET @deltaSigma = @B * @sinSigma * (@cosSigmaM2 + (@B / 4.0) * (@cosSignma * (-1 + 2 * @cos2SigmaM2) - (@B / 6.0) * @cosSigmaM2 * (-3 + 4 * @sinSigma * @sinSigma) * (-3 + 4 * @cos2SigmaM2)));
      -- eq. 7
      SET @sigma = @sOverbA + @deltaSigma;
      -- break after converging to tolerance
      IF (ABS(@sigma - @prevSigma) < 0.0000000000001) break;
      SET @prevSigma = @sigma;
    END;
    SET @sigmaM2     = 2.0 * @sigma1 + @sigma;
    SET @cosSigmaM2  = COS(@sigmaM2);
    SET @cos2SigmaM2 = @cosSigmaM2 * @cosSigmaM2;
    SET @cosSigma    = COS(@sigma);
    SET @sinSigma    = SIN(@sigma);
    -- eq. 8
    SET @phi2 = ATN2(@sinU1 * @cosSigma + @cosU1 * @sinSigma * @cosAlpha1, (1.0 - @f) * SQRT(@sin2Alpha + POWER(@sinU1 * @sinSigma - @cosU1 * @cosSigma * @cosAlpha1, 2.0)));

    -- eq. 9
    -- This fixes the pole crossing defect spotted by Matt Feemster. When a
    -- path passes a pole and essentially crosses a line of latitude twice -
    -- once in each direction - the longitude calculation got messed up. Using
    -- atan2 instead of atan fixes the defect. The change is in the next 3
    -- lines.
    -- double tanLambda = sinSigma * sinAlpha1 / (cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1);
    -- double lambda = Math.atan(tanLambda);
    SET @lambda = ATN2(@sinSigma * @sinAlpha1, (@cosU1 * @cosSigma - @sinU1 * @sinSigma * @cosAlpha1));
    -- eq. 10
    SET @C = (@f / 16) * @cos2Alpha * (4 + @f * (4 - 3 * @cos2Alpha));
    -- eq. 11
    SET @L = @lambda - (1 - @C) * @f * @sinAlpha * (@sigma + @C * @sinSigma * (@cosSigmaM2 + @C * @cosSigma * (-1 + 2 * @cos2SigmaM2)));
    -- eq. 12
    SET @semiMajorAxislpha2 = ATN2(@sinAlpha, -@sinU1 * @sinSigma + @cosU1 * @cosSigma * @cosAlpha1);
    -- build result
    SET @latitude  = Degrees(@phi2);
    SET @longitude = @p_point.Long + Degrees(@L);
    return geography::Point(@latitude, @longitude,@p_point.STSrid);
End;
GO

select [$(cogoowner)].[STDirectVincenty](geography::Point(-42.5,147.23,4326),90.0,100.0).STAsText();
GO

