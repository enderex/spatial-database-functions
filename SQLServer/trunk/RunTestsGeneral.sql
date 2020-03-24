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

PRINT 'Testing General Functions...';
GO

:r test/general/generate_series.sql 
:r test/general/Tokenizer.sql  
:r test/general/STFormatNumber.sql 
:r test/general/STEquals.sql 
:r test/general/STToGeomGeog.sql 
:r test/general/STIsGeographicSrid.sql 
:r test/general/STMBR.sql 
:r test/general/STMakeEnvelope.sql 
:r test/general/STMakeEnvelopeFromText.sql 
:r test/general/STGeomFromText.sql
:r test/general/STAsText.sql

:r test/general/STMorton.sql  
:r test/general/date_fns.sql  
:r test/general/STGeometryTypes.sql 
:r test/general/STMulti.sql 

:r test/general/STDetermine.sql 
:r test/general/STIsCompound.sql 
:r test/general/STIsGeo.sql 
:r test/general/STCoordDim.sql 
:r test/general/STTo2D.sql 
:r test/general/STNumDims.sql 
:r test/general/STNumRings.sql 
:r test/general/STStartPoint.sql  
:r test/general/STEndPoint.sql  
:r test/general/STIsPseudoMultiCurve.sql  

:r test/general/STPointAsText.sql 
:r test/general/STMakePoint.sql 
:r test/general/STRound.sql  

:r test/general/DD2DMS.sql 
:r test/general/STBearingAndDistance.sql 
:r test/general/STGeographic.sql 
:r test/general/STCOGOFunctions.sql 
:r test/general/STGeographicDistance.sql 
:r test/general/STEllipsoidParameters.sql 
:r test/general/STDirectVincenty.sql 
:r test/general/STInverseVincenty.sql 
:r test/general/STAzimuth.sql 
:r test/general/STFindDeflectionAngle.sql
:r test/general/STFindAngleBetween.sql 

:r test/general/STExtract.sql  
:r test/general/STExtractPolygon.sql  
:r test/general/STExplode.sql  
:r test/general/STForceCollection.sql  
:r test/general/STMakeLines.sql 
:r test/general/STLineMerge.sql
:r test/general/STBoundingDiagonal.sql 
:r test/general/STCheckRadii.sql 
:r test/general/STSnapPointToLine.sql

:r test/general/STNumCircularStrings.sql
:r test/general/STCircularStringN.sql

-- :r src/general/STSegment.sql 
:r test/general/STSegmentLine.sql 
:r test/general/STIsCollinear.sql
:r test/general/STReverse.sql  
:r test/general/STAppend.sql  
:r test/general/STMakeLineFromCollection.sql

:r test/general/STFindLineIntersection.sql 
:r test/general/STVectorize.sql 
:r test/general/STSegmentize.sql 
:r test/general/STFilterRings.sql 
:r test/general/STVertices.sql  

:r test/general/STLine2Cogo.sql
:r test/general/STAverageBearing.sql  

:r test/general/STAddZ.sql  
:r test/general/STSetZ.sql  
:r test/general/STInsertN.sql  
:r test/general/STUpdate.sql  
:r test/general/STUpdateN.sql  
:r test/general/STDelete.sql  
:r test/general/STDeleteN.sql  
:r test/general/STExtend.sql  
:r test/general/STAddSegmentByCOGO.sql 
:r test/general/STDensify.sql 
:r test/general/STConvertToLineString.sql 

:r test/general/STRemoveSpikes.sql  
:r test/general/STRemoveCollinearPoints.sql  
:r test/general/STRemoveDuplicatePoints.sql  

:r test/general/STSwapOrdinates.sql 
:r test/general/STFlipVectors.sql  
:r test/general/STIsCCW.sql  
:r test/general/STWhichSide.sql

:r test/general/STPostGIS.sql

:r test/general/STCentroid.sql  
:r test/general/STRemoveOffsetSegments.sql  
:r test/general/STOffsetSegment.sql  
:r test/general/STOneSidedBuffer.sql  
:r test/general/STOffsetLine.sql  
:r test/general/STSquareBuffer.sql  

:r test/general/STRotate.sql  
:r test/general/STMove.sql  
:r test/general/STScale.sql  

:r test/general/STNumTiles.sql  
:r test/general/STTileXY.sql  
:r test/general/STTileGeom.sql  
:r test/general/STTileGeomByPoint.sql  
:r test/general/STTileGeogByPoint.sql  
:r test/general/STTileByNumGrids.sql  
:r test/general/STTiler.sql  

PRINT 'Testing of General Functions and Procedures Complete.';
GO
 
QUIT

