@ECHO OFF

SETLOCAL 
SET PATH=%PATH%;F:\Projects\spatial-database-functions\Tools\bin

ECHO Clean Previous Documentation...
DEL /Q documentation\*.*

REM
ECHO Generate Documentation for SQL Server General....

ECHO ... Copy SQL files in to documentation folder to fix and file attribute problems...
FOR /R src\general %%f IN (*.sql) DO TYPE %%f > documentation\%%~nxf

robodoc ^
    --src documentation ^
    --doc documentation\SQLServer ^
    --singledoc ^
    --index ^
    --html ^
    --syntaxcolors ^
    --toc ^
    --sections ^
    --nogeneratedwith ^
    --documenttitle "SPDBA General TSQL Function Documentation" 

ECHO ... Remove copied General SQL files now documentation has been created....
DEL /Q documentation\*.sql

REM =========================================================
ECHO Generate Documentation for SQL Server LRS....

ECHO ... Copy SQL files in to documentation folder to fix and file attribute problems...
FOR /R src\lrs %%f IN (*.sql) DO TYPE %%f > documentation\%%~nxf

robodoc ^
    --src documentation ^
    --doc documentation\SQLServerLrs ^
    --singledoc ^
    --index ^
    --html ^
    --syntaxcolors ^
    --toc ^
    --sections ^
    --nogeneratedwith ^
    --documenttitle "SPDBA LRS Function Documentation" 

ECHO ... Remove copied LRS SQL files now documentation has been created....
DEL /Q documentation\*.sql

ECHO Modify HTML ...
cd documentation
ECHO ... SQLServer.html ...
copy SQLServer.html c_SQLServer.html 
sed -r -f ..\head_favicon.sed c_SQLServer.html > SQLServer.html
ECHO ... SQLServerLrs.html ...
copy SQLServerLrs.html c_SQLServerLrs.html 
sed -r -f ..\head_favicon.sed c_SQLServerLrs.html > SQLServerLrs.html
ECHO ... Cleaning up ...
DEL c_SQLServer.html 
DEL c_SQLServerLrs.html 
cd ..
REM
pause
