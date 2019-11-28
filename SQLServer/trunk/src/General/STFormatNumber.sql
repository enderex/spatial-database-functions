SET QUOTED_IDENTIFIER ON 
SET ANSI_NULLS ON 
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STFormatNumber]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STFormatNumber];
  PRINT 'Dropped [$(owner)].[STFormatNumber] ...';
END;
GO

PRINT 'Creating [$(owner)].[STFormatNumber] ...';
GO

CREATE FUNCTION [$(owner)].[STFormatNumber] 
(
  @number        decimal(38,15), 
  @decimalplaces int=0, 
  @format        varchar(115) = '',
  @ifzero        varchar(115) = '0',
  @ifNull        varchar(115) ='NULL'
) 
Returns varchar(256)
AS  
/**
  Valid @Format arguments (space between args is ignored)
  nothing -  returns the number unformatted
        $ - return the number preceded by a '$' sign 
        % - return the number followed by a '%' sign 
        , - place a , every 3 zeros in the whole number portion (thousands)
        c - divide the number by 100 - intended to calc percent values
        i - returns integer portion only with no formatting except commas if requested
        d - returns the decimal portion only with no formatting except commas if requested
        b - returns a blank string for 0 values
        ( - encloses negative numbers in brackets
        l - use leading zero
        r[int]r - rounds number outside of the decimal context
        z[int]z - zero fills to [int] width
**/
/****f* TOOLS/STFormatNumber (2008)
 *  NAME
 *    STFormatNumber -- Formats a number into a string.
 *  SYNOPSIS 
 *    FUNCTION [$(owner)].[STFORMATNUMBER] 
 *    (
 *      @number        decimal(38,15), 
 *      @decimalplaces int=0, 
 *      @format        varchar(115) = '',
 *      @ifzero        varchar(115) = '0',
 *      @ifNull        varchar(115) ='NULL'
 *    ) 
 *    Returns varchar(256)
 *  DESCRIPTION
 *    Creates a formatted string for the supplied number using supplied parameters.
 *  ARGUMENTS
 *    @number        (decimal 38 15)  -- number to format
 *    @decimalplaces (int)            -- Number decimal places
 *    @format        (varchar 115)    -- Format string.
 *    @ifzero        (varchar 115)    -- String for zeros eg '0'
 *    @ifNull        (varchar 115)    -- String for null values eg 'NULL'
 *  RESULT
 *    formatted number (varchar 256)  -- Formatted number
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN 
  DECLARE @fmtxt varchar(25), @parsetxt varchar(50)
       , @parsetxtdec varchar(50)
       , @decptloc int, @zerotext varchar(100)
       , @intpart varchar(25), @decpart varchar(25)
       , @ERR_type varchar(15), @roundto varchar(2)
       , @fillto varchar(50), @fillto# varchar(2)
   
  --A little error checking is in order
  IF @number IS NULL 
      RETURN  @ifNull -- '{ERR-null passed}'
  ELSE IF @decimalplaces < 0 
      RETURN  '{ERR-decimal spec <0}' 
  ELSE IF @decimalplaces >15 
      RETURN  '{ERR-decimal spec >15}'
   
  -- Handle zero values first
  IF @number = 0  RETURN @ifzero 
   
  -- Now 'C'alculate the percentage if requested using the '%c' arg.
  IF CHARINDEX('%c',@FORMAT) > 0  SET @number = @number * 100
   
  -- Do rounding outside if applicable
  IF CHARINDEX('r',@FORMAT) > 0 BEGIN
      SET @roundto = SUBSTRING(@FORMAT,CHARINDEX('r', @FORMAT)+1, 115)
      SET @roundto = LEFT(@roundto,CHARINDEX('r',@roundto)-1)
      SET @number = round(@number,cast(@roundto as integer))
  END
   
  -- Get the parsetext variable
  IF CHARINDEX(',',@FORMAT) > 0
      SET @parsetxt = CONVERT(varchar(100),CAST(@number as money),1)
  ELSE
      SET @parsetxt = CONVERT(varchar(100), @number)
   
  -- Grab some basic stuff
  SET @decptloc = ISNULL(CHARINDEX('.',@parsetxt),0)
   
  IF @decptloc = 0 
     RETURN @parsetxt
  ELSE
     SET @intpart = SUBSTRING(@parsetxt,1,@decptloc-1)
   
  -- Handle leading zeros
  IF CHARINDEX('l',@FORMAT) = 0 AND @intpart = '0' SET @intpart = ''
   
  -- Now build the decimal portion of the result
  SET @parsetxt = CONVERT(varchar(100),ROUND(@number,@decimalplaces),2)
  SET @decptloc = ISNULL(CHARINDEX('.',@parsetxt),0)
   
  IF @decimalplaces = 0
     SET @decpart = ''
  ELSE 
     SET @decpart =  LEFT(SUBSTRING(@parsetxt 
                                       + REPLICATE('0',@decimalplaces)
                                   ,@decptloc
                                   ,@decptloc+50)
                         ,@decimalplaces+1)
   
  --ASSEMBLE THE RESULTS --
   
  -- for just integer portion
  IF CHARINDEX('i',@FORMAT) > 0 
     RETURN @intpart
  -- for just decimal portion
  IF CHARINDEX('d',@FORMAT) > 0 
     RETURN  + @decpart
   
  SET @fmtxt =  @intpart  + @decpart
  --SET @fmtxt =  @intpart +'*'+ @decpart
   
  -- Handle brackets if requested
  IF CHARINDEX('(',@FORMAT) > 0 AND @number < 0 
           SET @fmtxt = '(' + RIGHT(@fmtxt,LEN(@fmtxt)-1) + ')'
   
  -- Add the symbols
  IF CHARINDEX('$',@FORMAT) > 0
      SET @fmtxt = '$' + @fmtxt
  ELSE IF CHARINDEX('%',@FORMAT) > 0
      SET @fmtxt = @fmtxt + '%'
   
  --Handle zero filling
  IF CHARINDEX('z',@FORMAT) > 0 BEGIN
    SET @fillto = SUBSTRING(@FORMAT,CHARINDEX('z',@FORMAT)+1,115)
    SET @fillto# = CAST(LEFT(@fillto,CHARINDEX('z',@fillto)-1) as INT)
    SET @fmtxt = RIGHT(REPLICATE('0',@fillto#) + @fmtxt,@fillto#)
  END
  RETURN  @fmtxt;
END;
GO
  
GRANT EXEC on [$(owner)].[STFORMATNUMBER] to PUBLIC
GO

