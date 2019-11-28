IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STAzimuth]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STAzimuth];
  PRINT 'Dropped [$(cogoowner)].[STAzimuth] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STAzimuth] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STAzimuth] (
  @p_X0 float, 
  @p_Y0 float,
  @p_X1 float, 
  @p_Y1 float
) 
Returns Float
/****f* COGO/STAzimuth (2008)
 *  NAME
 *    STAzimuth -- Returns a (Normalized) azimuth in Degrees between two non-geodetic (XY) coordinates
 *  SYNOPSIS
 *    Function STBearing (
 *               @p_dE1 float,
 *               @p_dN1 float,
 *               @p_dE2 float,
 *               @p_dN2 float
 *             )
 *     Returns float 
 *  DESCRIPTION
 *    Function that computes the azimuth from the supplied start point (@p_dx1) to the supplied end point (@p_dx2).
 *    The result is expressed as a whole circle bearing in decimal degrees.
 *    This function is an alternate implemetation of STBearing whose results should always be the same.
 *  INPUTS
 *    @p_dE1 (float) - X ordinate of start point.
 *    @p_dN1 (float) - Y ordinate of start point.
 *    @p_dE2 (float) - Z ordinate of start point.
 *    @p_dN2 (float) - M ordinate of start point.
 *  RESULT
 *    decimal degrees (float) - Azimuth between point 1 and 2 from 0-360.
 *  EXAMPLE
 *    SELECT [$(cogoowner)].[STAzimuth](0,0,45,45) as Bearing;
 *    Bearing
 *    45
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
As
Begin
  Declare
    @v_angle float = null;
  Begin
    IF (@p_X0 = @p_X1) 
    BEGIN
      IF (@p_Y0 < @p_Y1) 
        SET @v_angle = 0.0
      ELSE
      BEGIN
        IF (@p_Y0 > @p_Y1) 
          SET @v_angle = PI()
        ELSE 
          SET @v_angle = null;
      END;
    END 
    ELSE 
    BEGIN 
      IF (@p_Y0 = @p_Y1) 
      BEGIN
        IF (@p_X0 < @p_X1) 
          SET @v_angle = PI() / 2.0
        ELSE 
        BEGIN 
          IF (@p_X0 > @p_X1) 
            SET @v_angle = PI() + (PI() / 2.0)
          ELSE
            SET @v_angle = null;
        END;
      END
      ELSE
      BEGIN
        IF (@p_X0 < @p_X1) 
        BEGIN
          IF (@p_Y0 < @p_Y1) 
            SET @v_angle = atan(abs(@p_X0 - @p_X1) / abs(@p_Y0 - @p_Y1))
          ELSE /* ( @p_Y0 > @p_Y1 ) - equality case handled above */
            SET @v_angle = atan(abs(@p_Y0 - @p_Y1) / abs(@p_X0 - @p_X1)) + (PI() / 2);
        END
        ELSE
        BEGIN /* ( @p_X0 > @p_X1 ) - equality case handled above */
          IF (@p_Y0 > @p_Y1) 
            SET @v_angle = atan(abs(@p_X0 - @p_X1) / abs(@p_Y0 - @p_Y1)) + PI()
          ELSE /* ( @p_Y0 < @p_Y1 ) - equality case handled above */
            SET @v_angle = atan(abs(@p_Y0 - @p_Y1) / abs(@p_X0 - @p_X1)) + (PI() + (PI() / 2));
        END;
      END;
    END;
    Return @v_angle;
  End;
END;
GO

PRINT 'Testing [$(cogoowner)].[STAzimuth] ...';
GO

select case when [$(cogoowner)].[STDegrees]([$(cogoowner)].[STAzimuth] (10,0.123,0,0)) = [$(cogoowner)].[STBearing](10,0.123,0,0) then 'Equals' else 'Not Equal' end as az;
GO

