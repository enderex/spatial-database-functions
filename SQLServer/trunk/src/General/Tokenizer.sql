SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[Tokenizer]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[Tokenizer];
  Print 'Dropped [$(owner)].[Tokenizer] ...';
END;
GO

Print 'Creating [$(owner)].[Tokenizer] ...';
GO

Create Function [$(owner)].[Tokenizer]
(
  @p_string     VarChar(MAX),
  @p_separators VarChar(254)
)
Returns @varchar_table TABLE 
(
  id        int,
  token     varchar(MAX),
  separator varchar(MAX)
)
As
/****f* TOOLS/Tokenizer (2012)
 *  NAME
 *    Tokenizer - Splits any string into tokens and separators.
 *  SYNOPSIS
 *    Function Tokenizer (
 *       @p_string     varchar(max),
 *       @p_separators varchar(254)
 *     )
 *     Returns @varchar_table TABLE 
 *     (
 *       id        int,
 *       token     varchar(MAX),
 *       separator varchar(MAX)
 *     ) 
 *  EXAMPLE
 *
 *    SELECT t.id, t.token, t.separator
 *      FROM [$(owner)].[TOKENIZER]('LINESTRING(0 0,1 1)',' ,()') as t
 *    GO
 *    id token       separator
 *    -- ---------- ---------
 *     1 LINESTRING (
 *     2 0          NULL
 *     3 0          ,
 *     4 1          NULL 
 *     5 1          )
 *
 *  DESCRIPTION
 *    Supplied a string and a list of separators this function returns resultant tokens as a table collection.
 *    Function returns both the token and the separator.
 *    Returned table collection contains a unique identifier to ensure tokens and separators are always correctly ordered.
 *  INPUTS
 *    @p_string     (varchar max) - Any non-null string.
 *    @p_separators (varchar 254) - List of separators eg '(),'
 *  RESULT
 *    Table (Array) of Integers
 *      id        (int)         - Unique identifier for each row starting with first token/separator found.
 *      token     (varchar MAX) - Token between separators
 *      separator (varchar MAX) - Separator between tokens.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 2012 - Converted to SQL Server 2012 (Uses new Lag/Lead function and returns separators)
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Begin
    With MyCTE As (
      Select c.beg, 
             c.sep, 
             ROW_NUMBER() OVER(ORDER BY c.beg ASC) as rid
        From (Select b.beg, c.sep
                From (Select a.beg 
                        From (select c.IntValue as beg
                                from [$(owner)].[GENERATE_SERIES](1,DATALENGTH(@p_string),1) c 
                              ) a
                      ) b,
                      (select SUBSTRING(@p_separators,d.IntValue,1) as sep
                          from [$(owner)].[GENERATE_SERIES](1,DATALENGTH(@p_separators),1) d
                        ) c
                Where CHARINDEX(c.sep,SUBSTRING(@p_string,b.beg,1)) > 0
              Union All Select 0 as beg, @p_string as sep
             ) c
    )
    Insert Into @varchar_table
    Select Row_Number() Over (Order By a.rid ASC) as Id, 
           Case When DataLength(a.token) = 0 Then null Else a.token End as token, 
           a.sep
      From (Select d.rid,
                   SubString(@p_string, (d.beg + 1), (Lead(d.beg,1) Over (Order By d.rid asc) - d.beg - 1) ) as token,
                   Lead(d.sep,1) Over (Order By d.rid asc) as sep
              From MyCTE d 
           ) as a
     Where DataLength(a.token) <> 0 or DataLength(a.sep) <> 0;
    Return;
  End;
End
GO

PRINT 'Testing [$(owner)].[TOKENIZER] ...';
GO

select t.token
 from [$(owner)].[TOKENIZER]('LineString:MultiLineString:MultiPoint:MultiPolygon:Point:Point:LineString:Polygon:Polygon',':') as t
GO

select distinct t.token
 from [$(owner)].[TOKENIZER]('LineString:MultiLineString:MultiPoint:MultiPolygon:Point:Point:LineString:Polygon:Polygon',':') as t
GO

SELECT t.*
  FROM [$(owner)].[TOKENIZER]('The rain in spain, stays mainly on the plain.!',' ,.!') t
GO

SELECT t.id, t.token, t.separator
  FROM [$(owner)].[TOKENIZER]('POLYGON((2300 400, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400), (2300 1000, 2400  900, 2200 900, 2300 1000))',' ,()') as t
GO

SELECT t.id, t.token, t.separator
  FROM [$(owner)].[TOKENIZER]('POLYGON((2300 400, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400), (2300 1000, 2400  900, 2200 900, 2300 1000))',',()') as t
GO

SELECT SUBSTRING(a.gtype,5,LEN(a.gtype)) + ''''''
  FROM (SELECT (STUFF((SELECT DISTINCT ''''',''''' + a.gtype
                         FROM ( select distinct t.token as gtype
                                  from [$(owner)].[TOKENIZER]('LineString:MultiLineString:MultiPoint:MultiPolygon:Point:Point:LineString:Polygon:Polygon',':') as t
                              ) a
                        ORDER BY ''''',''''' + a.gtype
                       FOR XML PATH(''), TYPE, ROOT).value('root[1]','nvarchar(max)'),1,1,'''')
                ) AS gtype
        ) as a
GO



