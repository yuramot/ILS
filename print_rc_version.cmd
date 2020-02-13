echo off

set /p inputline=""

rem echo|set /p="." >> version_full.txt

for /F "tokens=1-4 delims=. " %%a in ("%inputline%") do (

echo #define Major %%a
echo #define Minor %%b
echo #define Revision %%c
echo #define Build %%d
)