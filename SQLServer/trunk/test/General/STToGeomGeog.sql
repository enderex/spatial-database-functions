SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STToGeometry] and [$(owner)].[STToGeography] ...';
GO

SELECT [$(owner)].[STToGeography](
           [$(owner)].[STToGeometry](
               geography::STGeomFromText('LINESTRING(147.234 -43.2345, 148.234 -43.2345)',4326),
               0),
           4326).STAsText() 
       as geog;
GO


