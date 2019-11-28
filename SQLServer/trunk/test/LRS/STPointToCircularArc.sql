SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STPointToCircularArc] ...'
GO

-- Falls on circular arc with M no Z
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),
          geometry::Point(2,8,0),
          3,2).AsTextZM() as project_point;
go

-- Falls on circular arc with Z
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 -2.1 0, 0 7 -2.1 3.08, -3 6.325 -2.1 6.15)',0),
          geometry::Point(2,8,0),
          3,2).AsTextZM() as project_point;
go

-- Does not fall on circular arc
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),
          geometry::Point(8,8,0),
          3,2).AsTextZM() as project_point;
go

-- 2D Circular Arc - Supplied point is also the centre of the circular arc
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
          geometry::Point(0,0,0),
          3,2).AsTextZM() as project_point;
go

-- 2D Circular Arc - Supplied point half way between centre of the circular arc and the circular arc
select geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0).STLength() as len,
       [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
          geometry::Point(0,3.5,0),
          3,2).AsTextZM() as project_point;
go

-- Unsuported geometries 
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
          geometry::Point(8,8,0),
          3,2).AsTextZM() as project_point;
go


