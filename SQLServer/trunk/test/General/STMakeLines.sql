SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STMakeLineXY]...';
GO

SELECT [$(owner)].[STMakeLineXY](null,null,null,null,null,null) as line;
GO

SELECT [$(owner)].[STMakeLineXY](0,0,10,10,0,3).STAsText() as line;
GO

Print 'Testing [$(owner)].[STMakeLine]...';
GO

SELECT [$(owner)].[STMakeLine](null,null,null,null) as line;
GO

SELECT [$(owner)].[STMakeLine](geometry::Point(0,0,0),null,null,null) as line;
GO

SELECT [$(owner)].[STMakeLine](null,geometry::Point(10,10,0),null,null) as line;
GO

SELECT [$(owner)].[STMakeLine](geometry::Point(0,0,0),geometry::Point(10,10,28355),3,2) as line;
GO

SELECT [$(owner)].[STMakeLine](geometry::Point(0,0,0),geometry::Point(10,10,0),3,2).STAsText() as line;
GO

Print 'Testing [$(owner)].[STMakeLineFromMultiPoint] ...';
GO

select [$(owner)].[STMakeLineFromMultiPoint](geometry::STGeomFromText('MULTIPOINT((0 0),(1 1),(2 2),(3 3))',0)).AsTextZM();
GO

Print 'Testing [$(owner)].[STMakeCircularLine]...';
Print 'Parameter Test.';
GO

select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), null,geometry::Point(10,0,0),10,3,3);

Print 'SRID Test.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,0,0),geometry::Point(10,0,100),10,3,3);

Print 'Collinear Test 1.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,0,0),geometry::Point(10,0,0),10,3,3);

Print 'Collinear Test 2.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,5,0),geometry::Point(10,10,0),10,3,3);

Print 'Duplicate Point Test.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(0,0,0),geometry::Point(10,10,0),10,3,3);

Print 'Real Circular Arc Test.'
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,5,0),geometry::Point(10,0,0),10,3,3);
GO

