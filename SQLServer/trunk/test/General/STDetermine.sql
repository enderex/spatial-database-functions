SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STDetermine] ...';
GO

Select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0),
         geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0)
       ) as relations;
go

Select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('LINESTRING (100.0 0.0, 400.0 0.0)',0),
         geometry::STGeomFromText('LINESTRING (90.0 0.0, 100.0 0.0)',0)
       ) as relations;
GO

select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) ,
         geometry::STPointFromText('POINT (250 150)',0)
     ) as relations;
GO

select [$(owner)].[STDetermine] ( 
       geometry::STPointFromText('POINT (250 150)',0),
       geometry::STPointFromText('POINT (250 150)',0)
     ) as relations;
GO

