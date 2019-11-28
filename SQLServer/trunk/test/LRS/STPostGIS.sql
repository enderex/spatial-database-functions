SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STLineInterpolatePoint] ...';
GO

-- Linestring
select f.fraction,
       [$(lrsowner)].[STLineInterpolatePoint] (
          /* @p_linestring*/ geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0),
          /* @p_fraction  */ f.fraction,
          /* @p_round_xy  */ 4,
          /* @p_round_zm  */ 3
       ).AsTextZM() as fPoint
  from (select 0.01 * CAST(t.IntValue as numeric) as fraction
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
  order by f.fraction;
GO

-- Unmeasured Compound curve test.
select f.fraction,
       [$(lrsowner)].[STLineInterpolatePoint] (
          /* @p_linestring*/ geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
          /* @p_fraction  */ f.fraction,
          /* @p_round_xy  */ 4,
          /* @p_round_zm  */ 3
       ).AsTextZM() as fPoint
  from (select 0.01 * CAST(t.IntValue as numeric) as fraction
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
  order by f.fraction;
GO

-- ***************************************************************

Print 'Testing  [$(lrsowner)].[STLineLocatePoint] ...';
GO

select [$(lrsowner)].[STLineLocatePoint] (
           geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
           geometry::Point(8,8,28355),
           default,
           default
       ) as ratio
union all
select [$(lrsowner)].[STLineLocatePoint] (
          geometry::STGeomFromText('LINESTRING(-4 -4,0 0,10 0,10 10)',28355),
          geometry::Point(10,0,28355),
          4,
          8
       ) as ratio;
Go

-- ***************************************************************

Print 'Testing  [$(lrsowner)].[STLocateAlong] ...';
GO

-- Measured Linestring.
with data as (
  select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o;
GO

-- UnMeasured 2D Linestring.
with data as (
  select geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o;
GO

-- UnMeasured 2D Circular string and Compound curve.
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
  union all 
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o;
GO

-- ********************************************************************

PRINT 'STLocateBetween -> LineString ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
Select locateType, 
       sm,em,
       case when f.measureSegment is not null 
            then f.measureSegment.AsTextZM() 
            else null 
        end as measureSegment 
  from (
select 'SM 1.0/EM 1.0 => Start Point' as locateType,1.0 as sm,1.0 as em,  [$(lrsowner)].[STLocateBetween](linestring,1.0,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM 1.0/EM NULL => Whole Linestring',1.0,null,                     [$(lrsowner)].[STLocateBetween](linestring,1.0,null,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 1 => Start Point',null,1.0,                            [$(lrsowner)].[STLocateBetween](linestring,null,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 5.6 => Return 1s Segment',null,5.6,                    [$(lrsowner)].[STLocateBetween](linestring,null,5.6,0.0,3,2) as measureSegment from data as a
union all
select 'SM 5.6/EM 5.6 => 1st Segment EP or 2nd SP',5.6,5.6,               [$(lrsowner)].[STLocateBetween](linestring,5.6,5.6,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 5.0 Within First Segment => New Segment',2.0,5.0,       [$(lrsowner)].[STLocateBetween](linestring,2.0,5.0,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 6.0 => Two New Segments',2.0,6.0,                       [$(lrsowner)].[STLocateBetween](linestring,2,6,0,3,2) as measureSegment from data as a
union all
select 'SM 1.1/EM 25.4 => New 1st Segment, 2nd, New 3rd Segment',1.1,25.1,[$(lrsowner)].[STLocateBetween](linestring,1.1,25.1,0,3,2) as measureSegment from data as a
union all
select 'SM 0.1/EM 30.0 => whole linestring',0.1,30.0,                     [$(lrsowner)].[STLocateBetween](linestring,0.1,30.0,0,3,2) as measureSegment from data as a
) as f;
GO

-- *******************************************************************

Print '  [$(lrsowner)].[STInterpolatePoint] ...';
GO
Print '....Measured LineStrings';
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(8,8,28355),
         3,2) as measure
union all
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(10,0,28355),
         3,2) as measure;
GO

Print '....UnMeasured LineStrings';
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         geometry::Point(8,8,28355),
         3,3) as measure
union all
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         geometry::Point(10,0,28355),
         3,3) as measure;
GO

-- *****************************************************************************************

Print '  [$(lrsowner)].[STLineSubstring] ...';
Print '....Line SubString';
GO

select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         0.0,1.0,0.0,3,2).AsTextZM() as line
union all
select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         0.0,0.5,0.0,3,2).AsTextZM() as line;
GO

-- line
-- LINESTRING (-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)
-- LINESTRING (-4 -4 0 1, 0 0 0 5.6, 13.2 0 0 13.2)

Print '....UnMeasured LineStrings';
select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         0.0,1.0,0.0,3,2).AsTextZM() as line
union all
select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         0.0,0.5,0.0,3,2).AsTextZM() as line;
GO

-- line
-- LINESTRING (-4 -4, 0 0, 10 0, 10 10)
-- LINESTRING (-4 -4, 0 0, 7.172 0)

-- ******************************************************************************************

PRINT 'Testing [$(lrsowner)].[STLocateBetweenElevations] ...';
GO

-- PostGIS 1
select [$(lrsowner)].[STLocateBetweenElevations](
         geometry::STGeomFromText('LINESTRING(1 2 3, 4 5 6)',0),
         2,4, 
         3,2).AsTextZM() as geomZ;
GO

--geomz
--LINESTRING (1 2 3, 2 3 4)

-- PostGIS 2
select [$(lrsowner)].[STLocateBetweenElevations](
         geometry::STGeomFromText('LINESTRING(1 2 6, 4 5 -1, 7 8 9)',0),
         6,9, 
         3,2).AsTextZM() as geomZ;
GO

--geomz
--GEOMETRYCOLLECTION (POINT (1 2 6), LINESTRING (6.1 7.1 6, 7 8 9))

-- PostGIS 3
SELECT d.geom.AsTextZM() as geomWKT
  FROM (SELECT [$(lrsowner)].[STLocateBetweenElevations](
                 geometry::STGeomFromText('LINESTRING(1 2 6, 4 5 -1, 7 8 9)',0),
                 6,9,
                 3,2
               ) As the_geom
       ) As foo
       cross apply
       [$(owner)].[STExtract](foo.the_geom,default) as d;
GO



