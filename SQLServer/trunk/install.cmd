@ECHO OFF

ECHO =================================
ECHO Installation Script
ECHO =================================

IF EXIST "%CD%\log"   GOTO LOG
mkdir "%CD%\log"
IF %errorlevel% EQU 0 GOTO LOG
ECHO Could not delete/create log directory.
GOTO EXIT

:LOG
DEL "%CD%\log\*.log"

SET server_instance=localhost\SQLEXPRESS
SET /P Express=Are we connecting to an Express database? (%server_instance%: Default is N):
IF %Express%_ EQU Y_ GOTO IDBNAME

SET server_instance=%ComputerName%\EnterSQLInstanceName
:SINSTANCE
SET /P server_instance=Enter server\instance (%server_instance%):
IF %server_instance%_ NEQ _ GOTO IDBNAME
ECHO Server Instance must be entered.
GOTO SINSTANCE

:IDBNAME
SET dbname=TESTDB
SET /P dbname=Enter install DB name (%dbname%):
IF %dbname%_ NEQ _ GOTO IOWNER
ECHO Installation database name must be entered.
GOTO IDBNAME

:IOWNER
ECHO Possible existing DB schemas in %dbname% for storing functions....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% -E -h-1 -Q "SET NOCOUNT ON; SELECT name FROM sys.schemas WHERE principal_id = 1 ORDER BY 1;"

SET owner=dbo
SET /P owner=Enter Main Schema owner (%owner%):
IF %owner%_ NEQ _ GOTO COGOOWNER
ECHO Main Schema owner name must be entered.
GOTO IOWNER

:COGOOWNER
SET cogoowner=%owner%
SET /P cogoowner=Enter COGO owner (Default: %owner%):
IF %cogoowner%_ NEQ _ GOTO LRSOWNER
SET cogoowner=%owner%

:LRSOWNER
SET lrsowner=%owner%
SET /P lrsowner=Enter LRS Owner (Default: %owner%):
IF %lrsowner%_ NEQ _ GOTO GETVERSION
SET lrsowner=%owner% 

:GETVERSION
ECHO Extracting SQL Server Database Version ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% -E -h-1 -Q  "EXIT(SELECT SUBSTRING(REPLACE(@@VERSION,'Microsoft SQL Server ',''),1,4))" > log/ShowDBVersion.log
SET dbversion=%ERRORLEVEL%

SET /P dbversion=Verify Database Version (%dbversion%):
IF %dbversion%_ EQU _ ( 
  SET dbversion=2012
  GOTO START 
)
IF %dbversion%_ EQU 2008_ ( 
  GOTO START 
)
IF %dbversion%_ GEQ 2012_ ( 
  SET dbversion=2012
  GOTO START 
)
GOTO GETVERSION

:START

ECHO ===============================
ECHO     Server is %server_instance%
ECHO   Database is %dbname%
ECHO DB version is %dbversion%
ECHO      Owner is %owner%
ECHO COGO Owner is %cogoowner%
ECHO  LRS Owner is %lrsowner%
ECHO ===============================
REM -e is Echo
REM -U username (not trusted)
REM -P password (not trusted) 

ECHO Installing ....
ECHO Check if LRS schema exists and create if not ...
IF %lrsowner%_ NEQ %owner%_ (
  sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%lrsowner% -m-1 -E -i CREATE_SCHEMA.sql  -o log/LRS_CREATE_SCHEMA.log
)
ECHO Check if COGO schema exists and create if not ...
IF %cogoowner%_ NEQ %owner%_ (
  sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%cogoowner% -m-1 -E -i CREATE_SCHEMA.sql -o log/%cogoowner%_CREATE_SCHEMA.log
)

ECHO Drop Any Existing Functions ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% -m-1 -E -i drop_all.sql -o log/__drop_all.log 

ECHO Install New Functions ....
ECHO TOOLS Functions ...
ECHO ... Generate_Series function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/generate_series.sql                     -o log/Generate_Series.log 
ECHO ... Tokenizer Function for database version %dbversion% ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/Tokenizer%dbversion%.sql                -o log/Tokenizer.log 
ECHO ... STFormatNumber Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STFormatNumber.sql                      -o log/STFormatNumber.log
ECHO ... STEquals Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STEquals.sql                            -o log/STEquals.log
ECHO ... STToGeometry/STToGeography functions
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STToGeomGeog.sql                        -o log/STToGeomGeog.log
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STIsGeographicSrid.sql                  -o log/STIsGeographicSrid.log
ECHO ... MBR Functions
find /I src/general/STMBR.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STMBR.sql                               -o log/STMBR.log
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STMakeEnvelope.sql                      -o log/STMakeEnvelope.log
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STMakeEnvelopeFromText.sql              -o log/STMakeEnvelopeFromText.log
ECHO ...... STBoundingDiagonal Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STBoundingDiagonal.sql -o log/STBoundingDiagonal.log

ECHO ... STMorton function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STMorton.sql                            -o log/STMorton.log 
ECHO ... Date Functions  ...
find /I src/general/date_fns.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/date_fns.sql                            -o log/date_fns.log 
ECHO ... GeometryTypes...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STGeometryTypes.sql                     -o log/STGeometryTypes.log
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STMulti.sql                             -o log/Multi.log

ECHO ... INSPECTION Functions ...
ECHO ...... STDetermine Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STDetermine.sql   -o log/STDetermine.log
ECHO ...... STIsCompound function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STIsCompound.sql  -o log/STIsCompound.log
ECHO ...... STIsGeo function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STIsGeo.sql       -o log/STIsGeo.log
ECHO ...... STCoordDim function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STCoordDim%dbversion%.sql  -o log/STCoordDim.log
ECHO ...... STNumDims Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STNumDims.sql     -o log/STNumDims.log
ECHO ...... STNumRings function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STNumRings.sql    -o log/STNumRings.log
ECHO ...... STStartPoint function 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STStartPoint.sql  -o log/STStartPoint.log 
ECHO ...... STEndPoint function 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STEndPoint.sql    -o log/STEndPoint.log 
ECHO ...... STIsPseudoMultiCurve function 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STIsPseudoMultiCurve.sql -o log/STIsPseudoMultiCurve.log 
ECHO ...... STIsCCW function 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STIsCCW.sql -o log/STIsCCW.log 

ECHO ... STPointAsText and STPointGeomAsText Functions ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STPointAsText.sql                       -o log/STPointAsText.log
ECHO ... STMakePoint Functions ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% cogoowner=%cogoowner% -m-1 -E -i src/general/STMakePoint.sql   -o log/STMakePoint.log
ECHO ... STRound Function (depends on STPointAsText)
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STRound.sql                             -o log/STRound.log 
ECHO ... STConvertToLineString Function (no dependencies)
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% -m-1 -E -i src/general/STConvertToLineString.sql               -o log/STConvertToLineString.log 

ECHO ... COGO Functions ...
find /I src/general/DD2DMS.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/DD2DMS.sql        -o log/COGO_DD2DMS.log
find /I src/general/STBearingAndDistance.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STBearingAndDistance.sql -o log/COGO_STBearingAndDistance.log
find /I src/general/STGeographic.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STGeographic.sql    -o log/COGO_STGeographic.log
find /I src/general/STCogoFunctions.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STCOGOFunctions.sql -o log/COGO_STCOGOFunctions.log
ECHO ...... STIsCollinear 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STIsCollinear .sql -o log/COGO_STIsCollinear .log
ECHO ...... STGeographicDistance
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STGeographicDistance.sql -o log/COGO_STGeographicDistance.log
ECHO ...... STEllipsoidParameters
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STEllipsoidParameters.sql -o log/COGO_STEllipsoidParameters.log
ECHO ...... STDirectVincenty
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STDirectVincenty.sql -o log/COGO_STDirectVincenty.log
ECHO ...... STInverseVincenty
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STInverseVincenty.sql -o log/COGO_STInverseVincenty.log

ECHO ... MAKE Functions ...
ECHO ... STMakeLine* Functions (depends on COGO) ...
find /I src/general/STMakeLines.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% owner=%owner% cogoowner=%cogoowner% -m-1 -E -i src/general/STMakeLines.sql     -o log/STMakeLines.log

ECHO ... EXTRACTION Functions ...
ECHO ...... STExtract (for DB Version %dbversion%) function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STExtract%dbversion%.sql -o log/STExtract.log 
ECHO ...... STExtractPolygon  function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STExtractPolygon.sql     -o log/STExtractPolygon.log 
ECHO ...... STForceCollection Function (Before STExplode)
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STForceCollection.sql    -o log/STForceCollection.log 
ECHO ...... STExplode Function 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STExplode.sql            -o log/STExplode.log 
ECHO ...... STSegmentLine function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STSegmentLine.sql        -o log/STSegmentLine.log
REM COGO that depends on STSegmentLine
find /I src/general/STFindLineIntersection.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STFindLineIntersection.sql -o log/COGO_STFindLineIntersection.log
ECHO ...... STVectorize functions
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STVectorize.sql   -o log/STVectorize.log
ECHO ...... STFilterRings function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STFilterRings.sql -o log/STFilterRings.log
ECHO ...... STVertices functions
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STVertices.sql    -o log/STVertices.log 

ECHO ... COGO Functions Dependent on STSegmentize ...
find /I src/general/STLine2Cogo.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STLine2Cogo.sql      -o log/COGO_STLine2Cogo.log
ECHO ...... STAverageBearing Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STAverageBearing.sql -o log/STAverageBearing.log 

ECHO ... EDIT Functions
ECHO ...... STAddZ function ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STAddZ.sql        -o log/STAddZ.log 
ECHO ...... STSetZ function ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STSetZ.sql        -o log/STSetZ.log 
ECHO ...... STInsertN function for database version %dbversion%
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STInsertN%dbversion%.sql -o log/STInsertN.log 
ECHO ...... STUpdate function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STUpdate.sql      -o log/STUpdate.log 
ECHO ...... STUpdateN function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STUpdateN.sql     -o log/STUpdateN.log 
ECHO ...... STDelete function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STDelete.sql      -o log/STDelete.log 
ECHO ...... STDeleteN (depends on STDeleteN) function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STDeleteN.sql     -o log/STDeleteN.log 
ECHO ...... STExtend and STReduce (depends on STInsert and STUpdate) functions
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STExtend.sql      -o log/STExtend.log 
ECHO ...... STAddSegmentByCOGO (uses STExtract) Function ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STAddSegmentByCOGO.sql -o log/STAddSegmentByCOGO.log
ECHO ...... STDensify Function ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STDensify.sql          -o log/STDensify.log
ECHO ...... STConvertToLineString Function ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STConvertToLineString.sql -o log/STConvertToLineString.log

ECHO ... Data Quality Functions ...
ECHO ......  STRemoveSpikes Functions
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STRemoveSpikes.sql          -o log/STRemoveSpikes.log 
ECHO ......  STRemoveCollinearPoints Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STRemoveCollinearPoints.sql -o log/STRemoveCollinearPoints.log 
ECHO ......  STRemoveDuplicatePoints Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STRemoveDuplicatePoints.sql -o log/STRemoveDuplicatePoints.log 

ECHO ... GEOPROCESSING
ECHO ...... STFlipVectors Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STFlipVectors.sql          -o log/STFlipVectors.log 
ECHO ...... STRemoveOffsetSegments Function (Before STOneSidedBuffer and STLineOffset)
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STRemoveOffsetSegments.sql -o log/STRemoveOffsetSegments.log 
ECHO ...... STOneSidedBuffer Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STOneSidedBuffer.sql  -o log/STOneSidedBuffer.log 
ECHO ...... STOffsetLine Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STOffsetLine.sql        -o log/STOffsetLine.log 
ECHO ...... STSwapOrdinates Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STSwapOrdinates.sql   -o log/STSwapOrdinates.log
ECHO ...... STOffsetSegment Function (depends on COGO)
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STOffsetSegment.sql -o log/STOffsetSegment.log 
ECHO ...... STReverse Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STReverse.sql         -o log/STReverse.log 
ECHO ...... STAppend Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STAppend.sql          -o log/STAppend.log 
ECHO ...... STCentroid Functions 
find /I src/general/STCentroid.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STCentroid.sql        -o log/STCentroid.log 
ECHO ...... STSquareBuffer Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STSquareBuffer.sql    -o log/STSquareBuffer.log 
ECHO ...... STRemoveOffsetSegments Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STRemoveOffsetSegments.sql -o log/STRemoveOffsetSegments.log

ECHO ... AFFINE Functions
ECHO ...... STRotate Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STRotate.sql   -o log/STRotate.log 
ECHO ...... STMove Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STMove.sql     -o log/STMove.log 
ECHO ...... STScale Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STScale.sql    -o log/STScale.log 
ECHO ...... PostGIS Functions...
find /I src/general/STPostGIS.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STPostGIS.sql  -o log/STPostGIS.log 

ECHO ... TILING Functions
ECHO ...... STTileXY Function: 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STTileXY.sql          -o log/STTileXY.log 
ECHO ...... STTileGeom Function: 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STTileGeom.sql        -o log/STTileGeom.log 
ECHO ...... STTileGeomByPoint Function: 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STTileGeomByPoint.sql -o log/STTileGeomByPoint.log 
ECHO ...... STTileGeogByPoint Function: 
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STTileGeogByPoint.sql -o log/STTileGeogByPoint.log 
ECHO ...... STTileByNumGrids Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STTileByNumGrids.sql  -o log/STTileByNumGrids.log 
ECHO ...... STTiler Function
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/general/STTiler.sql           -o log/STTiler.log 

ECHO LRS functions (schema %lrsowner%) ....
ECHO ... STSetMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STSetMeasure.sql                   -o log/LRS_STSetMeasure.log 
ECHO ... STAddMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STAddMeasure.sql                   -o log/LRS_STAddMeasure.log
ECHO ... STIsMeasured Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STIsMeasured.sql                   -o log/LRS_STIsMeasured.log
ECHO ... STPointFromCircularArc Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STPointFromCircularArc.sql         -o log/STPointFromCircularArc.log
ECHO ... STFindArcPointByLength Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFindArcPointByLength.sql         -o log/LRS_STFindArcPointByLength.log
ECHO ... STFindArcPointByMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFindArcPointByMeasure.sql        -o log/LRS_STFindArcPointByMeasure.log
find /I SRC/LRS/STExamineMeasures.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STExamineMeasures.sql              -o log/LRS_STExamineMeasures.log 
ECHO ... STFilterLineSegmentByLength Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFilterLineSegmentByLength.sql    -o log/LRS_STFilterLineSegmentByLength.log
ECHO ... STFilterLineSegmentByMEasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFilterLineSegmentByMeasure.sql   -o log/LRS_STFilterLineSegmentByMeasure.log
ECHO ... STSplitCircularStringByLength Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STSplitCircularStringByLength.sql  -o log/LRS_STSplitCircularStringByLength.log
ECHO ... STSplitCircularStringByMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STSplitCircularStringByMeasure.sql -o log/LRS_STSplitCircularStringByMeasure.log
ECHO ... STSplitLineSegmentByLength Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STSplitLineSegmentByLength.sql     -o log/LRS_STSplitLineSegmentByLength.log
ECHO ... STSplitLineSegmentByMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STSplitLineSegmentByMeasure.sql    -o log/LRS_STSplitLineSegmentByMeasure.log
find /I src/LRS/STFindByPointFunctions.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFindByPointFunctions.sql         -o log/LRS_STFindByPointFunctions.log
ECHO ... STFindPointByLength Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFindPointByLength.sql            -o log/LRS_STFindPointByLength.log
ECHO ... STFindPointByMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFindPointByMeasure.sql           -o log/LRS_STFindPointByMeasure.log
ECHO ... STFindSegmentByLengthRange Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFindSegmentByLengthRange.sql     -o log/LRS_STFindSegmentByLengthRange.log
ECHO ... STFindSegmentByMeasureRange Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STFindSegmentByMeasureRange.sql    -o log/LRS_STFindSegmentByMeasureRange.log
ECHO ... STResetMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STResetMeasure.sql                 -o log/LRS_STResetMeasure.log
ECHO ... STReverseMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STReverseMeasure.sql               -o log/LRS_STReverseMeasure.log
ECHO ... STScaleMeasure Function ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STScaleMeasure.sql                 -o log/LRS_STScaleMeasure.log
ECHO ... LRS Validity Functions ....
find /I SRC/LRS/STValidityFunctions.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STValidityFunctions.sql            -o log/LRS_STValidityFunctions.log 
ECHO ... STSplit Functions
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STSplitFunctions.sql               -o log/LRS_STSplitFunctions.log
ECHO ... PostGIS LRS Wrapper Functions ....
find /I SRC/LRS/STPostGIS.sql "CREATE FUNCTION" | find /I "CREATE"
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i src/LRS/STPostGIS.sql                      -o log/LRS_STPostGIS.log 

ECHO ================================================
ECHO Finished installing Functions.
ECHO ================================================

ECHO Check Count of All Functions Procedure in Database ...
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% -m-1 -E -i Function_Count.sql 

forfiles /m "%~nx0" /c "cmd /c echo 0x07"
timeout /t 1 /nobreak>nul

ECHO ================================================
ECHO If you find any bugs or improve this code please 
ECHO send the changes to simon@spdba.com.au or leave
ECHO a message at http://www.spdba.com.au
ECHO ================================================

:EXIT
pause
