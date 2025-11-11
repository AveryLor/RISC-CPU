`default_nettype none

/* This Verilog code demonstrates use of the VGA output window in the DESim GUI. The demo reads
 * an image from a memory and displays this image on the VGA output. After the image has been 
 * displayed, the code illuminates LEDR[9].
 *
 * Three levels of VGA resolution are supported in this example: 640x480, 320x240, and 160x120.
 * The resolution is set in the Verilog file top.v and must match that selected in the DESim GUI 
 * within the VGA output window. The color depth of the image is set in the file top.v. Three 
 * depths are supported: 3-, 6-, and 9-bit color.
 */

module vga_demo(CLOCK_50, KEY, LEDR, VGA_X, VGA_Y, VGA_COLOR, plot);
	
    // default resolution. Specify a resolution in top.v
    parameter RESOLUTION = "640x480"; // "640x480" "320x240" "160x120"

    // default color depth. Specify a color depth in top.v
    parameter COLOR_DEPTH = 9; // 9 6 3

    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = (RESOLUTION == "640x480") ? 9 : ((RESOLUTION == "320x240") ? 8 : 7);

	input wire CLOCK_50;	
	input wire [3:0] KEY;
	input wire [9:0] LEDR;
	output wire [nX-1:0] VGA_X;          // for DESim VGA
	output wire [nY-1:0] VGA_Y;          // for DESim VGA
	output wire [23:0] VGA_COLOR;        // for DESim VGA
	output wire plot;                    // for DESim VGA

    /* The following signals are needed for connections to the VGA adapter. These signals
     * would be needed if the demo code were to write to pixels using their x, y addresses, but
     * this example only reads the contents of the video memory and displays it. Since this 
     * example does not write to individual pixels except when reading from the video memory, 
     * the signals below are used only as placeholders. */
	wire [COLOR_DEPTH-1:0] color;        // used as placeholder
    wire [nX-1:0] X;                     // used as placeholder
    wire [nY-1:0] Y;                     // used as placeholder
    wire write;                          // used as placeholder
    
    wire VGA_SYNC;  // used to indicate that the video-memory has been read and displayed

    // display the color depth
    assign LEDR[3:0] = (COLOR_DEPTH == 9) ? 4'b1001 : ((COLOR_DEPTH == 6) ? 4'b0110 : 4'b0011);

    assign color = 0;
    assign X = 0;
    assign Y = 0;
    assign write = 0;

    // instantiate the DESim VGA adapter
    `define VGA_MEMORY              // include a memory module in the VGA adapter
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(color),              // used to draw pixels on top of background
        .x(X),                      // used to draw pixels on top of background
        .y(Y),                      // used to draw pixels on top of background
        .write(write),              // used to draw pixels on top of background
        .VGA_X(VGA_X),              // the output VGA x coordinate (column)
        .VGA_Y(VGA_Y),              // the output VGA y coordinate (row)
        .VGA_COLOR(VGA_COLOR),      // the output VGA color
        .VGA_SYNC(VGA_SYNC),        // indicates when background MIF has been drawn
        .plot(plot));               // the output VGA plot signal
		defparam VGA.RESOLUTION = RESOLUTION;
        // choose background image according to resolution and color depth
		defparam VGA.BACKGROUND_IMAGE = "./mif/0_bmp_160_6.mif"; 
        
        assign LEDR[9] = VGA_SYNC;      // turn on LED when background drawing is done
endmodule
