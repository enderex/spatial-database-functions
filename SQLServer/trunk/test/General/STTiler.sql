SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STTiler] ...';
GO

DROP TABLE IF EXISTS [$(owner)].[GridLL];
exec [$(owner)].[STTiler] 0, 0, 100, 100, 25, 25, 0,0,0, 0, '[$(owner)].GridLL', 0, 1;
SELECT COUNT(*) as tableCount FROM [$(owner)].[GridLL];
SELECT gid, geom.STBuffer(0.2) as geom FROM [$(owner)].[GridLL];
GO

DROP TABLE IF EXISTS [$(owner)].[GridLL];
exec [$(owner)].[STTiler] 0, 0, 100, 100, 25, 25, 0,0,45, 0, '[$(owner)].GridLL',0,0;
SELECT COUNT(*) as tableCount FROM [$(owner)].[GridLL];
SELECT gid, geom FROM [$(owner)].[GridLL];
GO


