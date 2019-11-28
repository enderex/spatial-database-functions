SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[STDirectVincenty] ...';
GO

select [$(cogoowner)].[STDirectVincenty](geography::Point(-42.5,147.23,4326),90.0,100.0).STAsText() as dv;
GO

