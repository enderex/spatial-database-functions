SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Testing [$(owner)].[STIsGeographicSrid] ...';
GO

SELECT 4283 as srid,case when [$(owner)].[STIsGeographicSrid](4283)=1 then 'Geographic' else 'Geometry' end as isGeographic;
GO


