rem echo off

rem chcp 1251>nul
chcp 65001>nul

setlocal EnableExtensions EnableDelayedExpansion

SET PATH=%PATH%;%MSBuildPath%;"C:\Program Files\7-Zip";

SET configuration=%1

if "%1" == "" (
SET configuration=Debug
set zipname=%configuration%.%BUILD_NUMBER%
)

if "%configuration%" == "Develop" (
SET configuration=Debug
set zipname=%configuration%.%BUILD_NUMBER%
)

if "%configuration%" == "Release" (
SET configuration=Release
set zipname=%BRANCH_NAME%.%BUILD_NUMBER%
echo %zipname%

set "zipname=!zipname:/=.!"
echo %zipname%
)

if "%configuration%" == "Feature" (
SET configuration=Debug
set zipname=%BRANCH_NAME%.%BUILD_NUMBER%
echo %zipname%

set "zipname=!zipname:/=.!"
echo %zipname%
)


if "%configuration%" == "Master" (
SET configuration=Release
set zipname=%configuration%.%BUILD_NUMBER%
)

rem SET zipfilename=%configuration%
echo "%zipname%"

rem if "%1" NEQ "" (
rem SET zipfilename=%1
rem )

echo ================================
echo АРХИВАЦИЯ СБОРКИ %configuration% В ПАПКЕ %~dp0bin\%configuration% 

echo "%zipname%"
echo "%configuration%"

del /q "*.zip"

cd %~dp0
cd "bin\Win32\%configuration%"
7z.exe a -tzip -ssw -mx7 -r -sdel ..\..\..\%zipname%.zip *.exe
7z.exe a -tzip -ssw -mx7 -r -sdel ..\..\..\%zipname%.zip *.dll
cd %~dp0
cd "bin\Win64\%configuration%"
7z.exe a -tzip -ssw -mx7 -r -sdel ..\..\..\%zipname%.zip *.exe
7z.exe a -tzip -ssw -mx7 -r -sdel ..\..\..\%zipname%.zip *.dll


rem del "%~dp0%configuration%.zip"
rem cd "%~dp0bin\%configuration%"
rem 7z.exe a -tzip -ssw -mx7  -sdel ..\..\%configuration%.zip *.exe
rem 7z.exe a -tzip -ssw -mx7  -sdel ..\..\%configuration%.zip *.dll

echo ЗАВЕРШЕНИЕ АРХИВАЦИИ
echo ================================
