/* This program generates the colors for a green box with red border.
 * 1. set COLS and ROWS to match the target memory
 * 2. set the COLOR_DEPTH to 3, 6, or 9 
 * 3. Compile the code using WindowsMake.bat
 * 4. Run the program ./obect_mem.exe 
 *    The result is generated in obect_mem_COLS_ROWS_COLOR-DEPTH.mif
 */
#include <stdio.h>
#define COLS 16
#define ROWS 16
#define RADIUS ((COLS >>1) - 1)
#define COLOR_DEPTH 9
#define RGB COLOR_DEPTH / 3

static FILE *fp;

int power(int base, int exp) {
    if (exp == 0)
        return 1;
    else if (exp % 2)
        return base * power(base, exp - 1);
    else {
        int temp = power(base, exp / 2);
        return temp * temp;
    }
}

int main()
{
    int x = 0, y = 0, address;
    int xc = (COLS >> 1) - 1;           // center of circle
    int yc = (ROWS >> 1) - 1;
    int R = 0, G = 0, B = 0, color, bg;
    int sat = power(2, RGB) - 1;        // saturation value for R, G, or B
    char file_name[80];

    sprintf (file_name, "circle_%d_%d_%d.mif", COLS, ROWS, COLOR_DEPTH);
    fp = fopen (file_name, "w");
    fprintf (fp, "WIDTH=%d;\n", COLOR_DEPTH);
    fprintf (fp, "DEPTH=%d;\n\n", COLS * ROWS);
    fprintf (fp, "ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\n");
    fprintf (fp, "CONTENT BEGIN\n");

    R = sat; G = sat >> 1; B = 0;  // red
    color = (R << RGB * 2) | (G << RGB) | B;
    R = 0; G = 0; B = 0;  // red
    bg = (R << RGB * 2) | (G << RGB) | B;

    for (y = 0; y < ROWS; ++y)
        for (x = 0; x < COLS; ++x) {
            address = y * COLS + x;
            if ((power(x - xc, 2) + power(y - yc, 2)) <= power(RADIUS, 2))
                fprintf (fp, "%X : %X;\n", address, color);
            else
                fprintf (fp, "%X : %X;\n", address, bg);
        }

    fprintf (fp, "END;\n");
    fclose (fp);
    return 0;
}

