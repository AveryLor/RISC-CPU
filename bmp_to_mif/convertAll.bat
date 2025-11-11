@echo off
set "BMP_FOLDER=../../assets/"
set "EXECUTABLE=bmp_to_mif.exe"
echo Starting batch conversion...
pushd %BMP_FOLDER%
FOR %%f IN (*.bmp) DO (
    echo Processing file: "%%f"
    ..\..\bmp_to_mif.exe "%%f"
)
popd
echo.
echo Conversion complete!
pause