SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing STFindCircle...';
GO

select [$(cogoowner)].[STFindCircle](0,5, 5,0, 10,5, default).AsTextZM(),
       [$(cogoowner)].[STFindCircle](0,5, 5,0, 10,5, default).STSrid;
GO

With data as (
  select 'CircularArc (clockwise)'    as test,  geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as linestring
  union all
  select 'CircularArc (antilockwise)' as test,  geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as linestring
)
Select [$(cogoowner)].[STFindCircle](
                     a.linestring.STPointN(1).STX,a.linestring.STPointN(1).STY,
                     a.linestring.STPointN(2).STX,a.linestring.STPointN(2).STY,
                     a.linestring.STPointN(3).STX,a.linestring.STPointN(3).STY,
                     a.linestring.STSrid
       ).AsTextZM() as circlePoint
  from data as a;
GO

PRINT 'Testing STFindCircleByPoint...';
GO

SELECT [$(cogoowner)].[STFindCircleByPoint] (
          geometry::Point(  0,10,0),
		  geometry::Point( 10, 0,0),
		  geometry::Point(-10, 0,0)).AsTextZM();
go

PRINT 'Testing STFindCircleFromArc...';
GO

select [$(cogoowner)].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0)).AsTextZM();
GO

With data as (
  select 'CircularArc (clockwise)'    as test,  geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as linestring
  union all
  select 'CircularArc (antilockwise)' as test,  geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as linestring
)
Select a.test, [$(cogoowner)].[STFindCircleFromArc](a.linestring).AsTextZM() as cPoint
  from data as a;
GO

-- *****************************************************************************

PRINT 'Testing STCreateCircle...';
GO

select [$(cogoowner)].[STCreateCircle](5,5,5,0,1);
GO

PRINT 'Testing STOptimalCircleSegments...';
GO

select [$(cogoowner)].[STOptimalCircleSegments](10,0.01);
GO

PRINT 'Testing STCircle2Polygon...';
GO

select [$(cogoowner)].[STCircle2Polygon](100,100,5.0,6,0,3);
GO

select [$(cogoowner)].[STCircle2Polygon](100,100,5.0,null,0,3);
GO

select [$(cogoowner)].[STCircle2Polygon](100,100,5.0,144,0,3);
GO

select [$(cogoowner)].[STCircle2Polygon](100,100,
                          a.intValue/6 + 5.0,
                          a.intValue,
                          0,3)
  from [$(owner)].[Generate_Series](144,0,-12) a;
GO

select b.Radius,
       [$(cogoowner)].[STCircle2Polygon](100 + b.Radius,
                          100 + b.Radius,
                          b.Radius,
                          b.segments,
                          0,3)
  from (select (a.intValue/6 + 5.0) as Radius,
                a.intValue as segments 
          from [$(owner)].[Generate_Series](144,0,-12) a 
        ) b;
GO

-- -ve angle is clockwise; +ve anticlockwise
With data as (
  select '45 CircularArc (clockwise)'     as test, geometry::STGeomFromText('CIRCULARSTRING(10 0, 10.6334767995324 2.43587256230255, 12.3733900559114 4.25451762267059)',0) as linestring
  union all
  select '90 CircularArc (clockwise)'     as test, geometry::STGeomFromText('CIRCULARSTRING(10 0, 12.3733900559114 4.25451762267059, 15 5)',0) as linestring
  union all
  select '180 CircularArc (clockwise)'    as test, geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as linestring
  union all
  select '180 CircularArc (antilockwise)' as test, geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as linestring
  union all
  select '270 CircularArc (clockwise)'    as test, geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0) as linestring
)
select c.test, c.linestring,
       round([$(cogoowner)].[STRadians2Degrees](
         [$(cogoowner)].[STSubtendedAngle] (
                c.linestring.STStartPoint().STX,c.linestring.STStartPoint().STY,
                c.circle.STX,
                c.circle.STY,       
                c.linestring.STEndPoint().STX,c.linestring.STEndPoint().STY
         )
       ),5) as angle,
       round(c.circle.STX,3) as cx,
       round(c.circle.STY,3) as cy,
       round(c.circle.Z,  3) as radius 
  from (select a.test, 
               a.linestring,
               [$(cogoowner)].[STFindCircle](
                     a.linestring.STPointN(1).STX,a.linestring.STPointN(1).STY,
                     a.linestring.STPointN(2).STX,a.linestring.STPointN(2).STY,
                     a.linestring.STPointN(3).STX,a.linestring.STPointN(3).STY, 0) as circle
          from data as a
       ) as c;
GO

select geometry::Point(10,0,0).STBuffer(0.2) as geom,
       [$(cogoowner)].[STSubtendedAngle](10,10,10,0,10.870,9.8) as subtendedAngle
union all
select geometry::Point(10, 0,0).ShortestLineTo(geometry::Point(10,10,0)).STBuffer(0.1) as reverse, null
union all
select geometry::Point(10, 0,0).ShortestLineTo(geometry::Point(11,9.5,0)).STBuffer(0.1) as forward, null;

select round([$(cogoowner)].[STSubtendedAngle](10,10,10,0,f.ePoint.STX,f.ePoint.STY),2) as subtendedAngle,
       f.ePoint.STBuffer(0.5) as point
  from (select [$(cogoowner)].[STPointFroMBearingAndDistance](10,0,g.IntValue,10,3,0) as ePoint
          from [$(owner)].Generate_Series(10,360,10) as g
        ) as f;
GO

PRINT 'Testing STFindPointBisector...';
GO

With data as (
  select geometry::STGeomFromText('LINESTRING( 0  0, 10 10)',0) as line,
         geometry::STGeomFromText('LINESTRING(10 10, 20 0)',0) as next_line
)
select [$(cogoowner)].[STFindPointBisector] ( a.line, a.next_line, g.Intvalue,3,2,1 ).STBuffer(2)
  from data as a
       cross apply
       [$(owner)].[Generate_Series](-5,5,5) as g
union all
select line from data as a
union all
select next_line from data as a;
go

PRINT 'Testing STComputeTangentPoint...';
GO

With data as (
  select geometry::STGeomFromText('CIRCULARSTRING(40 0, 35 5, 30 0)',0) as linestring
  union all
  select geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as linestring
  union all
  select geometry::STGeomFromText('CIRCULARSTRING(25 30, 30 12, 25 10)',0) as linestring
)
select [$(cogoowner)].[STComputeTangentPoint] (a.linestring,'START',3).STBuffer(1) as tPoint from data as a
union all
select [$(cogoowner)].[STComputeTangentPoint] (a.linestring,'END',3).STBuffer(1) as tPoint from data as a
union all
select a.linestring.STBuffer(1) from data as a;
GO

PRINT 'Testing STComputeLengthToMidPoint...';
GO

-- Arc Mid Point Calcs
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as cString
  union all
  select geometry::STGeomFromText('CIRCULARSTRING(25 30, 30 12, 25 10)',0) as cString
  union all
  select geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as cString
  union all
  select geometry::STGeomFromText('CIRCULARSTRING(30 0, 35 5, 35 -5)',0) as cString
  union all
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as cString
  union all
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.325 NULL 0, 0 7 NULL 3.08, 3 6.325 NULL 6.15)',0) as cString
  union all
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.325 NULL 0, 0 7 NULL 3.08, 3 9.325 NULL 6.15)',0) as cString
)
Select cString, 
       round(midArc,2)        as midArcLength, 
       round(allArc,2)        as allArcLength, 
       round(midArc/allArc,5) as MidAllRatio
  from (select d.cString, 
               [$(cogoowner)].[STComputeLengthToMidPoint](d.[cString]) as midArc, 
               d.[cString].STLength() as allArc
          from data as d
        ) as f;
GO

PRINT 'Testing STSubtendedAngle...';
GO

select 'From/To/Right',
       sAngle,
       [$(cogoowner)].[STDegrees](sAngle) as degrees 
  from (
select [$(cogoowner)].[STSubtendedAngle] (0,-1,0,0,1,-1) as sAngle -- 45
union all
select [$(cogoowner)].[STSubtendedAngle] (0,-1,0,0,1,0) -- 90 
union all
select [$(cogoowner)].[STSubtendedAngle] (0,-1,0,0,1,1) -- 135
union all
select [$(cogoowner)].[STSubtendedAngle] (0,-1,0,0,0,1) -- 180
union all
select [$(cogoowner)].[STSubtendedAngle] (0,-1,0,0,-1,1) -- 235
union all
select [$(cogoowner)].[STSubtendedAngle] (0,-1,0,0,-1,0) -- 270
union all
select [$(cogoowner)].[STSubtendedAngle] (0,-1,0,0,-1,-1) -- 315
) as a
union all
select 'To/From/Left',
       sAngle,
       [$(cogoowner)].[STDegrees](sAngle) as degrees 
  from (
select [$(cogoowner)].[STSubtendedAngle] (1,-1,0,0,0,-1) as sAngle -- 45
union all
select [$(cogoowner)].[STSubtendedAngle] (1,0,0,0,0,-1) -- 90 
union all
select [$(cogoowner)].[STSubtendedAngle] (1,1,0,0,0,-1) -- 135
union all
select [$(cogoowner)].[STSubtendedAngle] (0,1,0,0,0,-1) -- 180
union all
select [$(cogoowner)].[STSubtendedAngle] (-1,1,0,0,0,-1) -- 235
union all
select [$(cogoowner)].[STSubtendedAngle] (-1,0,0,0,0,-1) -- 270
union all
select [$(cogoowner)].[STSubtendedAngle] (-1,-1,0,0,0,-1) -- 315
) as b;
GO

