set MIF_FILES=..\MIF\*.mif
set SOURCE_FILES=../*.v ../vga_adapter/*.v

REM if any memory initialization files exist, copy them to this folder
%WINDIR%\System32\xcopy /y /c /q /i %MIF_FILES% .\MIF

if exist work rmdir /S /Q work

vlib work
vlog ../tb/*.v
vlog %SOURCE_FILES%
