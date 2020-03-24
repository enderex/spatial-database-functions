SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STAppend] ...';
GO

PRINT '1. LineString Append LineString ....';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0 1,0 0 0 5.6)',0) as baseLine
),
appendLines as (
  select 'No Shared Point Linestrings => MultiLineString' as test, 
         geometry::STGeomFromText('LINESTRING(10 0 0 15.61, 10 10 0 25.4)',0) as aline
  union all
  select 'End / Start => Single LineString' as test, 
         geometry::STGeomFromText('LINESTRING(0 0 0 5.6, 10 10 0 25.4)',0) as aline
  union all
  select 'Start / End => Single LineString' as test, 
         geometry::STGeomFromText('LINESTRING(-1 -1 0 5.6,-4 -4 0 1)',0) as aline
  union all
  select 'End / End Linestrings => Single LineString' as test, 
         geometry::STGeomFromText('LINESTRING(10 10 0 25.4,0 0 0 5.6)',0) as aline
  union all
  select 'Start / Start Linestrings => Single LineString' as test, 
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, -1 -1 0 5.2)',0) as aline
) 
SELECT test, 
       baseline.AsTextZM() as baseLine, 
       aLine.AsTextZM() as aLine, 
       concatline.AsTextZM() as concatLine, 
       concatline.STIsValid() as vConcatLine,
       xyLine.AsTextZM() as xyLine
  FROM ( SELECT test, 
                [$(owner)].[STAppend]( d.baseLine, a.aline, 3, 2) as concatline,
                d.baseLine, 
                a.aLine,
                d.baseLine.STUnion(a.aLine) as xyLine
           from data as d cross apply appendLines as a
       ) as f;
GO

PRINT '2. CircularString Append CircularString ....';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING(-5 0 0 1,-2.5 -2.5 0 1.5,0 0 0 5.6)',0) as baseLine
),
appendLines as (
  select 'No Shared Point Linestrings => MultiLineString' as test, 
         geometry::STGeomFromText('CIRCULARSTRING(1 1 0 5.6, 5 5 0 6.3,5 10 0 9.6)',0) as aline
  Union all
  select 'End / Start => Single CircularString' as test, 
         geometry::STGeomFromText('CIRCULARSTRING(0 0 0 5.6, 2.5 2.5 0 6.3,4 0 0 9.6)',0) as aLine
  union all
  select 'Start / End CircularString => Single CircularString' as test, 
         geometry::STGeomFromText('CIRCULARSTRING(-10 0 0 4.5,-5 5 0 2.5,-5 0 0 1)',0) as aline
  union all
  select 'Start / Start CircularString => Single CircularString' as test, 
         geometry::STGeomFromText('CIRCULARSTRING(-5 0 0 1, -5 5 0 2.5, -10 0 0 4.5)',0) as aline
  union all
  select 'End / End CircularString => Single CircularString' as test, 
         geometry::STGeomFromText('CIRCULARSTRING(2 0 0 5.6, 1 2 0 1.5, 0 0 0 5.6)',0) as aline
) 
SELECT test, 
       baseline.AsTextZM() as baseLine, 
       aLine.AsTextZM() as aLine, 
       concatline.AsTextZM() as concatLine, 
       concatline.STIsValid() as vConcatLine,
       xyLine.AsTextZM() as xyLine
  FROM ( SELECT test, 
                [$(owner)].[STAppend]( d.baseLine, a.aline, 3, 2) as concatline,
                d.baseLine, 
                a.aLine,
                d.baseLine.STUnion(a.aLine) as xyLine
           from data as d cross apply appendLines as a
       ) as f;
GO

PRINT '3. Linestring Append CircularString ....';
GO
SELECT test, 
       baseline.AsTextZM() as baseLine, 
       aLine.AsTextZM() as aLine, 
       concatline.AsTextZM() as concatLine, 
       concatline.STIsValid() as vConcatLine,
       xyLine.AsTextZM() as xyLine
  FROM ( SELECT test, 
                [$(owner)].[STAppend]( d.baseLine, d.aline, 3, 2) as concatline,
                d.baseLine, 
                d.aLine,
                d.baseLine.STUnion(d.aLine) as xyLine
           from (
select 'End / Start' as test,
       geometry::STGeomFromText('LINESTRING(-4 -4 0 1,0 0 0 5.6)',0) as baseLine,
       geometry::STGeomFromText('CIRCULARSTRING(0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6)',0) as aLine
-- COMPOUNDCURVE (CIRCULARSTRING (5 10, 5 5, 0 0), (0 0, -4 -4))
union all
select 'End / End',
       geometry::STGeomFromText('LINESTRING(-4 -4 0 1,0 0 0 5.6)',0) as baseLine,
       geometry::STGeomFromText('CIRCULARSTRING(5 10 0 9.6,5 5 0 6.3, 0 0 0 5.6)',0) as aLine
-- COMPOUNDCURVE (CIRCULARSTRING (5 10, 5 5, 0 0), (0 0, -4 -4))
union all
select 'Start / End',
       geometry::STGeomFromText('CIRCULARSTRING(0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6)',0) as baseLine,
       geometry::STGeomFromText('LINESTRING(-4 -4 0 1,0 0 0 5.6)',0) as aLine
-- COMPOUNDCURVE (CIRCULARSTRING (5 10, 5 5, 0 0), (0 0, -4 -4))
union all
select 'Start / Start',
       geometry::STGeomFromText('CIRCULARSTRING(0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6)',0) as baseLine,
       geometry::STGeomFromText('LINESTRING(0 0 0 5.6, -4 -4 0 1)',0) as aLine
-- COMPOUNDCURVE (CIRCULARSTRING (5 10, 5 5, 0 0), (0 0, -4 -4))
union all
select 'Disjoint',
       geometry::STGeomFromText('LINESTRING(-4 -4 0 1,-2 -2 0 5.6)',0) as baseLine,
       geometry::STGeomFromText('CIRCULARSTRING(0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6)',0) as aLine
-- GEOMETRYCOLLECTION (CIRCULARSTRING (5 10, 5 5, 0 0), LINESTRING (-2 -2, -4 -4))
          ) as d
       ) as f;
GO

PRINT '4. MultiLineString Append LineString ....';
GO

SELECT test, 
       baseline.AsTextZM() as baseLine, 
       aLine.AsTextZM() as aLine, 
       concatline.AsTextZM() as concatLine, 
       concatline.STIsValid() as vConcatLine,
       xyLine.AsTextZM() as xyLine
  FROM ( SELECT test, 
               [$(owner)].[STAppend]( d.baseLine, d.aline, 3, 2) as concatline,
               --[$(owner)].[STAppend]( d.baseLine, d.aline, 3, 2) as concatline,
                d.baseLine, 
                d.aLine,
                d.baseLine.STUnion(d.aLine) as xyLine
           from (
select 'End / End' as test,
       geometry::STGeomFromText('MULTILINESTRING((-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6))',0) as baseLine,
       geometry::STGeomFromText('LINESTRING(-0.5 -0.5 0 5.6,-0.25 -0.25 0 5.5)',0) as aLine
--MULTILINESTRING ((-5 0 0 1, -2.5 -2.5 0 1.5, -0.5 -0.5 0 5.6, -0.25 -0.25 0 5.5), (0 0 0 5.6, 5 5 0 6.3, 5 10 0 9.6))
Union All
select 'Disjoint' as test,
       geometry::STGeomFromText('MULTILINESTRING((-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6))',0) as baseLine,
       geometry::STGeomFromText('LINESTRING(100.5 50.5 0 5.6,101 51 0 5.5)',0) as aLine
-- MULTILINESTRING ((-5 0 0 1, -2.5 -2.5 0 1.5, -0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3, 5 10 0 9.6), (100.5 50.5 0 5.6, 101 51 0 5.5))
       ) as d
    ) as f;
GO

PRINT '5. MultiLineString Append CircularString Using STUnion ....';
GO

select geometry::STGeomFromText('MULTILINESTRING((-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6))',0)
       .STUnion(
       geometry::STGeomFromText('CIRCULARSTRING(-0.5 -0.5 0 5.6,-0.2 -0.4 0 5.5, -0.1 -0.1 0 5.65)',0)
       ).AsTextZM();
GO
-- GEOMETRYCOLLECTION (LINESTRING (5 10, 5 5, 0 0), COMPOUNDCURVE ((-5 0, -2.5 -2.5, -0.5 -0.5), CIRCULARSTRING (-0.5 -0.5, -0.2 -0.4, -0.1 -0.1)))

select dbo.STAppend(
geometry::STGeomFromText('LINESTRING(2173378.16228123 260432.846523359 NULL 2206.1746,2173355.55940427 260371.804622516 NULL 2271.2667,2173350.99754606 260362.115766078 NULL 2281.9758)',2274),
geometry::STGeomFromText('LINESTRING(2173378.16228123 260432.846523359 NULL 2206.1746,2173381.19882422 260470.679448103 NULL 0)',2274),
3,3).AsTextZM();
-- LINESTRING (2173350.998 260362.116 NULL 2281.976, 2173355.559 260371.805 NULL 2271.267, 2173378.162 260432.847 NULL 2206.175, 2173381.19882422 260470.679448103 NULL 0)

select dbo.STAppend(
geometry::STGeomFromText('LINESTRING(2173378.16228123 260432.846523359 NULL 2206.1746,2173355.55940427 260371.804622516 NULL 2271.2667,2173350.99754606 260362.115766078 NULL 2281.9758)',2274),
geometry::STGeomFromText('COMPOUNDCURVE ((2173251.19755045 260565.663264811 NULL 2000,2173324.62503405 260532.888690099 NULL 2080.4098),
 CIRCULARSTRING (2173324.62503405 260532.888690099 NULL 2080.4098,2173345.78352624 260520.72691965 NULL 0,2173364.04390489 260504.535902888 NULL 2129.3036),
 CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036,2173381.19882422 260470.679448103 NULL 0,2173378.16228123 260432.846523359 NULL 2206.1746))',2274),
3,3).AsTextZM() as geom;
-- COMPOUNDCURVE ((2173251.19755045 260565.663264811 NULL 2000, 2173324.62503405 260532.888690099 NULL 2080.4098), CIRCULARSTRING (2173324.62503405 260532.888690099 NULL 2080.4098, 2173345.78352624 260520.72691965 NULL 0, 2173364.04390489 260504.535902888 NULL 2129.3036), CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036, 2173381.19882422 260470.679448103 NULL 0, 2173378.16228123 260432.846523359 NULL 2206.1746), (2173378.16228123 260432.846523359 NULL 2206.1746, 2173355.55940427 260371.804622516 NULL 2271.2667, 2173350.99754606 260362.115766078 NULL 2281.9758))

select dbo.STAppend(
geometry::STGeomFromText('CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036,2173381.19882422 260470.679448103 NULL 0,2173378.16228123 260432.846523359 NULL 2206.1746)',2274),
geometry::STGeomFromText('CIRCULARSTRING (2173378.16228123 260432.846523359 NULL 2206.1746,2173336.7026266 260144.609642233 NULL 0,2173474.30695651 259975.558445781 NULL 2728.2803)',2274),
 3,3).AsTextZM();
-- CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036, 2173381.19882422 260470.679448103 NULL 0, 2173378.16228123 260432.846523359 NULL 2206.1746, 2173336.7026266 260144.609642233 NULL 0, 2173474.30695651 259975.558445781 NULL 2728.2803)

