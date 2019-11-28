SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STSquareBuffer] ...';
GO

-- Simple 2 Point Linestring
with data as (
select geometry::STGeomFromText('LINESTRING(0 0,10 10)',0) as linestring
)
select a.linestring from data as a 
union all
select [$(owner)].[STSquareBuffer](a.linestring,-5.0,3,2) as sqBuff from data as a;
GO

-- Simple Linestring
with data as (
select geometry::STGeomFromText('LINESTRING(0 0,5 0,5 10)',0) as linestring
)
select a.linestring from data as a 
union all
select [$(owner)].[STSquareBuffer](a.linestring,-5.0,3,2) as sqBuff from data as a;
GO

-- Simple 2 Point Linestring with z and measure (both lost)
with data as (
select geometry::STGeomFromText('LINESTRING(0 0 1 2, 10 0 1.5 3)',0) as linestring
)
select [$(owner)].[STSquareBuffer](a.linestring,-15.0,3,2).AsTextZM() as sqBuff from data as a;
GO

-- Closed Linestring
with data as (
select geometry::STGeomFromText('LINESTRING(0 0, 5 5, 0 5, -5 5,0 0)',0) as linestring
)
select a.linestring from data as a 
union all
select [$(owner)].[STSquareBuffer](a.linestring,-15.0,3,2) as sqBuff from data as a;
GO

WITH data AS (
  select 'Ordinary 2 Point Linestring' as test, 
         geometry::STGeomFromText('LINESTRING(0 0 0 1, 10 0 0 2)',0) as linestring
  union all
  select 'CircularArc (anticlockwise)' as test, 
         geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as linestring
  union all
  select 'Ordinary 2 Point Linestring (after circularArc)' as test,
         geometry::STGeomFromText('LINESTRING(20 0 0 15.6, 20 -4 34.5)',0) as linestring
  union all
  select 'Proper CircularArc (clockwise)' as test,
         geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as linestring
)
select d.test, 0.0 as bufferDistance, d.linestring.STBuffer(0.1) as sqBuff 
  from data as d
union all
select d.test, 
       g.intValue as bufferDistance, 
       [$(owner)].[STSquareBuffer](d.linestring,CAST(g.intValue as float),3,2) as sqBuff
  from data as d
       cross apply
       [$(owner)].[generate_series](5,5,0) as g
 where g.intValue <> 0;
GO

select geometry::STGeomFromText('LINESTRING(0 0, 10 0, 10 10, 0 10,0 0)',0) as geom
union all
select geometry::STGeomFromText('LINESTRING(0 0, 10 0, 10 10, 0 10,0 0)',0) as geom
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),-1.0,1,3,2)
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),1.0,1,3,2);
GO


