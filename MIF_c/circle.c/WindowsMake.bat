@ECHO OFF

set mingw_dir=C:\MinGW\bin
set PATH=%mingw_dir%;%PATH%

@ECHO ON
gcc -Wall -o circle.exe circle.c
