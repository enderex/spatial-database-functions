SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[STInverseVincenty] ...';
GO

SELECT [$(cogoowner)].[STInverseVincenty] ( geography::Point(12.1603670,55.4748508,4326), geography::Point(12.1713976,55.4786191,4326)) as meters;
GO


