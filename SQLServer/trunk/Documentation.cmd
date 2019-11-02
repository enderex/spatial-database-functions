@ECHO ON

SETLOCAL 
SET PATH=%PATH%;..\..\tools\bin

ECHO Clean Previous Documentation...
DEL /Q documentation\*.*

ECHO Generate Documentation for SQL Server General....
robodoc ^
     --src src\general ^
     --doc documentation\c_SQLServer ^
     --singledoc ^
     --index ^
     --html ^
     --syntaxcolors ^
     --toc ^
     --sections ^
     --nogeneratedwith ^
     --documenttitle "SPDBA General TSQL Function Documentation" 

ECHO Generate Documentation for SQL Server LRS....
robodoc ^
     --src src\LRS ^
     --doc documentation\c_SQLServerLrs ^
     --singledoc ^
     --index ^
     --html ^
     --syntaxcolors ^
     --toc ^
     --sections ^
     --nogeneratedwith ^
     --documenttitle "SPDBA LRS Function Documentation" 

ECHO Modify SQLServer.html ...
sed -r -f head_favicon.sed documentation\c_SQLServer.html > documentation\SQLServer.html
ECHO Modify SQLServerLrs.html ...
sed -r -f head_favicon.sed documentation\c_SQLServerLrs.html > documentation\SQLServerLrs.html
ECHO Rename css files ...
rename documentation\c_SQLServerLrs.css SQLServerLrs.css
rename documentation\c_SQLServer.css    SQLServer.css
ECHO Clean up ...
del documentation\c_SQLServer.html 
del documentation\c_SQLServerLrs.html

pause
