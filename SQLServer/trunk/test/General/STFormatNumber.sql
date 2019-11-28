SET QUOTED_IDENTIFIER ON 
SET ANSI_NULLS ON 
GO

PRINT 'Testing [$(owner)].[STFormatNumber] ...';
GO

select [$(owner)].[STFORMATNUMBER] (16394506.234,3,null,0,'NULL');
GO

select [$(owner)].[STFORMATNUMBER] (-5283738.5676878,3,null,0,'NULL');
GO

select [$(owner)].[STFORMATNUMBER] (null,3,null,0,'NULL');
GO


