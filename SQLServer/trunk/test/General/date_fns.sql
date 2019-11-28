SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[dhms] ...';
GO

SELECT [$(owner)].dhms((2.0 * 24.0 * 60.0 * 60.0) + 923.3) as dhms;
GO

