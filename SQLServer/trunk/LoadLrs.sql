USE $(usedbname)
GO
 
/* RUN:
* F:\Projects\spatial-database-functions\SQLServer\trunk>sqlcmd -b -S localhost\GISDB -d TESTDB -v usedbname=TESTDB owner=dbo lrsowner=lrs cogoowner=cogo -m-1 -E -i LoadScripts.sql
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

-- Only for sqlcmd mode
:On Error Ignore

PRINT 'Load LRS Functions...';
GO

:r src/LRS/STSetMeasure.sql  
:r src/LRS/STAddMeasure.sql 
:r src/LRS/STIsMeasured.sql 
:r src/LRS/STPointToCircularArc.sql 
:r src/LRS/STExamineMeasures.sql  
:r src/LRS/STSplitSegmentByLength.sql 
:r src/LRS/STSplitSegmentByMeasure.sql 
:r src/LRS/STFindByPointFunctions.sql 
:r src/LRS/STFindPointByLength.sql 
:r src/LRS/STFindPointByMeasure.sql 
:r src/LRS/STFindSegmentByLengthRange.sql 
:r src/LRS/STFindSegmentByMeasureRange.sql 
:r src/LRS/STResetMeasure.sql 
:r src/LRS/STReverseMeasure.sql 
:r src/LRS/STRemoveMeasure.sql 
:r src/LRS/STScaleMeasure.sql 
:r src/LRS/STValidityFunctions.sql  
:r src/LRS/STSplitFunctions.sql 
:r src/LRS/STPostGIS.sql  
:r src/LRS/STFindPointsByMeasures.sql
-- :r src/LRS/STFindSegmentByZRange.sql 

:r Function_Count.sql 

PRINT 'Loading of all functions and Procedures complete.';
GO

QUIT

