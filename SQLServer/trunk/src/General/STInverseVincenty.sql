SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(cogoowner)].[STInverseVincenty]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STInverseVincenty];
  Print 'Dropped [$(cogoowner)].[STInverseVincenty] ...';
END;
GO

Print 'Creating [$(cogoowner)].[STInverseVincenty] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STInverseVincenty]
(
  @p_point1 geography,
  @p_point2 geography
) 
returns Float
As
/****f* COGO/STInverseVincenty (2008)
 *  NAME
 *    STInverseVincenty -- Vincenty inverse calculation.
 *  SYNOPSIS
 *    Function [$(cogoowner)].[STInverseVincenty] (
 *       @p_point1 geography,
 *       @p_point2 geography
 *    )
 *    Returns float
 *  DESCRIPTION
 *    Computes distance in meters between two geographic points.
 *
 *    Vincenty Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness 2002-2019
 *    www.movable-type.co.uk/scripts/latlong-ellipsoidal-vincenty.html
 *    www.movable-type.co.uk/scripts/geodesy-library.html#latlon-ellipsoidal-vincenty
 *
 *    Distances & bearings between points, and destination points given start points & initial bearings,
 *    calculated on an ellipsoidal earth model using direct solution of geodesics on the ellipsoid 
 *    devised by Thaddeus Vincenty.
 *  SEE ALSO
 *    [$(cogoowner)].[STGeographicDistance]
 *  NOTES
 *    1. From: T Vincenty, "Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of
 *    nested equations", Survey Review, vol XXIII no 176, 1975. www.ngs.noaa.gov/PUBS_LIB/inverse.pdf.
 *    2. Ellipsoid parameters are taken from sys.spatial_reference_systems.
 *  INPUTS
 *    @p_point1 (geography) - First Latitude/Longitude Point
 *    @p_point2 (geography) - Second Latitude/Longitude Point
 *  RESULT
 *    distance     (float) - Distance between @p_point1 and @p_point2 in meters.
 *  EXAMPLE
 *    SELECT [$(cogoowner)].[STInverseVincenty] (
 *             geography::Point(12.1603670,55.4748508,4326),
 *             geography::Point(12.1713976,55.4786191,4326)) as meters;
 *    GO
 *
 *    meters
 *    1287.32279362667
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Chris Veness  - Original JavaScript coding
 *    Simon Greener - October 2019 - Ported to SQL Server TSQL.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 *    MIT Licence
 ******/
Begin
  Declare
    -- Ellipsoid parameters (default WGS84)
    @a          float = 6378137,           -- Semi-major axis
    @b          float = 6356752.314245,    -- Semi-minor axis
    @f          float = 1.0/298.257223563, -- Flattening
    @a_f        varchar(100),
    @Epsilon    Float = 2.220446049250313e-16,

    @Phi1       Float,
    @Lambda1    Float,
    @Phi2       Float,
    @Lambda2    Float,
    @L          Float,
    @tanU1      Float,
    @tanU2      Float,
    @cosU1      Float,
    @sinU1      Float,
    @cosU2      Float,
    @sinU2      Float,

    @Lambda     Float,
    @sinLambda  Float,
    @cosLambda  Float, 
    @Sigma      Float,
    @sinSigma   Float,
    @cosSigma   Float,
    @sinSqSigma Float,  
    @cos2Sigmam Float,  
    @sinAlpha   Float,
    @cosSqAlpha Float,  -- Alpha = azimuth of the geodesic at the equator
    @C          Float,
    @Lambdap    Float,
    @uSq        Float,
    @capA       Float,
    @capB       Float,
    @DeltaSigma Float, 
    @s          Float,
    @Alpha1     Float,
    @Alpha2     Float,
    @antipodal      bit,
    @iterationCheck float,
    @iterations     integer;

    SET @Phi1    = Radians(@p_point1.Lat); 
    SET @Lambda1 = Radians(@p_point1.Long);
    SET @Phi2    = Radians(@p_point2.Lat); 
    SET @Lambda2 = Radians(@p_point2.Long);

  -- allow alternative ellipsoid to be specified
  SET @a_f = [$(cogoowner)].[STEllipsoidParameters] ( @p_point1.STSrid ); 
  IF ( @a_f is not null AND LEN(@a_f) > 0 ) 
  BEGIN
    SET @a = CAST(SUBSTRING(@a_f,1,CHARINDEX(',',@a_f)-1) as float);
    SET @a = ISNULL(@a,6378137);
    SET @f = 1.0 / CAST(SUBSTRING(@a_f,CHARINDEX(',',@a_f)+1,100) as float);
    SET @f = ISNULL(@f,1.0/298.257223563);
    SET @b = @a * @f + @a;
  END;

  SET @L          = @Lambda2 - @Lambda1;
  SET @tanU1      = (1.0-@f) * TAN(@Phi1);
  SET @cosU1      = 1.0 / SQRT((1.0 + @tanU1*@tanU1));
  SET @sinU1      = @tanU1 * @cosU1;
  SET @tanU2      = (1.0-@f) * TAN(@Phi2);
  SET @cosU2      = 1.0 / SQRT((1.0 + @tanU2*@tanU2));
  SET @sinU2      = @tanU2 * @cosU2;
  SET @antipodal  = case when ABS(@L) > PI()/2.0 or ABS(@Phi2-@Phi1) > PI()/2.0 then 1 else 0 end;

  SET @Lambda     = @L;
  SET @sinLambda  = 0.0;
  SET @cosLambda  = 0.0;
  SET @Sigma      = case when @antipodal = 1 then PI() else 0 end;
  SET @sinSigma   = 0;
  SET @cosSigma   = case when @antipodal = 1 then -1 else 1 end;
  SET @sinSqSigma = 0.0; 
  SET @cos2Sigmam = 1;
  SET @sinAlpha   = 0.0;
  SET @cosSqAlpha = 1;
  SET @C          = 0.0;

  SET @Lambdap    = 0.0;
  SET @iterations = 0;
  WHILE (abs(@Lambda-@Lambdap) > 1e-12 AND @iterations<1000)
  BEGIN
    SET @sinLambda  = sin(@Lambda);
    SET @cosLambda  = cos(@Lambda);
    SET @sinSqSigma = (@cosU2*@sinLambda) * (@cosU2*@sinLambda) + 
                      (@cosU1*@sinU2-@sinU1*@cosU2*@cosLambda) * (@cosU1*@sinU2-@sinU1*@cosU2*@cosLambda);
    IF (abs(@sinSqSigma) < @Epsilon) break;  -- co-incident/antipodal points (falls back on Lambda/Sigma = L)
    SET @sinSigma   = sqrt(@sinSqSigma);
    SET @cosSigma   = @sinU1*@sinU2 + @cosU1*@cosU2*@cosLambda;
    SET @Sigma      = atn2(@sinSigma, @cosSigma);
    SET @sinAlpha   = @cosU1 * @cosU2 * @sinLambda / @sinSigma;
    SET @cosSqAlpha = 1.0 - @sinAlpha*@sinAlpha;
    SET @cos2Sigmam = case when (@cosSqAlpha != 0.0) then (@cosSigma - 2.0*@sinU1*@sinU2/@cosSqAlpha) else 0.0 end; -- on equatorial line @cosSqAlpha = 0
    SET @C          = @f/16.0*@cosSqAlpha*(4.0+@f*(4.0-3.0*@cosSqAlpha));
    SET @Lambdap    = @Lambda;
    SET @Lambda     = @L + (1.0-@C) * @f * @sinAlpha * (@Sigma + @C*@sinSigma*(@cos2Sigmam+@C*@cosSigma*(-1.0+2.0*@cos2Sigmam*@cos2Sigmam)));
    SET @iterationCheck = case when @antipodal= 1 then abs(@Lambda)-PI() else abs(@Lambda) end;
    IF (@iterationCheck > PI()) 
        Return 0.0; --  RAISERROR('Lambda > PI()',16,1);
    SET @iterations = @iterations + 1;
  END;
  IF (@iterations >= 1000) 
    Return 0.0; -- RAISERROR('Vincenty formula failed to converge',16,1);

  SET @uSq        = @cosSqAlpha * (@a*@a - @b*@b) / (@b*@b);
  SET @capA       = 1.0 + @uSq/16384.0*(4096.0+@uSq*(-768.0+@uSq*(320.0-175.0*@uSq)));
  SET @capB       = @uSq/1024.0 * (256.0+@uSq*(-128.0+@uSq*(74.0-47.0*@uSq)));
  SET @DeltaSigma = @capB*@sinSigma*(@cos2Sigmam+@capB/4.0*(@cosSigma*(-1.0+2.0*@cos2Sigmam*@cos2Sigmam) - 
                    @capB/6.0*@cos2Sigmam*(-3.0+4.0*@sinSigma*@sinSigma)*(-3.0+4.0*@cos2Sigmam*@cos2Sigmam)));
  SET @s          = @b*@capA*(@Sigma-@DeltaSigma); -- s = length of the geodesic

  -- note special handling of exactly antipodal points where sinSqSigma = 0 (due to discontinuity atan2(0, 0) = 0 but atan2(Epsilon, 0) = PI()/2 / 90.0) - in which case bearing is always meridional, due north (or due south!)
  -- Alpha = azimuths of the geodesic; Alpha2 the direction PP produced
  SET @Alpha1 = case when abs(@sinSqSigma) < @Epsilon then 0.0  else atn2(@cosU2*@sinLambda,  @cosU1*@sinU2-@sinU1*@cosU2*@cosLambda) end;
  SET @Alpha2 = case when abs(@sinSqSigma) < @Epsilon then PI() else atn2(@cosU1*@sinLambda, -@sinU1*@cosU2+@cosU1*@sinU2*@cosLambda) end;

  Return @s;
End;
GO

