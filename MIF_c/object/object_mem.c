/* This program generates a MIF for a colored box with a border.
 * 1. set COLS and ROWS to match the target memory
 * 2. set the COLOR_DEPTH to 3, 6, or 9 
 * 3. Compile the code using WindowsMake.bat
 * 4. Run the program ./obect_mem.exe 
 *    The result is generated in obect_mem_COLS_ROWS_COLOR-DEPTH.mif
 */
#include <stdio.h>
#define COLS 16
#define ROWS 16
#define COLOR_DEPTH 24
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
    int R = 0, G = 0, B = 0, color;
    int sat = power(2, RGB) - 1;        // saturation value for R, G, or B
    char file_name[80];

    sprintf (file_name, "object_mem_%d_%d_%d.mif", COLS, ROWS, COLOR_DEPTH);
    fp = fopen (file_name, "w");
    fprintf (fp, "WIDTH=%d;\n", COLOR_DEPTH);
    fprintf (fp, "DEPTH=%d;\n\n", COLS * ROWS);
    fprintf (fp, "ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\n");
    fprintf (fp, "CONTENT BEGIN\n");

    R = sat; G = sat >> 1; B = 0;  // red
    color = (R << RGB * 2) | (G << RGB) | B;

    // two rows of red
    for (y = 0; y < 2; ++y){
        address = y * COLS + x;
        fprintf (fp, "[%X..%X] : %X;\n", address, address + COLS - 1, color);
    }
    // all but last two rows are RRGGGGG....GGGGRR
    for (; y < ROWS - 2; ++y){
        // two pixels in red
        x = 0;
        address = y * COLS + x;
        fprintf (fp, "[%X..%X] : %X;\n", address, address + 1, color);

        x = x + 2;
        // rest of the row in green, except last two pixels
        R = 0; G = sat; B = 0; // green
        color = (R << RGB * 2) | (G << RGB) | B;
        address = y * COLS + x;
        fprintf (fp, "[%X..%X] : %X;\n", address, address + (COLS - 1 - 4), color);

        x = x + COLS - 1 - 4 + 1;
        R = sat; G = sat >> 1; B = 0;  // red
        color = (R << RGB * 2) | (G << RGB) | B;
        address = y * COLS + x;
        fprintf (fp, "[%X..%X] : %X;\n", address, address + 1, color);
    }
    x = 0;
    R = sat; G = sat >> 1; B = 0;  // red
    color = (R << RGB * 2) | (G << RGB) | B;
    // two rows of red
    for (; y < ROWS; ++y){
        address = y * COLS + x;
        fprintf (fp, "[%X..%X] : %X;\n", address, address + COLS - 1, color);
    }

    fprintf (fp, "END;\n");
    fclose (fp);
    return 0;
}

