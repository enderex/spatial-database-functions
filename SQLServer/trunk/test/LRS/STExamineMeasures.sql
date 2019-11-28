SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing .... ';
PRINT '1. STStartMeasure';
GO

select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0));
GO
select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0));
GO
select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0));
GO

PRINT '2. STEndMeasure';
GO
select [$(lrsowner)].[STEndMeasure](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0));
GO
select [$(lrsowner)].[STEndMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0));
GO
select [$(lrsowner)].[STEndMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0));
GO

PRINT '3. STMeasureRange';
GO
select [$(lrsowner)].[STMeasureRange](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0));
GO
select [$(lrsowner)].[STMeasureRange](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0));
GO
select [$(lrsowner)].[STMeasureRange](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0));
GO

PRINT '4. STPercentageToMeasure';
GO
select [$(lrsowner)].[STPercentageToMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),50);
GO
select [$(lrsowner)].[STPercentageToMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),80);
GO
select [$(lrsowner)].[STPercentageToMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),10);
GO

PRINT '5. STMeasureToPercentage';
GO
select [$(lrsowner)].[STMeasureToPercentage](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),4);
GO
select [$(lrsowner)].[STMeasureToPercentage](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),5);
GO
select [$(lrsowner)].[STMeasureToPercentage](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),6.15);
GO

PRINT '6. STIsMeasureIncreasing';
GO
select [$(lrsowner)].[STIsMeasureIncreasing](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0));
GO
select [$(lrsowner)].[STIsMeasureIncreasing]([$(owner)].[STReverse](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),1,1));
GO
select [$(lrsowner)].[STIsMeasureIncreasing](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0));
GO

PRINT '7. STIsMeasureDecreasing';
GO
select [$(lrsowner)].[STIsMeasureDecreasing](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3,2 2 3 4),(3 3 4 5,4 4 5 6))',0));
GO
select [$(lrsowner)].[STIsMeasureDecreasing](geometry::STGeomFromText('MULTILINESTRING((4 4 5 6,3 3 4 5),(2 2 3 4,1 1 2 3))',0));
GO
select [$(lrsowner)].[STIsMeasureDecreasing](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0));
GO


