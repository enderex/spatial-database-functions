SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STMakeEnvelopeFromText] ...';
GO

SELECT [$(owner)].[STMakeEnvelopeFromText]('0 0 1 1',DEFAULT,0) as mbr;
GO

SELECT [$(owner)].[STMakeEnvelopeFromText]('0,0,1,1',',',0).STAsText() as mbr;
GO

SELECT [$(owner)].[STMakeEnvelopeFromText]('0@0@1@1','@',0) as mbr;
GO

