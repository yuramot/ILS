echo off

rem chcp 1251>nul
chcp 65001>nul

setlocal enableextensions

echo =========================================
echo НАЧАЛО СБОРКИ 

call "C:\Program Files (x86)\Embarcadero\RAD Studio\9.0\bin\rsvars.bat"

rem set MSBUILD = "c:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
SET MSBuildPath=C:\Windows\Microsoft.NET\Framework\v4.0.30319\
SET PATH=%PATH%;%MSBuildPath%;

set configuration=Console
set extra=

set TestProjectPath="%~d0\dunit\bin\Win32\%configuration%"
set TestProjectGroup="%~dp0\dunit\src\AutoTests.groupproj"


set extra=ExtraDefines=

if "%1" == "Release" (
set extra=ExtraDefines=AutoGeneratedVersion
)

echo Конфигурация сборки = %configuration% 
echo Конфигурация версии = %extra% 


echo Собираем автотесты
MSBuild.exe /t:Clean /p:Config=%configuration%;%extra%DCC_ExeOutput=%TestProjectPath% %TestProjectGroup%
MSBuild.exe /t:Build /p:Config=%configuration%;%extra%DCC_ExeOutput=%TestProjectPath% %TestProjectGroup%

if NOT "%ERRORLEVEL%" == "0" (
  echo Сборка тестов завершена с ERRORLEVEL = %ERRORLEVEL%	
  exit /b -1
)
echo Сборка автотестов завершена
echo --------------------------------------------

echo Удаляем служебные файлы
del "%ProjectPath%\*.drc"
del "%ProjectPath%\*.map"
del "%TestProjectPath%\*.drc"
del "%TestProjectPath%\*.map"


echo ЗАВЕРШЕНИЕ СБОРКИ

echo ==================================================
endlocal
