SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing STAverageBearing....';
go

Print '1. Testing Ordinary 2 Point Linestring ...';
GO

select [$(owner)].[STAvergeBearing] (geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ([$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0),DEFAULT,DEFAULT)) as avgBearing;
GO

Print '2. Testing 4 Point Linestring All Points Collinear - Special Case...';
GO

select [$(owner)].[STAvergeBearing] (geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0)  ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ([$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0),DEFAULT,DEFAULT)) as avgBearing;
go

PRINT '3. Testing More complex Linestring...';
GO 

select [$(owner)].[STAvergeBearing] ( geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0) ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ( [$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0),DEFAULT,DEFAULT)) as avgBearing;
GO

PRINT '4. Testing Nearly Closed Loop Linestring';
GO

select [$(owner)].[STAvergeBearing] ( geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 -1)',0) ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ( [$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 -1)',0),DEFAULT,DEFAULT) ) as avgBearing;
go


