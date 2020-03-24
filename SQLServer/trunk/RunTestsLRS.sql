USE $(usedbname)
GO
 
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

-- Only for sqlcmd mode
:On Error Ignore

PRINT 'Run LRS Function Tests...';
GO

:r test/LRS/STSetMeasure.sql  
:r test/LRS/STAddMeasure.sql 
:r test/LRS/STIsMeasured.sql 
:r test/LRS/STPointToCircularArc.sql 
:r test/LRS/STFindArcPointByLength.sql 
:r test/LRS/STFindArcPointByMeasure.sql 
:r test/LRS/STExamineMeasures.sql  
:r test/LRS/STFilterLineSegmentByLength.sql 
:r test/LRS/STFilterLineSegmentByMeasure.sql 
:r test/LRS/STSplitCircularStringByLength.sql 
:r test/LRS/STSplitCircularStringByMeasure.sql 
:r test/LRS/STSplitLineSegmentByLength.sql 
:r test/LRS/STSplitLineSegmentByMeasure.sql 
:r test/LRS/STFindByPointFunctions.sql 
:r test/LRS/STFindPointByLength.sql 
:r test/LRS/STFindPointByMeasure.sql 
:r test/LRS/STFindPointsByMeasures.sql 
:r test/LRS/STFindSegmentByLengthRange.sql 
:r test/LRS/STFindSegmentByMeasureRange.sql 
-- :r src/LRS/STFindSegmentByZRange.sql 
:r test/LRS/STResetMeasure.sql 
:r test/LRS/STReverseMeasure.sql 
:r test/LRS/STRemoveMeasure.sql 
:r test/LRS/STScaleMeasure.sql 
:r test/LRS/STValidityFunctions.sql  
:r test/LRS/STSplitFunctions.sql 
:r test/LRS/STPostGIS.sql  

PRINT 'Testing of all LRS Functions and Procedures complete.';
GO

QUIT

