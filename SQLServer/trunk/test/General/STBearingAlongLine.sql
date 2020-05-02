SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing STBearingAlongLine...';
GO


SELECT [$(cogoowner)].[STBearingAlongLine] (
           geometry::STGeomFromText('LINESTRING(0 0,45 45)',0) 
       ) as Bearing;
GO

