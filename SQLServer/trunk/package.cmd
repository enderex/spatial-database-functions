@ECHO OFF

set path=%path%;..\..\tools\bin

ECHO rename install.cmd to install_cmd ...
rename install.cmd install_cmd
rename installSQLAuthMode.cmd installSQLAuthMode_cmd

ECHO Remove old deploy zip files ...
del deploy\SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip

ECHO Create SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip ...
zip -r deploy\SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip ^
       README.txt ^
       COPYING.LESSER ^
       CREATE_SCHEMA.sql ^
       Drop_All.sql ^
       LoadGeneral.sql ^
       LoadLRS.sql ^
       install_cmd ^
       installSQLAuthMode_cmd ^
       Function_Count.sql ^
       src\General\*.* ^
       src\LRS\*.* ^
       test\General\*.* ^
       test\LRS\*.* ^
       test\LRS_End_To_End_Testing.sql ^
       Documentation\SQLServer*.* > NUL

ECHO rename install_cmd to back to install.cmd ...
rename installSQLAuthMode_cmd installSQLAuthMode.cmd
rename install_cmd install.cmd

pause
