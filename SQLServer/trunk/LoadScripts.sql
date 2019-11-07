USE $(usedbname)
GO
 
/* RUN:
* F:\Projects\spatial-database-functions\SQLServer\trunk>sqlcmd -b -S localhost\GISDB -d TESTDB -v usedbname=TESTDB owner=dbo lrsowner=lrs cogoowner=cogo dbversion=2008 -m-1 -E -i LoadScripts.sql
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
PRINT 'Execution Variables are: dbversion($(dbversion))';
GO

:On Error exit

PRINT 'Load General Functions...';
GO

:r Function_Count.sql 

/*
:r src/general/generate_series.sql  
:r src/general/Tokenizer$(dbversion).sql  
:r src/general/STFormatNumber.sql 
:r src/general/STEquals.sql 
:r src/general/STToGeomGeog.sql 
:r src/general/STIsGeographicSrid.sql 
:r src/general/STMBR.sql 
:r src/general/STMakeEnvelope.sql 
:r src/general/STMakeEnvelopeFromText.sql 
:r src/general/STBoundingDiagonal.sql 

:r src/general/STMorton.sql  
:r src/general/date_fns.sql  
:r src/general/STGeometryTypes.sql 
:r src/general/STMulti.sql 

:r src/general/STDetermine.sql 
:r src/general/STIsCompound.sql 
:r src/general/STIsGeo.sql 
:r src/general/STCoordDim$(dbversion).sql 
:r src/general/STNumDims.sql 
:r src/general/STNumRings.sql 
:r src/general/STStartPoint.sql  
:r src/general/STEndPoint.sql  
:r src/general/STIsPseudoMultiCurve.sql  
:r src/general/STIsCCW.sql  

:r src/general/STPointAsText.sql 
:r src/general/STMakePoint.sql 
:r src/general/STRound.sql  
:r src/general/STConvertToLineString.sql  

:r src/general/DD2DMS.sql 
:r src/general/STBearingAndDistance.sql 
:r src/general/STGeographic.sql 
:r src/general/STCOGOFunctions.sql 
:r src/general/STIsCollinear.sql
:r src/general/STGeographicDistance.sql 
:r src/general/STEllipsoidParameters.sql 
:r src/general/STDirectVincenty.sql 
:r src/general/STInverseVincenty.sql 
:r src/general/STFindAngleBetween.sql 
:r src/general/STAzimuth.sql 

:r src/general/STMakeLines.sql 

:r src/general/STCheckRadii.sql 

:r src/general/STExtract$(dbversion).sql  
:r src/general/STExtractPolygon.sql  
:r src/general/STForceCollection.sql  
:r src/general/STExplode.sql  

:r src/general/STSegmentLine.sql 

:r src/general/STFindLineIntersection.sql 
:r src/general/STVectorize.sql 
:r src/general/STFilterRings.sql 
:r src/general/STVertices.sql  

:r src/general/STLine2Cogo.sql
:r src/general/STAverageBearing.sql  

:r src/general/STAddZ.sql  
:r src/general/STSetZ.sql  
:r src/general/STInsertN$(dbversion).sql  
:r src/general/STUpdate.sql  
:r src/general/STUpdateN.sql  
:r src/general/STDelete.sql  
:r src/general/STDeleteN.sql  
:r src/general/STExtend.sql  
:r src/general/STAddSegmentByCOGO.sql 
:r src/general/STDensify.sql 
:r src/general/STConvertToLineString.sql 

:r src/general/STRemoveSpikes.sql  
:r src/general/STRemoveCollinearPoints.sql  
:r src/general/STRemoveDuplicatePoints.sql  

:r src/general/STSwapOrdinates.sql 
:r src/general/STFlipVectors.sql  
:r src/general/STReverse.sql  
:r src/general/STAppend.sql  
:r src/general/STCentroid.sql  
:r src/general/STRemoveOffsetSegments.sql  
:r src/general/STOffsetLine.sql  
:r src/general/STOffsetSegment.sql  
:r src/general/STOneSidedBuffer.sql  
:r src/general/STSquareBuffer.sql  

:r src/general/STRotate.sql  
:r src/general/STMove.sql  
:r src/general/STScale.sql  
:r src/general/STPostGIS.sql  

:r src/general/STTileXY.sql  
:r src/general/STTileGeom.sql  
:r src/general/STTileGeomByPoint.sql  
:r src/general/STTileGeogByPoint.sql  
:r src/general/STTileByNumGrids.sql  
:r src/general/STTiler.sql  

PRINT 'Load LRS Functions...';
GO

:r src/LRS/STSetMeasure.sql  
:r src/LRS/STAddMeasure.sql 
:r src/LRS/STIsMeasured.sql 
:r src/LRS/STPointToCircularArc.sql 
:r src/LRS/STFindArcPointByLength.sql 
:r src/LRS/STFindArcPointByMeasure.sql 
:r src/LRS/STExamineMeasures.sql  
:r src/LRS/STFilterLineSegmentByLength.sql 
:r src/LRS/STFilterLineSegmentByMeasure.sql 
:r src/LRS/STSplitCircularStringByLength.sql 
:r src/LRS/STSplitCircularStringByMeasure.sql 
:r src/LRS/STSplitLineSegmentByLength.sql 
:r src/LRS/STSplitLineSegmentByMeasure.sql 
:r src/LRS/STFindByPointFunctions.sql 
:r src/LRS/STFindPointByLength.sql 
:r src/LRS/STFindPointByMeasure.sql 
:r src/LRS/STFindSegmentByLengthRange.sql 
:r src/LRS/STFindSegmentByMeasureRange.sql 
-- :r src/LRS/STFindSegmentByZRange.sql 
:r src/LRS/STResetMeasure.sql 
:r src/LRS/STReverseMeasure.sql 
:r src/LRS/STRemoveMeasure.sql 
:r src/LRS/STScaleMeasure.sql 
:r src/LRS/STValidityFunctions.sql  
:r src/LRS/STSplitFunctions.sql 
:r src/LRS/STPostGIS.sql  

:r Function_Count.sql 
*/

PRINT 'Loading of all functions and Procedures complete.';
GO

QUIT

