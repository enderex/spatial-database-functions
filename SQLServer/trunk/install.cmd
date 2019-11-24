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
IF %lrsowner%_ NEQ _ GOTO IS2008
SET lrsowner=%owner% 

:IS2008
SET is2008=N
SET /P Express=Are we connecting to an 2008 database? (%is2008%):
IF %is2008%_ EQU _ SET is2008=N

ECHO ===============================
ECHO     Server is %server_instance%
ECHO   Database is %dbname%
ECHO 2008 Database %is2008%
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

ECHO Install General Functions ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i LoadGeneral.sql -o log/__LoadGeneral.log
ECHO Install LRS Functions ....
sqlcmd -b -S %server_instance% -d %dbname% -v usedbname=%dbname% lrsowner=%lrsowner% cogoowner=%cogoowner% owner=%owner% -m-1 -E -i LoadLRS.sql     -o log/__LoadLRS.log

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
