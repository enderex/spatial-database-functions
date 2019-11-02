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
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/* Vincenty Direct and Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness 2002-2019  */
/*                                                                                   MIT Licence  */
/* www.movable-type.co.uk/scripts/latlong-ellipsoidal-vincenty.html                               */
/* www.movable-type.co.uk/scripts/geodesy-library.html#latlon-ellipsoidal-vincenty                */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/**
 * Distances & bearings between points, and destination points given start points & initial bearings,
 * calculated on an ellipsoidal earth model using ‘direct and inverse solutions of geodesics on the
 * ellipsoid’ devised by Thaddeus Vincenty.
 *
 * From: T Vincenty, "Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of
 * nested equations", Survey Review, vol XXIII no 176, 1975. www.ngs.noaa.gov/PUBS_LIB/inverse.pdf.
 *
 * @module latlon-ellipsoidal-vincenty
 */

/**
    * Vincenty direct calculation.
    *
    * Ellipsoid parameters are taken from datum of 'this' point. Height is ignored.
    *
    * @private
    * @param   {number} distance - Distance along bearing in metres.
    * @param   {number} initialBearing - Initial bearing in degrees from north.
    * @returns (Object} Object including point (destination point), finalBearing.
    * @throws  {RangeError} Point must be on surface of ellipsoid.
    * @throws  {EvalError}  Formula failed to converge.
    */
Begin
  Declare 
    -- Ellipsoid parameters (default WGS84)
    @a                float = 6378137,           -- Semi-major axis
    @b                float = 6356752.314245,    -- Semi-minor axis
    @f                float = 1.0/298.257223563, -- Flattening
    @a_f              varchar(100),

    @π                float = PI(),
    @ε                float = 2.2204460492503130808472633361816E-16,
    @σ                float,
    @sinσ             float,
    @cosσ             float, 
    @Δσ               float, -- σ = angular distance P₁ P₂ on the sphere
    @cos2σm           float, -- σₘ = angular distance on the sphere from the equator to the midpoint of the line

    @φ1               Float,
    @λ1               Float,
    @α1               Float,
    @s                Float,
    @sinα1            Float,
    @cosα1            Float,

    @tanU1            Float,
    @cosU1            Float,
    @sinU1            Float,
    @σ1               Float, --angular distance on the sphere from the equator to P1
    @sinα             Float, -- α = azimuth of the geodesic at the equator
    @cosSqα           Float,
    @uSq              Float,
    @capA             Float,
    @capB             Float,
    @σP               Float,
	@iterations       integer,
    @x                Float,
    @φ2               Float,
    @λ                Float,
    @C                Float,
    @L                Float,
    @λ2               Float,
    @α2               Float,
	@height           float,
	@finalBearing     varchar(100),
	@destinationPoint geography;

    SET @height = 0; -- point must be on the surface of the ellipsoid;

    SET @φ1 = Radians(@p_point.Lat);
    SET @λ1 = Radians(@p_point.Long);
    SET @α1 = Radians(@p_initialBearing);
    SET @s  = @p_distance;

    -- allow alternative ellipsoid to be specified
    SET @a_f = [$(cogoowner)].[STEllipsoidParameters] ( @p_point.STSrid ); 
    SET @a = CAST(SUBSTRING(@a_f,1,CHARINDEX(',',@a_f)-1) as float);
    SET @a = ISNULL(@a,6378137);
	SET @b = 6356752.314245;
    SET @f = 1.0 / CAST(SUBSTRING(@a_f,CHARINDEX(',',@a_f)+1,100) as float);
    SET @f = ISNULL(@f,1.0/298.257223563);

    SET @sinα1 = SIN(@α1);
    SET @cosα1 = COS(@α1);

    SET @tanU1  = (1.0 - @f) * TAN(@φ1);
    SET @cosU1  = 1.0 / SQRT((1 + @tanU1*@tanU1));
    SET @sinU1  = @tanU1 * @cosU1;
    SET @σ1     = ATN2(@tanU1, @cosα1); -- σ1 = angular distance on the sphere from the equator to P1
    SET @sinα   = @cosU1 * @sinα1;       -- α = azimuth of the geodesic at the equator
    SET @cosSqα = 1.0 - @sinα*@sinα;
    SET @uSq    = @cosSqα * (@a*@a - @b*@b) / (@b*@b);
    SET @capA      = 1.0 + @uSq / 16384.0*(4096.0 + @uSq * (-768.0 + @uSq * (320.0 - 175.0 * @uSq)));
    SET @capB      = @uSq / 1024.0 *      (256.0  + @uSq * (-128.0 + @uSq * (74.0  - 47.0  * @uSq)));

    SET @σ      = @s / (@b*@capA);
	SET @sinσ   = 0.0;
    SET @cosσ   = 0.0; 
    SET @Δσ     = 0.0;
    SET @cos2σm = 0.0;

    SET @σP = 0;
	SET @iterations = 0;
    while (ABS(@σ-@σP) > 1e-12 AND @iterations < 100)
	Begin
        SET @cos2σm = COS(2.0*@σ1 + @σ);
        SET @sinσ   = SIN(@σ);
        SET @cosσ   = COS(@σ);
        SET @Δσ     = @capB*@sinσ * (@cos2σm + @capB/4.0 * (@cosσ*(-1.0 + 2.0*@cos2σm*@cos2σm) -
                      @capB/6.0 * @cos2σm * (-3.0 + 4.0*@sinσ*@sinσ) * (-3.0 + 4.0*@cos2σm*@cos2σm)));
        SET @σP     = @σ;
        SET @σ      = @s / (@b*@capA) + @Δσ;
		SET @iterations = @iterations + 1;
    END;
    if (@iterations >= 100) 
		RAISERROR('Vincenty formula failed to converge',16,1);

    SET @x  = @sinU1 * @sinσ - @cosU1 * @cosσ * @cosα1;
    SET @φ2 = atn2(@sinU1*@cosσ + @cosU1*@sinσ*@cosα1, (1.0 - @f) * SQRT(@sinα * @sinα + @x * @x));
    SET @λ  = atn2(@sinσ*@sinα1, @cosU1*@cosσ - @sinU1 * @sinσ * @cosα1);
    SET @C  = @f/16.0 * @cosSqα * (4.0+@f*(4.0 - 3.0*@cosSqα));
    SET @L  = @λ - (1.0-@C) * @f*@sinα*(@σ+@C * @sinσ*(@cos2σm + @C*@cosσ *(-1.0 + 2.0*@cos2σm*@cos2σm)));
    SET @λ2 = @λ1 + @L;

    SET @α2 = atn2(@sinα, -@x);

    SET @destinationPoint = geography::Point(Degrees(@φ2),Degrees(@λ2),@p_point.STSrid);
    SET @finalBearing     = [$(cogoowner)].[DD2DMS](Degrees(@α2),DEFAULT,DEFAULT,DEFAULT);

	return @destinationPoint;
End;
GO

select [$(cogoowner)].[STDirectVincenty](geography::Point(-42.5,147.23,4326),90.0,100.0).STAsText();
GO

QUIT
GO
