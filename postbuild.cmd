rem echo off

rem chcp 1251>nul
chcp 65001>nul

setlocal enableextensions

exit /b 0

call "C:\Program Files (x86)\Embarcadero\RAD Studio\9.0\bin\rsvars.bat"

rem set MSBUILD = "c:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
SET MSBuildPath=C:\Windows\Microsoft.NET\Framework\v4.0.30319\
SET PATH=%PATH%;%MSBuildPath%;

set configuration=%1
set test_configuration=%configuration%Console
rem set working_dir="%~d0\bin\%configuration%"

if %1 == "Release" (
  set extra=ExtraDefines=AutoGeneratedVersion;
)


call zip_build.cmd %configuration%

rem cd %working_dir%

rem git fetch origin
rem git checkout -b develop origin/develop
rem git pull

cd "%~dp0version"

del _LocalVersion.inc
rename _LocalVersion.inc.tmp _LocalVersion.inc

cd ..

rem git stage version\_LocalVersion.inc

rem git commit -m "Version Increment"

rem git push

endlocal
