with data as (
  select geometry::STGeomFromText('LINESTRING(147.5 -43.132 100, 147.41 -43.387 30000)',4326) as line
)
select 0 as ratio, -99 as offset, line from data as a union all
select ratio.IntValue/100.0 as ratio, 
       gs.IntValue as offset, 
       [$(owner)].[STOffsetPoint](
          a.line,
          ratio.IntValue/10.0,
          gs.IntValue/50.0,
          8,8,8
       )
       .STBuffer(0.01) as result
 from data as a
      cross apply
	  dbo.Generate_Series(0,10,1) as ratio
      cross apply
	  dbo.Generate_Series (-5,5,5) as gs;

with data as (
  select geometry::STGeomFromText('LINESTRING(147.5 -43.132,147.41 -43.387)',4326) as line
)
select 0 as ratio, -99 as offset, line from data as a union all
select ratio.IntValue/100.0 as ratio, 
       gs.IntValue as offset, 
       [$(owner)].[STOffsetPoint](
          a.line,
          ratio.IntValue/10.0,
          gs.IntValue/50.0,
          8,8,8
       )
       .STBuffer(0.01) as result
 from data as a
      cross apply
	  dbo.Generate_Series(0,10,1) as ratio
      cross apply
	  dbo.Generate_Series (-5,5,5) as gs;

--*******************
--Circular Arcs...
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373,252230.478 5527000.0)',28355) as cLine
)
select 0 as ratio, -99 as offset, cline from data as a union all
select ratio.IntValue/10.0 as ratio, gs.IntValue as offset, [$(owner)].[STOffsetPoint](a.cline,ratio.IntValue/10.0,gs.IntValue,3,3,3).STBuffer(2.0) as result
 from data as a
      cross apply
	  dbo.Generate_Series(0,10,1) as ratio
      cross apply
	  dbo.Generate_Series (-5,5,5) as gs;

-- 3D/Z Test      
select [$(owner)].[STOffsetPoint](geometry::STGeomFromText('CIRCULARSTRING(252230.478 5526918.373 1.0, 252400.08 5526918.373 1.0, 252230.478 5527000.0 1.0)',28355),0.25,5,3,3,3).AsTextZM();
--SRID=28355;POINT (252337.322 5526862.557 1)

-- *************************************************************
-- Arc Bottom To Top centre on right
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173742.05001496 259159.972709981 NULL 0,
2173712.74541767 259214.837554961 NULL 3186.7865,
2173742.0037621  259304.411434516 NULL 3498.52)',2274) as linestring
)
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-100.0,3,2,3).STBuffer(2.0) from data as a union all
select 100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 100.0,3,2,3).STBuffer(2.0) from data as a
go

-- Arc Top To Bottom centre on right
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173742.0037621  259304.411434516 NULL 3498.52,
2173712.74541767 259214.837554961 NULL 3186.7865,
2173742.05001496 259159.972709981 NULL 0)',2274) as linestring
)
select 0 as offset, geometry::STGeomFromText('POINT(2173742.0037621  259304.411434516 NULL 3498.52)',2274).STBuffer(5) as geom union all
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-100.0,3,2,3).STBuffer(10.0) from data as a union all
select 100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 100.0,3,2,3).STBuffer(10.0) from data as a
go

-- Arc Bottom To Top centre on left
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173742.05001496 259159.972709981 NULL 0,
2173762.74541767 259214.837554961 NULL 3186.7865,
2173742.0037621  259304.411434516 NULL 3498.52)',2274) as linestring
)
select 0 as offset, geometry::STGeomFromText('POINT(2173742.05001496 259159.972709981 NULL 0)',2274).STBuffer(5) as geom union all
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-100.0,3,2,3).STBuffer(10.0) from data as a union all
select 100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 100.0,3,2,3).STBuffer(10.0) from data as a
go

-- Arc Top To Bottom centre on left
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173742.0037621  259304.411434516 NULL 3498.52,
2173762.74541767 259214.837554961 NULL 3186.7865,
2173742.05001496 259159.972709981 NULL 0)',2274) as linestring
)
select 0 as offset, geometry::STGeomFromText('POINT(2173742.0037621  259304.411434516 NULL 3498.52)',2274).STBuffer(5) as geom union all
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-100.0,3,2,3).STBuffer(10.0) from data as a union all
select 100.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 100.0,3,2,3).STBuffer(10.0) from data as a
go

-- Sydney harbor left to right
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173722.05 259159.97 NULL 0,
2173732.05 259184.84 NULL 3186.7865,
2173762.05 259159.97 NULL 3498.52)',2274) as linestring
)
select 0 as offset, geometry::STGeomFromText('POINT(2173722.05 259159.97 NULL 0)',2274).STBuffer(5) as geom union all
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-10.0,3,2,3).STBuffer(5.0) from data as a union all
select  10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 10.0,3,2,3).STBuffer(5.0) from data as a
go

-- Sydney harbor right to left
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173762.05 259159.97 NULL 3498.52,
2173732.05 259184.84 NULL 3186.7865,
2173722.05 259159.97 NULL 0)',2274) as linestring
)
select 0 as offset, geometry::STGeomFromText('POINT(2173762.05 259159.97 NULL 3498.52)',2274).STBuffer(5) as geom union all
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-10.0,3,2,3).STBuffer(5.0) from data as a union all
select  10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 10.0,3,2,3).STBuffer(5.0) from data as a
go

-- Bowel Left to right
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173722.05 259159.97 NULL 0,
2173732.05 259134.84 NULL 3186.7865,
2173762.05 259159.97 NULL 3498.52)',2274) as linestring
)
select 0 as offset, geometry::STGeomFromText('POINT(2173722.05 259159.97 NULL 0)',2274).STBuffer(5) as geom union all
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-10.0,3,2,3).STBuffer(5.0) from data as a union all
select  10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 10.0,3,2,3).STBuffer(5.0) from data as a
go

-- Sydney harbor right to left
with data as (
select geometry::STGeomFromText('CIRCULARSTRING (
2173762.05 259159.97 NULL 3498.52,
2173732.05 259134.84 NULL 3186.7865,
2173722.05 259159.97 NULL 0)',2274) as linestring
)
select 0 as offset, geometry::STGeomFromText('POINT(2173762.05 259159.97 NULL 3498.52)',2274).STBuffer(5) as geom union all
select 0 as offset, a.linestring.STBuffer(4.0) as geom from data as a union all
select -10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5,-10.0,3,2,3).STBuffer(5.0) from data as a union all
select  10.0,[$(owner)].[STOffsetPoint]( a.linestring,0.5, 10.0,3,2,3).STBuffer(5.0) from data as a
go
