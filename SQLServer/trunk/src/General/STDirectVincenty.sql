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

create function [$(cogoowner)].[STDirectVincenty](
  @p_point      geography,
  @p_initialBearing float,
  @p_distance       float
) 
returns geography
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
 *    Vincenty Direct and Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness 2002-2019
 *    www.movable-type.co.uk/scripts/latlong-ellipsoidal-vincenty.html
 *    www.movable-type.co.uk/scripts/geodesy-library.html#latlon-ellipsoidal-vincenty
 *
 *    Distances & bearings between points, and destination points given start points & initial bearings,
 *    calculated on an ellipsoidal earth model using direct solution of geodesics on the ellipsoid 
 *    devised by Thaddeus Vincenty.
 *  NOTES
 *    1. From: T Vincenty, "Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of
 *    nested equations", Survey Review, vol XXIII no 176, 1975. www.ngs.noaa.gov/PUBS_LIB/inverse.pdf.
 *    2. Ellipsoid parameters are taken from sys.spatial_reference_systems.
 *  INPUTS
 *    @p_point      (geography) - Latitude/Longitude Point
 *    @p_initialBearing (float) - Initial bearing in degrees from north.
 *    @p_distance       (float) - Distance along bearing in metres.
 *  RESULT
 *    point         (geography) - Destination point, bearing and distance from @p_point.
 *  EXAMPLE
 *    select [$(cogoowner)].[STDirectVincenty](geography::Point(-42.5,147.23,4326),90.0,100.0).STAsText() as newPoint
 *    GO
 *
 *    newPoint
 *    POINT (147.23121655963791 -42.499999993543213)
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
    @a                float = 6378137,           -- Semi-major axis
    @b                float = 6356752.314245,    -- Semi-minor axis
    @f                float = 1.0/298.257223563, -- Flattening
    @a_f              varchar(100),
    @Sigma            float,
    @sinSigma         float,
    @cosSigma         float, 
    @DeltaSigma       float, -- Sigma = angular distance P₁ P₂ on the sphere
    @cos2Sigmam       float, -- Sigmaₘ = angular distance on the sphere from the equator to the midpoint of the line
    @Phi1             Float,
    @Lambda1          Float,
    @Alpha1           Float,
    @s                Float,
    @sinAlpha1        Float,
    @cosAlpha1        Float,
    @tanU1            Float,
    @cosU1            Float,
    @sinU1            Float,
    @Sigma1           Float, --angular distance on the sphere from the equator to P1
    @sinAlpha         Float, -- Alpha = azimuth of the geodesic at the equator
    @cosSqAlpha       Float,
    @uSq              Float,
    @capA             Float,
    @capB             Float,
    @SigmaP           Float,
	@iterations       integer,
    @x                Float,
    @Phi2             Float,
    @Lambda           Float,
    @C                Float,
    @L                Float,
    @Lambda2          Float,
    @Alpha2           Float,
	@finalBearing     varchar(100),
	@destinationPoint geography;

    SET @Phi1    = Radians(@p_point.Lat);
    SET @Lambda1 = Radians(@p_point.Long);
    SET @Alpha1  = Radians(@p_initialBearing);
    SET @s       = @p_distance;

    -- allow alternative ellipsoid to be specified
    SET @a_f = [$(cogoowner)].[STEllipsoidParameters] ( @p_point.STSrid ); 
    IF ( @a_f is not null AND LEN(@a_f) > 0 ) 
    BEGIN
      SET @a = CAST(SUBSTRING(@a_f,1,CHARINDEX(',',@a_f)-1) as float);
      SET @a = ISNULL(@a,6378137);
      SET @b = 6356752.314245;
      SET @f = 1.0 / CAST(SUBSTRING(@a_f,CHARINDEX(',',@a_f)+1,100) as float);
      SET @f = ISNULL(@f,1.0/298.257223563);
    END;

    SET @sinAlpha1 = SIN(@Alpha1);
    SET @cosAlpha1 = COS(@Alpha1);

    SET @tanU1      = (1.0 - @f) * TAN(@Phi1);
    SET @cosU1      = 1.0 / SQRT((1 + @tanU1*@tanU1));
    SET @sinU1      = @tanU1 * @cosU1;
    SET @Sigma1     = ATN2(@tanU1, @cosAlpha1); -- Sigma1 = angular distance on the sphere from the equator to P1
    SET @sinAlpha   = @cosU1 * @sinAlpha1;       -- Alpha = azimuth of the geodesic at the equator
    SET @cosSqAlpha = 1.0 - @sinAlpha*@sinAlpha;
    SET @uSq        = @cosSqAlpha * (@a*@a - @b*@b) / (@b*@b);
    SET @capA       = 1.0 + @uSq / 16384.0*(4096.0 + @uSq * (-768.0 + @uSq * (320.0 - 175.0 * @uSq)));
    SET @capB       = @uSq / 1024.0 *      (256.0  + @uSq * (-128.0 + @uSq * (74.0  - 47.0  * @uSq)));

    SET @Sigma      = @s / (@b*@capA);
	SET @sinSigma   = 0.0;
    SET @cosSigma   = 0.0; 
    SET @DeltaSigma = 0.0;
    SET @cos2Sigmam = 0.0;

    SET @SigmaP = 0;
	SET @iterations = 0;
    while (ABS(@Sigma-@SigmaP) > 1e-12 AND @iterations < 100)
	Begin
        SET @cos2Sigmam = COS(2.0*@Sigma1 + @Sigma);
        SET @sinSigma   = SIN(@Sigma);
        SET @cosSigma   = COS(@Sigma);
        SET @DeltaSigma = @capB*@sinSigma * (@cos2Sigmam + @capB/4.0 * (@cosSigma*(-1.0 + 2.0*@cos2Sigmam*@cos2Sigmam) -
                          @capB/6.0 * @cos2Sigmam * (-3.0 + 4.0*@sinSigma*@sinSigma) * (-3.0 + 4.0*@cos2Sigmam*@cos2Sigmam)));
        SET @SigmaP     = @Sigma;
        SET @Sigma      = @s / (@b*@capA) + @DeltaSigma;
		SET @iterations = @iterations + 1;
    END;
    if (@iterations >= 100) 
       return null; -- RAISERROR('Vincenty formula failed to converge',16,1);

    SET @x       = @sinU1 * @sinSigma - @cosU1 * @cosSigma * @cosAlpha1;
    SET @Phi2    = atn2(@sinU1*@cosSigma + @cosU1*@sinSigma*@cosAlpha1, (1.0 - @f) * SQRT(@sinAlpha * @sinAlpha + @x * @x));
    SET @Lambda  = atn2(@sinSigma*@sinAlpha1, @cosU1*@cosSigma - @sinU1 * @sinSigma * @cosAlpha1);
    SET @C       = @f/16.0 * @cosSqAlpha * (4.0+@f*(4.0 - 3.0*@cosSqAlpha));
    SET @L       = @Lambda - (1.0-@C) * @f*@sinAlpha*(@Sigma+@C * @sinSigma*(@cos2Sigmam + @C*@cosSigma *(-1.0 + 2.0*@cos2Sigmam*@cos2Sigmam)));
    SET @Lambda2 = @Lambda1 + @L;

    SET @Alpha2 = atn2(@sinAlpha, -@x);

    SET @destinationPoint = geography::Point(Degrees(@Phi2),Degrees(@Lambda2),@p_point.STSrid);
    SET @finalBearing     = [$(cogoowner)].[DD2DMS](Degrees(@Alpha2),DEFAULT,DEFAULT,DEFAULT);

	return @destinationPoint;
End;
GO

select [$(cogoowner)].[STDirectVincenty](geography::Point(-42.5,147.23,4326),90.0,100.0).STAsText();
GO

QUIT
GO
