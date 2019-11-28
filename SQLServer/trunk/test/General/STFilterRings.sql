SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STFilterRings] ...';
go

select geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0) as geom;
GO

select [$(owner)].[STFilterRings](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),2) as geom;
GO

select a.geom.STArea() as area, a.geom
  from (Select geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((30 30,50 30,50 50,30 50,30 30)), ((0 30,20 30,20 50,0 50,0 30)), ((30 0,31 0,31 1,30 1,30 0)))',0) as geom) as a;
GO

select e.geom.STArea() as area, e.geom
  from [$(owner)].[STExtract](
          [$(owner)].[STFilterRings](
             geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((30 30,50 30,50 50,30 50,30 30)), ((0 30,20 30,20 50,0 50,0 30)), ((30 0,31 0,31 1,30 1,30 0)))',0),2.5),1) as e;
GO


