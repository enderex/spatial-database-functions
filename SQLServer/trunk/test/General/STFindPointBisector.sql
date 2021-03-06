use devdb
go

with data as (
select geometry::STGeomFromText('LINESTRING(3 6.3246,10 10)',0) as firstline, 
       geometry::STGeomFromText('LINESTRING(10 10, 13 16.3246)',0) as secondline
)
select firstline from data as a union all
select secondline from data as a union all
select [cogo].[STFindPointBisector] (firstline,secondline,offset.IntValue,3,2,1).STBuffer(0.5) 
  from data as a
       cross apply
	   [dbo].[generate_series](-5,5,5) as offset;

-- Linestring and circularstring
with data as (
  select geometry::STGeomFromText('LINESTRING(10 10, 3 6.3246)',0) as firstLine,
         geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0) as secondLine
)
select a.firstline from data as a union all
select a.secondline from data as a union all
select [cogo].[STFindPointBisector] (a.firstline,a.secondline,offset.IntValue,3,2,1).STBuffer(0.5)
  from data as a
       cross apply
	   [dbo].[generate_series](-5,5,5) as offset;

-- Linestring with linestring in compoundCurve
with data as (
  select geometry::STGeomFromText('LINESTRING(10 10, 3 6.3246)',0) as firstLine,
         geometry::STGeomFromText('COMPOUNDCURVE((3 6.3246 NULL 0, -10 10 null 14.414),CIRCULARSTRING (-10 10 NULL 14.414, -20 20 NULL 21.34, -30 10 NULL 43.34))',0) as secondLine
)
select a.firstline from data as a union all
select a.secondline from data as a union all
select [cogo].[STFindPointBisector] (a.firstline,a.secondline,offset.IntValue,3,2,1).STBuffer(0.5)
  from data as a
       cross apply
	   [dbo].[generate_series](-5,5,5) as offset;


with data as (
select geometry::STGeomFromText('CIRCULARSTRING(3 6.3246 NULL 0.0,0 5 NULL 10.1,-3 6.3246 NULL 25.38)',0) as firstline,
       geometry::STGeomFromText('CIRCULARSTRING(-3 6.3246 NULL 25.38,-4.5 8.0 NULL 27.5, -3 9.3246 null 32.1)',0) as secondline
)
select a.firstline from data as a union all
select a.secondline from data as a union all
select [cogo].[STFindPointBisector] (a.firstline,a.secondline,offset.IntValue,3,2,1).STBuffer(0.2) as dfb 
  from data as a
       cross apply
	   [dbo].[generate_series](-5,5,5) as offset;


