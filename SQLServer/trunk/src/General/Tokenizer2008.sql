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
  DROP FUNCTION  [$(owner)].[Tokenizer];
  PRINT 'Dropped [$(owner)].[Tokenizer] ...';
END;
GO

PRINT 'Creating [$(owner)].[Tokenizer] ...';
GO

CREATE FUNCTION [$(owner)].[Tokenizer]
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
/****f* TOOLS/Tokenizer (2008)
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
 *    Pawel Barut, http://pbarut.blogspot.com/2007/03/yet-another-tokenizer-in-oracle.html
 *    Simon Greener - Aug 2008 - Converted to SQL Server 2008
 *    Simon Greener - Aug 2012 - Added extra return variables.
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
                                from $(owner).generate_series(1,DATALENGTH(@p_string),1) c 
                              ) a
                      ) b,
                      (select SUBSTRING(@p_separators,d.IntValue,1) as sep
                          from $(owner).generate_series(1,DATALENGTH(@p_separators),1) d
                        ) c
                Where CHARINDEX(c.sep,SUBSTRING(@p_string,b.beg,1)) > 0
              Union All Select 0 as beg, CAST(NULL AS varchar) as sep
             ) c
    )
    Insert Into @varchar_table
    Select Row_Number() Over (Order By a.rid ASC) as Id, 
           Case When DataLength(a.token) = 0 Then null Else a.token End as token, 
           a.sep
      From (Select d.rid,
                    SUBSTRING(@p_string, 
                             (d.beg + 1), 
                             (d.end_p - d.beg - 1) ) token,
                   d.sep
               From (Select BASE.rid,
                          BASE.beg,
                          LEAD.beg end_p,
                          LEAD.sep sep
                     From MyCTE BASE LEFT JOIN MyCTE LEAD ON BASE.rid = LEAD.rid-1
                   ) d
               Where d.end_p Is Not Null
           ) as a ;
    Return;
  End;
End;
GO

PRINT 'Testing [$(owner)].[Tokenizer] ...';
GO

select distinct t.token
 from $(owner).Tokenizer('LineString:MultiLineString:MultiPoint:MultiPolygon:Point:Point:LineString:Polygon:Polygon',':') as t;
GO

SELECT t.*
  FROM $(owner).tokenizer('The rain in spain, stays mainly on the plain.!',' ,.!') t;
GO

SELECT t.id, t.token, t.separator
  FROM $(owner).tokenizer('POLYGON((2300 400, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400), (2300 1000, 2400  900, 2200 900, 2300 1000))',' ,()') as t;
GO

SELECT t.id, t.token, t.separator
  FROM $(owner).tokenizer('POLYGON((2300 400, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400), (2300 1000, 2400  900, 2200 900, 2300 1000))',',()') as t;
GO

-- Reverse
SELECT SUBSTRING(a.gtype,5,LEN(a.gtype)) + ''''''
  FROM (SELECT (STUFF((SELECT DISTINCT ''''',''''' + a.gtype
                         FROM ( select distinct t.token as gtype
                                  from $(owner).Tokenizer('LineString:MultiLineString:MultiPoint:MultiPolygon:Point:Point:LineString:Polygon:Polygon',':') as t
                              ) a
                        ORDER BY ''''',''''' + a.gtype
                       FOR XML PATH(''), TYPE, ROOT).value('root[1]','nvarchar(max)'),1,1,'''')
                ) AS gtype
        ) as a;
GO


