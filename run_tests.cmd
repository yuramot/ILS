echo off

rem chcp 1251>nul
chcp 65001>nul

setlocal enableextensions

rem exit /b 0

SET configuration=%1
SET TestPath=dunit

echo ==================================
echo ЗАПУСК ТЕСТОВ

rem echo Копирование тестовых файлов и утилит
rem xcopy "%~dp0Tests\XML\*.xml" "%TestPath%\*.*" /Y
rem xcopy "%~dp0Tests\Utils\RunWithTimeout.exe" "%TestPath%*.*" /Y

cd "%TestPath%"

echo Удаление результатов предыдущих тестов
del report\*.xml

echo Запуск файлов тестирования
..\utils\RunWithTimeout.exe 30 bin\win32\console\GeoCalcTests.exe -source:data\GeoCalc\GeoCalcTests.xml -report:report\GeoCalcTests_Report.xml
..\utils\RunWithTimeout.exe 120 bin\win32\console\TestPlanFact.exe -source:data\PlanFact\ -report:report\TestPlanFact_Report.xml
..\utils\RunWithTimeout.exe 120 bin\win32\console\TestFuelProcessor.exe -source:data\FuelProcessor\ -report:report\TestFuelProcessor_Report.xml

rem echo Запуск файлов тестирования
rem For /R "%TestPath%" %%I In (*Test*.exe) Do (
rem   echo Запуск %%I
rem   RunWithTimeout.exe 300 %%I
rem )

rem echo Копирование результатов
rem copy "%TestPath%\*report.xml" "%~dp0\*.*" /Y
rem del "%TestPath%\*report.xml"

if NOT "%ERRORLEVEL%" == "0" (
  echo Запуск тестов завершен с ERRORLEVEL = %ERRORLEVEL%	
  exit /b -1
)

echo ЗАВЕРШЕНИЕ ТЕСТИРОВАНИЯ
echo ==================================

cd "%~dp0"

endlocal
