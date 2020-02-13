rem echo off

setlocal enableextensions

rem chcp 1251>nul
chcp 65001>nul

SET MSBuildPath=C:\Windows\Microsoft.NET\Framework\v4.0.30319\
SET PATH=%PATH%;%MSBuildPath%;

set extra=
set UtilBinPath=..\..\..\utils
set UtilProjectGroup=%~dp0src\ILSBuildUtils.groupproj
rem TASKKILL /F /IM MonitoringServerTests.exe /T
rem TASKKILL /F /IM AStarTests.exe /T

rem Тут удаляем отчёты от предыдущего билда
del "%~dp0*.xml"

call "C:\Program Files (x86)\Embarcadero\RAD Studio\9.0\bin\rsvars.bat"

echo ===============================
echo СБОРКА УТИЛИТ И УСТАНОВКА ВЕРСИИ
echo Группа сборки = %UtilProjectGroup%
echo Директория сборки = %UtilBinPath%

MSBuild.exe /t:Build /p:Config=Release;DCC_ExeOutput="%UtilBinPath%";FinalOutputDir="%UtilBinPath%\\" "%UtilProjectGroup%"

set /A EL = 0

del version\_AutogeneratedVersion.inc
del version\version_full.txt

if "%1" == "Release" (
  echo|set /p=%BRANCH_NAME% > version\version_full.txt
  echo|set /p="." >> version\version_full.txt
  echo|set /p=%BUILD_NUMBER% >> version\version_full.txt

  utils\MakeVersion.exe version\version_full.txt version\_AutogeneratedVersion.inc /releasevariant="(%BRANCH_NAME%.%BUILD_NUMBER%) TESTING ONLY!!!"
)

if "%1" == "Feature" (
  echo|set /p=%BRANCH_NAME% > version\version_full.txt
  echo|set /p="." >> version\version_full.txt
  echo|set /p=%BUILD_NUMBER% >> version\version_full.txt

  utils\MakeVersion.exe version\version_full.txt version\_AutogeneratedVersion.inc /localversion=version\_LocalVersion.inc /releasevariant="(%BRANCH_NAME%.%BUILD_NUMBER%) TESTING ONLY!!!"
)

if "%1" == "Master" (
  git describe --abbrev=0 --tags > version\version_full.txt
  echo|set /p="." >> version\version_full.txt
  echo|set /p=%BUILD_NUMBER% >> version\version_full.txt

  utils\MakeVersion.exe version\version_full.txt version\_AutogeneratedVersion.inc /releasevariant=
)

set /A EL = %ERRORLEVEL%

echo Установлена версия:
type "version\_AutogeneratedVersion.inc"

echo Удаляем служебные файлы
del "%UtilBinPath%\*.drc"
del "%UtilBinPath%\*.map"
del "%UtilBinPath%\*.il*"
del "%UtilBinPath%\*.pdi"
del "%UtilBinPath%\*.tds"
del "%UtilBinPath%\*.obj"


echo УТИЛИТЫ СОБРАНЫ С ERRORLEVEL = "%EL%"

if NOT "%EL%" == "0" (
  exit /b -1
)

echo ======================================

endlocal