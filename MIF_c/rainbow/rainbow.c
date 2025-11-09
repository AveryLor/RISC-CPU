/* This program generates colors like those in a rainbow, in a MIF file. The "rainbow" is meant
 * to be displayed on a VGA monitor. The rainbow can have whatever height is needed, and there
 * can be multiple rainbows.  Different miscellaneous options are also in the (some
 * commented out) code for making borders. To use:
 * 1. set COLS and ROWS to match the target memory
 * 2. set the COLOR_DEPTH to 3, 6, or 9 
 * 3. Compile the code using WindowsMake.bat
 * 4. Run the program ./rainbow.exe 
 *    The result is generated in rainbow_COLS_COLOR_DEPTH.mif
 */
#include <stdio.h>
#define COLS 640
#define ROWS 480
#define RAINBOW ROWS / 10
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

/* 
 *  This function prints pixel colors. It is meant to be used with one of dR, dG, or dB set
 *  to a non-zero value. It ramps the corresponding R, G, or B component of the color either
 *  up to the saturation level from 0, or down to 0 from the saturation level. The component
 *  is ramped up if its d[RGB] = 1, ramped down if is d[RGB] = -1, and unchanged for 
 *  d[RGB] = 0. Each generated pixel color is written to the output file in the range
 *  from (x,y) to (x+(step-1),y).
 */
int ramp (int* R, int* G, int *B, int dR, int dG, int dB, int x, int y, int sat, int step) {
    int c, address, color;
    for (c = 0; c <= sat; ++c) {    // ramp G from 0 to sat
        address = y * COLS + x;
        *R = (dR == 1) ? c : ((dR == -1) ? (sat - c) : *R);
        *G = (dG == 1) ? c : ((dG == -1) ? (sat - c) : *G);
        *B = (dB == 1) ? c : ((dB == -1) ? (sat - c) : *B);
        color = (*R << RGB * 2) | (*G << RGB) | *B;
        if (step > 1)
            fprintf (fp, "[%d..%d] : %X;\n", address, address + step - 1, color);
        else
            fprintf (fp, "%d : %X;\n", address, color);
        x = x + step;
    }
    return x;
}

/* Code to generate rainbow colors.
    Algorithm is to set (two colors at a time) in RBG in this manner:

    RRRRG-RGGGG-GGGGB-GBBBB-BBBBR     saturation level
       G   R       B   G       R 
      G     R     B     G     R  
     G       R   B       G   R   
    GBBBB-BBBBR-BRRRR-RRRRG-RGGGG     0 level

*/   
void rainbow (int sat, int step, int x0, int y0, int rows){

    int x = 0, y = 0;
    int R = 0, G = 0, B = 0;
                                                      //
    // rainbow is 5 "ramps" wide, and each ramp has 2^RGB colors repeated step times
    R = sat; G = 0; B = 0;  // initial color (red)

    x = x0;
    for (y = y0; y < y0 + rows; ++y){
        R = sat; G = 0; B = 0;
        x = ramp (&R, &G, &B, 0, 1, 0, x, y, sat, step);    // ramp up G
    
        // R = sat; G = sat; B = 0;
        x = ramp (&R, &G, &B, -1, 0, 0, x, y, sat, step);   // ramp down R

        // R = 0; G = sat; B = 0;
        x = ramp (&R, &G, &B, 0, 0, 1, x, y, sat, step);    // ramp up B
        
        // R = 0; G = sat; B = sat;
        x = ramp (&R, &G, &B, 0, -1, 0, x, y, sat, step);   // ramp down G

        // R = 0; G = 0; B = sat;
        x = ramp (&R, &G, &B, 1, 0, 0, x, y, sat, step);    // ramp up R

        x = x0;
    }
}
    
int main()
{
    char file_name[80];

    int sat = power(2, RGB) - 1;        // saturation value for R, G, or B
    // rainbow is 5 "ramps" wide, and each ramp has 2^RGB colors repeated step times
    int step = COLS / ((sat + 1) * 5);  // number of times to repeat each rainbow color
    int rainbow_x = (COLS - (5 * step * (sat+1))) / 2;  // starting x coord (center on screen)

    sprintf (file_name, "rainbow_%d_%d.mif", COLS, COLOR_DEPTH);
    fp = fopen (file_name, "w");
    fprintf (fp, "WIDTH=%d;\n", COLOR_DEPTH);
    fprintf (fp, "DEPTH=%d;\n\n", COLS * ROWS);
    fprintf (fp, "ADDRESS_RADIX=UNS;\nDATA_RADIX=HEX;\n\n");
    fprintf (fp, "CONTENT BEGIN\n");

    // rainbow (sat, step, rainbow_x, ROWS >> 2, ROWS >> 1);    // single rainbow
    rainbow (sat, step, rainbow_x, 0, RAINBOW);                 // top rainbow
    rainbow (sat, step, rainbow_x, ROWS - RAINBOW, RAINBOW);    // bottom rainbow

    fprintf (fp, "END;\n");
    fclose (fp);
    return 0;
}

