USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STGreatCircleBearing]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STGreatCircleBearing];
  Print 'Dropping [$(cogoowner)].[STGreatCircleBearing] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STGreatCircleDistance]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STGreatCircleDistance];
  Print 'Dropping [$(cogoowner)].[STGreatCircleDistance] ...';
END;
GO

Print 'Creating [$(cogoowner)].[STGreatCircleBearing] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STGreatCircleBearing]
(
  @p_dLon1 Float,
  @p_dLat1 Float,
  @p_dLon2 Float,
  @p_dLat2 Float
)
Returns Float
As
/****f* COGO/STGreatCircleBearing (2008)
 *  NAME
 *    STGreatCircleBearing -- Returns a (Normalized) bearing in Degrees between two lat/long coordinates
 *  SYNOPSIS
 *    Function STGreatCircleBearing (
 *               @p_dLon1 float,
 *               @p_dLat2 float,
 *               @p_dLon1 float,
 *               @p_dLat2 float
 *             )
 *     Returns float 
 *  USAGE
 *    SELECT [GISDB].[$(owner)].[STGreatCircleBearing](0,0,45,45) as Great_Circle_Bearing;
 *    Great_Circle_Bearing
 *    35.2643896827547
 *  DESCRIPTION
 *    Function that computes the bearing from the supplied start point (@p_dx1) to the supplied end point (@p_dx2).
 *    The result is expressed as a whole circle bearing in decimal degrees.
 *  INPUTS
 *    @p_dLon1 (float) - Longitude of starting point.
 *    @p_dLat1 (float) - Latitude of starting point.
 *    @p_dLon2 (float) - Longitude of finish point.
 *    @p_dLat2 (float) - Latitude of finish point.
 *  RESULT
 *    decimal degrees -- Bearing from point 1 to 2 in range 0-360.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    @v_dLon1 Float,
    @v_dLat1 Float,
    @v_dLon2 Float,
    @v_dLat2 Float,
    @v_dLong Float,
    @v_cosC  Float,
    @v_cosD  Float,
    @v_C     Float,
    @v_D     Float;
  Begin
    IF ( @p_dLon1 is null OR @p_dLat1 is null OR @p_dLon2 is null OR @p_dLat2 is null )
      Return NULL;

    IF ( ( ABS(@p_dLon1) NOT BETWEEN 0 AND 180 ) OR
         ( ABS(@p_dLat1) NOT BETWEEN 0 AND  90 ) OR
         ( ABS(@p_dLon2) NOT BETWEEN 0 AND 180 ) OR
         ( ABS(@p_dLat2) NOT BETWEEN 0 AND  90 ) )
      Return NULL;

    SET @v_dLon1 = RADIANS(@p_dLon1);
    SET @v_dLat1 = RADIANS(@p_dLat1);
    SET @v_dLon2 = RADIANS(@p_dLon2);
    SET @v_dLat2 = RADIANS(@p_dLat2);

    SET @v_dLong = @v_dLon2 - @v_dLon1;
    SET @v_cosD  = ( sin(@v_dLat1) * sin(@v_dLat2) ) +
                   ( cos(@v_dLat1) * cos(@v_dLat2) * cos(@v_dLong) );
    SET @v_D     = acos(@v_cosD);
    IF ( @v_D = 0.0 ) 
      SET @v_D = 0.00000001; -- roughly 1mm

    SET @v_cosC  = ( sin(@v_dLat2) - @v_cosD * sin(@v_dLat1) ) /
                   ( sin(@v_D) * cos(@v_dLat1) );
    -- numerical error can result in |cosC| slightly > 1.0
    IF ( @v_cosC > 1.0 ) 
      SET @v_cosC = 1.0;

    IF ( @v_cosC < -1.0 ) 
      SET @v_cosC = -1.0;

    SET @v_C  = 180.0 * acos( @v_cosC ) / PI();
    IF ( sin(@v_dLong) < 0.0 ) 
      SET @v_C = 360.0 - @v_C;

    Return @v_C;
  END;
END;
GO

Print 'Creating [$(cogoowner)].[STGreatCircleDistance] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STGreatCircleDistance] 
( 
  @p_dLon1             Float,
  @p_dLat1             Float,
  @p_dLon2             Float,
  @p_dLat2             Float,
  @p_equatorial_radius Float = 637813,       -- Default is WGS-84 in meters
  @p_flattening        Float = 298.257223563 -- Default is WGS-84 ellipsoid flattening factor 
)
Returns Float
As
/****f* COGO/STGreatCircleDistance (2008)
 *  NAME
 *    STGreatCircleDistance -- Computes great circle distance between two lat/long coordinates
 *  SYNOPSIS
 *    Function STGreatCircleDistance (
 *               @p_dLon1             float,
 *               @p_dLat2             float,
 *               @p_dLon1             float,
 *               @p_dLat2             float,
 *               @p_equatorial_radius Float = 6378137,      -- Default is WGS-84 in meters
 *               @p_flattening        Float = 298.257223563 -- Default is WGS-84 ellipsoid flattening factor 
 *             )
 *     Returns float 
 *  USAGE
 *    SELECT well_known_text FROM sys.spatial_reference_systems where spatial_reference_id = 4326;
 *    well_known_text
 *    GEOGCS["WGS 84", DATUM["World Geodetic System 1984", ELLIPSOID["WGS 84", 6378137, 298.257223563]], PRIMEM["Greenwich", 0], UNIT["Degree", 0.0174532925199433]]
 *
 *    select [GISDB].[$(owner)].[STGreatCircleDistance](0,0,45,45,6378137,298.257223563) as Great_Circle_Distance
 *    union all
 *    select [GISDB].[$(owner)].[STGreatCircleDistance](0,0,45,45,default,default)       as Great_Circle_Distance
 *    union all
 *    select geography::Point(0,0,4326).STDistance(geography::Point(45,45,4326))         as Great_Circle_Distance;
 *
 *    Great_Circle_Distance
 *    6662444.94352008
 *    6662444.94352008
 *    6662473.57317356
 *
 *  DESCRIPTION
 *    Function that computes a great circle distance between the supplied start (@p_dx1) and end points (@p_dx2).
 *    The result is expressed in meters. 
 *  NOTES
 *    Should be same as geographic::STPointFromText(
 *  INPUTS
 *    @p_dLon1             (float) - Longitude of starting point.
 *    @p_dLat1             (float) - Latitude of starting point.
 *    @p_dLon2             (float) - Longitude of finish point.
 *    @p_dLat2             (float) - Latitude of finish point.
 *    @p_equatorial_radius (float) - Radius at equator: default is WGS-84 of 6378.137.
 *    @p_flattening        (float) - Ellipsoid flattening factor: Default is WGS-84 
 *  RESULT
 *    distance -- Distance from point 1 to 2 in meters.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    @v_dLon1       Float,
    @v_dLat1       Float,
    @v_dLon2       Float,
    @v_dLat2       Float,
    @v_equatorial_radius  Float,
    @v_Inv_Flattening  Float,
    @v_C           Float,
    @v_D           Float,
    @v_F           Float,
    @v_G           Float,
    @v_H1          Float,
    @v_H2          Float,
    @v_dL          Float,
    @v_R           Float,
    @v_S           Float,
    @v_W           Float,
    @v_sinG2       Float,
    @v_cosG2       Float,
    @v_sinF2       Float,
    @v_cosF2       Float,
    @v_sinL2       Float,
    @v_cosL2       Float,
    @v_distance    Float;
  Begin
    IF ( @p_dLon1 is null OR @p_dLat1 is null OR @p_dLon2 is null OR @p_dLat2 is null )
      Return NULL;

    IF ( ( ABS(@p_dLon1) NOT BETWEEN 0 AND 180 ) OR
         ( ABS(@p_dLat1) NOT BETWEEN 0 AND  90 ) OR
         ( ABS(@p_dLon2) NOT BETWEEN 0 AND 180 ) OR
         ( ABS(@p_dLat2) NOT BETWEEN 0 AND  90 ) )
      Return NULL;

    SET @v_dLon1 = RADIANS(@p_dLon1);
    SET @v_dLat1 = RADIANS(@p_dLat1);
    SET @v_dLon2 = RADIANS(@p_dLon2);
    SET @v_dLat2 = RADIANS(@p_dLat2);

    SET @v_equatorial_radius = @p_equatorial_radius;
    IF ( @p_equatorial_radius IS NULL )
      SET @v_equatorial_Radius = 6378137; -- Default is WGS-84 meters
    IF ( @p_flattening IS NULL )
      SET @v_Inv_Flattening = 1.0 / 298.257223563; -- Default is WGS-84 ellipsoid flattening factor
    ELSE
      SET @v_Inv_Flattening = 1.0 / @p_flattening;

    SET @v_F  = ( @v_dLat1 + @v_dLat2 ) / 2.0;
    SET @v_G  = ( @v_dLat1 - @v_dLat2 ) / 2.0;
    SET @v_dL = ( @v_dLon1 - @v_dLon2 ) / 2.0;

    SET @v_sinG2 = power( sin( @v_G ), 2 );
    SET @v_cosG2 = power( cos( @v_G ), 2 );
    SET @v_sinF2 = power( sin( @v_F ), 2 );
    SET @v_cosF2 = power( cos( @v_F ), 2 );
    SET @v_sinL2 = power( sin( @v_dL ), 2 );
    SET @v_cosL2 = power( cos( @v_dL ), 2 );

    SET @v_S  = @v_sinG2 * @v_cosL2 + @v_cosF2 * @v_sinL2;
    SET @v_C  = @v_cosG2 * @v_cosL2 + @v_sinF2 * @v_sinL2;

    SET @v_W  = atan( sqrt( @v_S / @v_C ) );
    SET @v_R  = sqrt( @v_S * @v_C ) / @v_w;

    SET @v_D  = 2.0 * @v_w * @v_equatorial_radius;
    SET @v_H1 = ( 3.0 * @v_R - 1)/( 2.0 * @v_C);
    SET @v_H2 = ( 3.0 * @v_R + 1)/( 2.0 * @v_S);

    SET @v_distance = @v_D * ( ( 1.0 + @v_Inv_Flattening * @v_H1 * @v_sinF2 * @v_cosG2 ) -
                                     ( @v_Inv_Flattening * @v_H2 * @v_cosF2 * @v_sinG2 ) );

    Return @v_distance;
  END;
END
GO

Print 'Testing [$(cogoowner)].[STGreatCircleBearing] ...';
GO

select [$(cogoowner)].[STGreatCircleBearing] (
          [$(cogoowner)].[DMS2DD](149,0,0),
          [$(cogoowner)].[DMS2DD](-32,0,0),
          [$(cogoowner)].[DMS2DD](100,0,0),
          [$(cogoowner)].[DMS2DD](10,0,0)
       ) as GCB;
GO

Print 'Testing [$(cogoowner)].[STGreatCircleDistance] ...';
GO

-- Null will force default use of WGS84 flattening and equatorial radius
select [$(cogoowner)].[STGreatCircleDistance] (
         [$(cogoowner)].[DMS2DD]( 90,0,0),0,
         [$(cogoowner)].[DMS2DD](100,0,0),0,
         NULL,NULL) as gcd_wgs84;
GO

-- Hardcoded flattening for WGS84 ...
select [$(cogoowner)].[STGreatCircleDistance] (
          [$(cogoowner)].DMS2DD(90,0,0), 0,
          [$(cogoowner)].DMS2DD(100,0,0),0,
          6378.137, 
          298.257223563 )
       As GCD_90_0_to_100_0;
GO

