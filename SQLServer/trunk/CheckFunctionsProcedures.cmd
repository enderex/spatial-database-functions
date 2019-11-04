@ECHO ON

SETLOCAL 
SET PATH=%PATH%;F:\Projects\spatial-database-functions\Tools\bin

ECHO Number of General Functions/Procedures ...
findstr /I /R "^CREATE (FUNCTION|PROCEDURE)" src\general\*.sql | wc -l

ECHO Number of LRS Functions/Procedures ...
findstr /I /R "^CREATE (FUNCTION|PROCEDURE)" src\lrs\*.sql | wc -l

pause
