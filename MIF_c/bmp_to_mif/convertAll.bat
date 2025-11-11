@echo off
set "BMP_FOLDER=."  // Change this to your folder path, e.g., ".\my_images"
set "EXECUTABLE=bmp_to_mif.exe"

echo Starting batch conversion...

// The FOR command iterates through every file matching the pattern in the folder.
FOR %%f IN (%BMP_FOLDER%\*.bmp) DO (
    echo Processing file: "%%f"
    
    // Execute the C program, passing the full file path (%%f) as the argument.
    %EXECUTABLE% "%%f"
    
    // Optional: Rename the resulting MIF file to include the original BMP's name
    // The C program creates "bmp_640_9.mif" by default. We rename it here.
    REN "bmp_%COLS%_%COLOR_DEPTH%.mif" "%%~nf.mif"
)

echo.
echo Conversion complete!
pause