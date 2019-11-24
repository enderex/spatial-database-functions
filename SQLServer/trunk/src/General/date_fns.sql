SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[dhms]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[dhms];
  PRINT 'Dropped [$(owner)].[dhms] ...';
END;
GO

PRINT 'Creating [$(owner)].[dhms] ...'
GO

CREATE FUNCTION [$(owner)].[dhms] 
( 
  @p_seconds float 
) 
RETURNS varchar(100)
/****f* TOOLS/dhms (2008)
 *  NAME
 *    dhms -- Function that takes a duration/time in seconds and returns a string that include the number of elapsed days.
 *  SYNOPSIS
 *    Function dhms(@p_seconds float)
 *     Returns varchar(100)
 *  USAGE
 *     SELECT [$(owner)].dhms((2.0 * 24.0 * 60.0 * 60.0) + 923.3) as dhms;
 *     dhms
 *     2:00:15:23:300
 *     SELECT [$(owner)].dhms((2.0 * 24.0 * 60.0 * 60.0) + 923) as dhms;
 *     dhms
 *     2:00:15:23
 *  DESCRIPTION
 *    Function that takes a duration expressed in seconds, and returns a string that included days, hours, minutes and seconds.
 *    ie  DAYS:HOURS:MINUTES:SECONDS{:MICROSECONDS}
 *    If the input seconds has decimal places, they are returned, if not they aren't.
 *  INPUTS
 *    @p_seconds      (float) : Non-NULL duration expressed in seconds.
 *  RESULT
 *    formated date (varchar) : Date formatted as DAYS:HOURS:MINUTES:SECONDS{:MICROSECONDS}
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
AS
BEGIN
  DECLARE 
    @days float,
    @dhms varchar(100);
  IF (@p_seconds is null)
    Return null;
  SET @days = FLOOR(@p_seconds / (24.0 * 60.0 * 60.0));
  SET @dhms = CAST(@days as varchar(10)) + 
              ':' +
              CONVERT(varchar(100), 
                      DATEADD(ms, 1000.0 * ( @p_seconds - (@days * 24.0 * 60.0 * 60.0)),0.0), 
                      114);
  RETURN case when /* Does @p_seconds have decimal places? */
                   PARSENAME(@p_seconds,1) = FLOOR(@p_seconds)
              then REPLACE(@dhms,':000','')
              else @dhms
          end;
END
GO

PRINT 'Textingt [$(owner)].[dhms] ...'
GO

SELECT [$(owner)].dhms((2.0 * 24.0 * 60.0 * 60.0) + 923.3) as dhms;


