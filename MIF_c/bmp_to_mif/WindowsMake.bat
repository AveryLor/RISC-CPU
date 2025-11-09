@ECHO OFF

set mingw_dir=C:\MinGW\bin
set PATH=%mingw_dir%;%PATH%

@ECHO ON
gcc -Wall -o bmp_to_mif.exe bmp_to_mif.c
