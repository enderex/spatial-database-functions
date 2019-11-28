SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[Tokenizer] ...';
GO

select distinct t.token from $(owner).Tokenizer('LineString:MultiLineString:MultiPoint:MultiPolygon:Point:Point:LineString:Polygon:Polygon',':') as t;
GO

SELECT t.* FROM $(owner).tokenizer('The rain in spain, stays mainly on the plain.!',' ,.!') t;
GO

SELECT t.id, t.token, t.separator FROM $(owner).tokenizer('POLYGON((2300 400, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400), (2300 1000, 2400  900, 2200 900, 2300 1000))',' ,()') as t;
GO

SELECT t.id, t.token, t.separator FROM $(owner).tokenizer('POLYGON((2300 400, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400), (2300 1000, 2400  900, 2200 900, 2300 1000))',',()') as t;
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


