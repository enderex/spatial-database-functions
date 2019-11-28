SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[DMS2DD]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[DMS2DD];
  Print 'Dropped [$(cogoowner)].[DMS2DD] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[DMSS2DD]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[DMSS2DD];
  Print 'Dropped [$(cogoowner)].[DMSS2DD] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[DD2DMS]') 
             AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[DD2DMS];
  Print 'Dropped [$(cogoowner)].[DD2DMS] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STDegrees]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STDegrees];
  PRINT 'Dropped [$(cogoowner)].[STDegrees] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STRadians2Degrees]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STRadians2Degrees];
  PRINT 'Dropped [$(cogoowner)].[STRadians2Degrees] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STNormalizeBearing]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STNormalizeBearing];
  PRINT 'Dropped [$(cogoowner)].[STNormalizeBearing] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STNormalizeBearing] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STNormalizeBearing]
(
  @p_bearing float
)
Returns float
As
/****f* COGO/STNormalizeBearing (2008)
 *  NAME
 *    STNormalizeBearing -- Function ensures supplied bearing is between 0 and 360. 
 *  SYNOPSIS
 *    Function STNormalizeBearing(@p_bearing float)
 *     Returns Float
 *  USAGE
 *    SELECT [$(cogoowner)].[STNormalizeBearing](450.39494) as bearing;
 *    bearing
 *    90.39494
 *  DESCRIPTION
 *    Function that ensures supplied bearing is between 0 and 360 degrees (360 = 0).
 *  INPUTS
 *    @p_bearing (float) : Non-NULL decimal bearing.
 *  RESULT
 *    bearing (float) : Bearing between 0 and 360 degrees.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  return case when @p_bearing < 0 
              then @p_bearing + 360
              when @p_bearing >= 360
              then @p_bearing - 360
              else @p_bearing
           end;
End;
GO

PRINT 'Creating [$(cogoowner)].[DMS2DD] ...';
GO

CREATE FUNCTION [$(cogoowner)].[DMS2DD]
(
  @p_dDeg Int,
  @p_dMin Int,
  @p_dSec Float
)
Returns Float
AS
/****f* COGO/DMS2DD (2008)
 *  NAME
 *    DMS2DD -- Function computes a decimal degree floating point number from individual degrees, minutes and seconds values.
 *  SYNOPSIS
 *    Function DMS2DD(@p_dDeg  Int,
 *                    @p_dMin  Int,
 *                    @p_dSec  Float )
 *     Returns Float
 *  USAGE
 *    SELECT [$(cogoowner)].[DMS2DD](45,30,30) as DD;
 *    DD
 *    45.5083333333333
 *  DESCRIPTION
 *    Function that computes the decimal equivalent to the supplied degrees, minutes and seconds values.
 *    No checking of the values of each of the inputs is conducted: one can supply 456 minutes if one wants to!
 *  NOTES
 *    Normalization of the returned value to ensure values are between 0 and 360 degrees can be conducted via the STNormalizeBearing function.
 *  INPUTS
 *    @p_dDeg (int)   : Non-NULL degree value (0-360)
 *    @p_dMin (int)   : Non-NULL minutes value (0-60)
 *    @p_dSec (float) : Non-NULL seconds value (0-60)
 *  RESULT
 *    DecimalDegrees (float) : Decimal degrees equivalent value.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
Begin
    Declare
       @dDD Float;
    BEGIN
       IF ( @p_dDeg IS NULL OR
            @p_dMin IS NULL OR
            @p_dSec IS NULL )
          RETURN NULL;   
       SET @dDD = ABS(@p_dDeg) + @p_dMin / 60.0 + @p_dSec / 3600.0;
       Return SIGN(@p_dDeg) * @dDD;
    End;
End;
Go

PRINT 'Creating [$(cogoowner)].[DMSS2DD] ...';
GO

CREATE FUNCTION [$(cogoowner)].[DMSS2DD] 
(
  @p_strDegMinSec nvarchar(100)
)
Returns Float
As 
/****f* COGO/DMSS2DD (2008)
 *  NAME
 *    DMSS2DD -- Function computes a decimal degree floating point number from individual degrees, minutes and seconds values encoded in supplied string.
 *  SYNOPSIS
 *    Function DMSS2DD(@p_strDegMinSec nvarchar(100))
 *     Returns Float
 *  USAGE
 *    SELECT [$(cogoowner)].[DMSS2DD]('43° 0'' 50.00"S') as DD;
 *    DD
 *    -43.0138888888889
 *  DESCRIPTION
 *    The function parses the provided string (eg extracted from Google Earth) that contains DD MM SS.SS values, extracts and creates a single floating point decimal degrees value.
 *    No checking of the values of each of the inputs is conducted: one can supply 456 minutes if one wants to!
 *    The function honours N, S, E and W cardinal references.
 *  NOTES
 *    Normalization of the returned value to ensure values are between 0 and 360 degrees can be conducted via the STNormalizeBearing function.
 *  INPUTS
 *    @p_strDegMinSec (nvarchar(100)) : DD MM SS.SS description eg 43° 0'' 50.00"S
 *  RESULT
 *    DecimalDegrees (float) : Decimal degrees equivalent value.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
BEGIN
   DECLARE
       @i               Int = 0,
       @intDmsLen       Int = -1,            --Length of original string
       @strCompassPoint NVarChar(1),
       @strNorm         Nvarchar(100) = N'', --Will contain normalized string
       @strDegMinSecB   Nvarchar(100),
       @token           Nvarchar(100),
       @strChr          NVarChar(1),
       @blnGotSeparator integer = -1,        -- Keeps track of separator sequences
       @dDeg            Float   = 0,
       @dMin            Float   = 0,
       @dSec            Float   = 0,
       @dReturnDecimal  Float   = 0.0;
    BEGIN
       -- Remove leading and trailing spaces
       SET @strDegMinSecB = REPLACE(@p_strDegMinSec,' ','');
       -- assume no leading and trailing spaces?
       SET @intDmsLen = DATALENGTH(@strDegMinSecB);
       SET @blnGotSeparator = 0; -- Not in separator sequence right now
       -- Loop over string, replacing anything that is not a digit or a
       -- decimal separator with
       -- a single blank
       SET @i = 0;
       WHILE ( @i <= @intDmsLen)
       BEGIN
          SET @i = @i + 1;
          -- Get current character
          SET @strChr = SUBSTRING(@strDegMinSecB, @i, 1);
          -- either add character to normalized string or replace
          -- separator sequence with single blank
          IF (CHARINDEX(@strChr,N'0123456789,.') > 0 )
          BEGIN
             -- add character but replace comma with point
             IF ((@strChr <> N',') )
             BEGIN
                SET @strNorm = @strNorm + @strChr;
             END
             Else
             BEGIN
                SET @strNorm = @strNorm + N'.';
             END;
             SET @blnGotSeparator = 0;
          END;
          ELSE
          BEGIN
            IF (CHARINDEX(@strChr,N'neswNESW') > 0 ) -- Extract Compass Point IF (present
            BEGIN
              SET @strCompassPoint = UPPER(@strChr);
            END;
            ELSE
            BEGIN
               -- ensure only one separator is replaced with a marker -
               -- suppress the rest
               IF (@blnGotSeparator = 0 )
               BEGIN
                  SET @strNorm = @strNorm + N'@';
                  SET @blnGotSeparator = 0;
               END;
             END;
          END;
       END /* LOOP */
       -- Split normalized string into array of max 3 components
       DECLARE tokenList CURSOR FOR
          SELECT a.token 
            FROM [$(owner)].[Tokenizer](@strNorm,N'@') a;
       OPEN tokenList
       FETCH NEXT FROM tokenList 
        INTO @token
       SET @i = 1;
       WHILE ( @@FETCH_STATUS = 0 )
       BEGIN
          --convert specified components to double
         IF ( @i = 1 ) SET @dDeg = CAST(@token AS FLOAT);
         IF ( @i = 2 ) SET @dMin = CAST(@token AS FLOAT);
         IF ( @i = 3 ) SET @dSec = CAST(@token AS FLOAT);
         SET @i = @i + 1
         FETCH NEXT FROM tokenList INTO @token
       END;
       CLOSE tokenList
       DEALLOCATE tokenList
       -- convert components to value
       SET @dReturnDecimal = CASE WHEN UPPER(@strCompassPoint) IN (N'S',N'W') 
                                  THEN -1 
                                  ELSE 1 
                              END 
                             *
                             (@dDeg + @dMin / 60 + @dSec / 3600);
       RETURN @dReturnDecimal;
    End;
END;
GO

PRINT 'Creating [$(cogoowner)].[DD2DMS] ...';
GO

CREATE FUNCTION [$(cogoowner)].[DD2DMS] 
(
  @dDecDeg       Float,
  @pDegreeSymbol NVarChar(1),
  @pMinuteSymbol NVarChar(1),
  @pSecondSymbol NVarChar(1) 
)
Returns nvarchar(50)
AS
/****f* COGO/DD2DMS (2008)
 *  NAME
 *    DD2DMS -- Function converts a decimal degree floating point number to its string equivalent.
 *  SYNOPSIS
 *    Function [$(cogoowner)].[DD2DMS] (
 *               @dDecDeg       Float,
 *               @pDegreeSymbol NVarChar(1),
 *               @pMinuteSymbol NVarChar(1),
 *               @pSecondSymbol NVarChar(1) 
 *             )
 *     Returns nvarchar(50)
 *  USAGE
 *     SELECT [$(cogoowner)].[DD2DMS](45.5083333333333,'^','''','"') as DMS;
 *     DMS
 *     45^30'30.00"
 *     
 *     SELECT [$(cogoowner)].[DD2DMS](45.5083333333333,CHAR(176),CHAR(39),'"') as DMS;
 *     DMS
 *     45°30'30.00"
 *  DESCRIPTION
 *    Function that converts the supplied decimal degrees value to a string using the supplied symbols.
 *  NOTES
 *    Normalization of the returned value to ensure values are between 0 and 360 degrees can be conducted via the STNormalizeBearing function.
 *    Useful for working with Google Earth
 *  INPUTS
 *    @dDecDeg       (Float)       - Decimal degrees value.
 *    @pDegreeSymbol (NVarChar(1)) - Degrees symbol eg ^
 *    @pMinuteSymbol (NVarChar(1)) - Seconds symbol eg '
 *    @pSecondSymbol (NVarChar(1)) - Seconds symbol eg "
 *  RESULT
 *    DMS (string) : Decimal degrees string equivalent.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
BEGIN
  Declare
    @iDeg  Int,
    @iMin  Int,
    @dSec  Float,
    @iSign Int;
  Begin
    SET @iSign = SIGN(@dDecDeg);
    SET @iDeg  = ABS(Cast(@dDecDeg as Int));
    SET @iMin  = Cast(((Abs(@dDecDeg) - Abs(@iDeg)) * 60) as Int);
    SET @dSec  = Round((((Abs(@dDecDeg) - Abs(@iDeg)) * 60) - @iMin) * 60, 3);
    IF (Round(@dSec,3) >= 60.0 ) 
	BEGIN
      SET @dSec = 0.0;
      SET @iMin = @iMin + 1;
    End;
    IF ( @iMin >= 60 ) 
	Begin
      SET @iMin = 0;
      SET @iDeg = @iDeg + 1;
    End;
    IF ( @iDeg >= 360 ) 
	Begin
      SET @iDeg = 0;
    End;
    Return STR(@iSign * @iDeg,4,0) + @pDegreeSymbol + STR(@iMin,2,1) + @pMinuteSymbol + STR(@dSec,5,3) + @pSecondSymbol;
  End;
END;
GO

Print 'Creating [$(cogoowner)].[STRadians2Degrees] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STRadians2Degrees]
(
  @p_radians float
)
RETURNS float
BEGIN
  IF ( @p_radians is null ) 
    RETURN NULL;
  RETURN @p_radians * (CAST(180.0 as float)/PI());
END;
GO

PRINT 'Creating [$(cogoowner)].[STDegrees]...';
GO

CREATE FUNCTION [$(cogoowner)].[STDegrees]
(
  @p_radians float
)
RETURNS float
BEGIN
  IF ( @p_radians is null ) 
    RETURN NULL;
  RETURN @p_radians * (CAST(180.0 as float)/PI());
END;
go



