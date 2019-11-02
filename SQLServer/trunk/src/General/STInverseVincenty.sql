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

create function [$(cogoowner)].[STInverseVincenty]
(
  @p1 geography,
  @p2 geography
) 
returns Float
As
/**
 * Vincenty inverse calculation.
 *
 * Ellipsoid parameters are taken from datum of 'this' point. Height is ignored.
 * Point must be on the surface of the ellipsoid
 *
 * @private
 * @param   {LatLon} point - Latitude/longitude of destination point.
 * @returns {Object} Object including distance, initialBearing, finalBearing.
 * @throws  {TypeError}  Invalid point.
 * @throws  {RangeError} Points must be on surface of ellipsoid.
 * @throws  {EvalError}  Formula failed to converge.
*/
Begin
  Declare
    -- Ellipsoid parameters (default WGS84)
    @a         float = 6378137,           -- Semi-major axis
    @b         float = 6356752.314245,    -- Semi-minor axis
    @f         float = 1.0/298.257223563, -- Flattening
    @a_f       varchar(100),

    @φ1        Float,
	@λ1        Float,
    @φ2        Float,
	@λ2        Float,
    @L         Float,
    @tanU1     Float,
    @tanU2     Float,
	@cosU1     Float,
	@sinU1     Float,
	@cosU2     Float,
	@sinU2     Float,

    @ε         Float,
    @λ         Float,
	@sinλ      Float,
	@cosλ      Float,  -- λ = difference in longitude on an auxiliary sphere
    @σ         Float,
	@sinσ      Float,
	@cosσ      Float,
	@sinSqσ    Float,  -- σ = angular distance P₁ P₂ on the sphere
    @cos2σm    Float,  -- σM = angular distance on the sphere from the equator to the midpoint of the line
    @sinα      Float,
	@cosSqα    Float,  -- α = azimuth of the geodesic at the equator
    @C         Float,
    @λp        Float,
	@π         Float,
	@uSq       Float,
    @capA      Float,
    @capB      Float,
    @Δσ        Float, 
    @s         Float,
    @α1        Float,
    @α2        Float,
    @antipodal      bit,
	@iterationCheck float,
	@iterations     integer;

    SET @φ1 = Radians(@p1.Lat); 
	SET @λ1 = Radians(@p1.Long);
    SET @φ2 = Radians(@p2.Lat); 
    SET @λ2 = Radians(@p2.Long);

    -- allow alternative ellipsoid to be specified
    -- allow alternative ellipsoid to be specified
    SET @a_f = [$(cogoowner)].[STEllipsoidParameters] ( @p1.STSrid ); 
    SET @a = CAST(SUBSTRING(@a_f,1,CHARINDEX(',',@a_f)-1) as float);
    SET @a = ISNULL(@a,6378137);
	SET @b = 6356752.314245;
    SET @f = 1.0 / CAST(SUBSTRING(@a_f,CHARINDEX(',',@a_f)+1,100) as float);
    SET @f = ISNULL(@f,1.0/298.257223563);

    SET @L = @λ2 - @λ1; -- L = difference in longitude, U = reduced latitude, defined by tan U = (1-f)·tanφ.
    SET @tanU1 = (1-@f) * TAN(@φ1);
	SET @cosU1 = 1 / SQRT((1 + @tanU1*@tanU1));
	SET @sinU1 = @tanU1 * @cosU1;
    SET @tanU2 = (1-@f) * TAN(@φ2);
	SET @cosU2 = 1 / SQRT((1 + @tanU2*@tanU2));
	SET @sinU2 = @tanU2 * @cosU2;
    SET @antipodal = case when ABS(@L) > @π/2 or ABS(@φ2-@φ1) > @π/2 then 1 else 0 end;

    SET @λ      = @L;
	SET @sinλ   = 0.0;
	SET @cosλ   = 0.0;               -- λ = difference in longitude on an auxiliary sphere
    SET @σ      = case when @antipodal = 1 then @π else 0 end;
	SET @sinσ   = 0;
	SET @cosσ   = case when @antipodal = 1 then -1 else 1 end;
	SET @sinSqσ = 0.0;              -- σ = angular distance P₁ P₂ on the sphere
    SET @cos2σm = 1;                 -- σM = angular distance on the sphere from the equator to the midpoint of the line
    SET @sinα   = 0.0;
	SET @cosSqα = 1;                 -- α = azimuth of the geodesic at the equator
    SET @C      = 0.0;

    SET @λp = 0.0;
	SET @iterations = 0;
	WHILE (abs(@λ-@λp) > 1e-12 AND @iterations<1000)
    BEGIN
      SET @sinλ = sin(@λ);
      SET @cosλ = cos(@λ);
      SET @sinSqσ = (@cosU2*@sinλ) * (@cosU2*@sinλ) + (@cosU1*@sinU2-@sinU1*@cosU2*@cosλ) * (@cosU1*@sinU2-@sinU1*@cosU2*@cosλ);
      if (abs(@sinSqσ) < @ε) break;  -- co-incident/antipodal points (falls back on λ/σ = L)
      SET @sinσ = sqrt(@sinSqσ);
      SET @cosσ = @sinU1*@sinU2 + @cosU1*@cosU2*@cosλ;
      SET @σ    = atn2(@sinσ, @cosσ);
      SET @sinα = @cosU1 * @cosU2 * @sinλ / @sinσ;
      SET @cosSqα = 1 - @sinα*@sinα;
      SET @cos2σm = case when (@cosSqα != 0) then (@cosσ - 2*@sinU1*@sinU2/@cosSqα) else 0.0 end; -- on equatorial line @cos²α = 0 (§6)
      SET @C = @f/16*@cosSqα*(4+@f*(4-3*@cosSqα));
      SET @λp = @λ;
      SET @λ = @L + (1-@C) * @f * @sinα * (@σ + @C*@sinσ*(@cos2σm+@C*@cosσ*(-1+2*@cos2σm*@cos2σm)));
      SET @iterationCheck = case when @antipodal= 1 then abs(@λ)-@π else abs(@λ) end;
      if (@iterationCheck > @π) 
	    Return 0.0; --  RAISERROR('λ > π',16,1);
      SET @iterations = @iterations + 1;
    END;
    if (@iterations >= 1000) 
	  Return 0.0; -- RAISERROR('Vincenty formula failed to converge',16,1);

    SET @uSq  = @cosSqα * (@a*@a - @b*@b) / (@b*@b);
    SET @capA = 1 + @uSq/16384*(4096+@uSq*(-768+@uSq*(320-175*@uSq)));
    SET @capB = @uSq/1024 * (256+@uSq*(-128+@uSq*(74-47*@uSq)));
    SET @Δσ   = @capB*@sinσ*(@cos2σm+@capB/4*(@cosσ*(-1+2*@cos2σm*@cos2σm) - 
                @capB/6*@cos2σm*(-3+4*@sinσ*@sinσ)*(-3+4*@cos2σm*@cos2σm)));
    SET @s    = @b*@capA*(@σ-@Δσ); -- s = length of the geodesic

    -- note special handling of exactly antipodal points where sin²σ = 0 (due to discontinuity
    -- atan2(0, 0) = 0 but atan2(ε, 0) = π/2 / 90°) - in which case bearing is always meridional,
    -- due north (or due south!)
    -- α = azimuths of the geodesic; α2 the direction P₁ P₂ produced
    SET @α1 = case when abs(@sinSqσ) < @ε then 0.0 else atn2(@cosU2*@sinλ,  @cosU1*@sinU2-@sinU1*@cosU2*@cosλ) end;
    SET @α2 = case when abs(@sinSqσ) < @ε then @π  else atn2(@cosU1*@sinλ, -@sinU1*@cosU2+@cosU1*@sinU2*@cosλ) end;

  Return @s;
  -- initialBearing: abs(s) < ε ? NaN : Dms.wrap360(α1.toDegrees()),
  -- finalBearing:   abs(s) < ε ? NaN : Dms.wrap360(α2.toDegrees()),
End;
Go

SELECT [$(cogoowner)].[STInverseVincenty] (
         geography::Point(12.1603670,55.4748508,4326),
         geography::Point(12.1713976,55.4786191,4326)) as meters;
GO

QUIT
GO

