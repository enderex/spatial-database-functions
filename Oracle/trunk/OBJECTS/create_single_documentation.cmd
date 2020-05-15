..\..\..\Tools\bin\robodoc ^
      --src src ^
      --doc documentation\OracleObjects ^
      --singledoc ^
      --toc ^
      --index ^
      --html ^
      --syntaxcolors ^
      --sections ^
      --no_subdirectories ^
      --documenttitle "SPDBA Object Types and Methods Documentation" 

Echo Now modifying HEAD HTML ....
rmdir /S /Q html
mkdir html
copy head_favicon.sed html
cd html
SET PATH=%PATH%;"C:\Program Files (x86)\GnuWin32\bin"
copy ..\documentation\OracleObjects.html c_OracleObjects.html 
sed -r -f head_favicon.sed c_OracleObjects.html > OracleObjects.html
IF EXIST OracleObjects.html (
  move OracleObjects.html ..\documentation\
) 
cd ..
rmdir /S /Q html
pause
