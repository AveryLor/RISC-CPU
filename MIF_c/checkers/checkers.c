/* This program generates vertical checker-board patterns in a MIF. To use:
 * 1. set COLS and ROWS to match the target memory
 * 2. set the COLOR_DEPTH to 3, 6, or 9 
 * 3. set color1 and color2
 * 4. Compile the code using WindowsMake.bat
 * 5. Run the program ./checkers.exe 
 *    The result is generated in checkers_COLS_COLOR_DEPTH.mif
 */
#include <stdio.h>
#define COLS 640
#define ROWS 480
#define WIDTH COLS / 10
#define COLOR_DEPTH 3
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

// outputs one section of a line of squares: ____----____----
// where ____ is color1 and ---- is color2
void section (int x, int y, int boxes, int box, int color1, int color2) {
    int i, address;
    address = y * COLS + x;
    for (i = boxes; i > 0; i = i - 2) { 
        fprintf (fp, "[%d..%d] : %X;\n", address, address + box - 1, color1);
        address += box;
        fprintf (fp, "[%d..%d] : %X;\n", address, address + box - 1, color2);
        address += box;
    }
}

int main()
{
    char file_name[80];
    int sat = power(2, RGB) - 1;      // saturation value for R, G, or B

    int num_boxes_h = 4;              // somewhat arbitrary
    int box = WIDTH / num_boxes_h;    // size of each square

    sprintf (file_name, "checkers_%d_%d.mif", COLS, COLOR_DEPTH);
    fp = fopen (file_name, "w");
    fprintf (fp, "WIDTH=%d;\n", COLOR_DEPTH);
    fprintf (fp, "DEPTH=%d;\n\n", COLS * ROWS);
    fprintf (fp, "ADDRESS_RADIX=UNS;\nDATA_RADIX=HEX;\n\n");
    fprintf (fp, "CONTENT BEGIN\n");

    int x=0, y=0, R=0, G=0, B=0, color1=0, color2=0, temp=0;
    // R = sat; G = 4; B = 0;  // orange color
    R = sat; G = sat; B = 0;  // yellow
    color1 = (R << RGB * 2) | (G << RGB) | B;
    // R = sat >> 2; G = sat; B = sat >> 2;  // green color
    R = 0; G = sat; B = 0;  // green
    color2 = (R << RGB * 2) | (G << RGB) | B;

    for (y = 0; y < ROWS; ) {
        x = 0;
        section (x, y, num_boxes_h, box, color1, color2); 
        section (COLS - box * num_boxes_h, y, num_boxes_h, box, color2, color1); 
        y = y + 1;
        if (y % box == 0) {
            temp = color1;
            color1 = color2;
            color2 = temp;
        }
    }

    fprintf (fp, "END;\n");
    fclose (fp);
    return 0;
}


