SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STMakeEnvelope] ...';
GO

SELECT [$(owner)].[STMakeEnvelope](0,0,1,1,null) as mbr;
GO

