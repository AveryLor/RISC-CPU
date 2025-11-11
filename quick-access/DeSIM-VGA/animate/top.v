module top (CLOCK_50, SW, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, VGA_X, VGA_Y, VGA_COLOR, plot);

    input CLOCK_50;             // DE-series 50 MHz clock signal
    input wire [9:0] SW;        // DE-series switches
    input wire [3:0] KEY;       // DE-series pushbuttons

    output wire [6:0] HEX0;     // DE-series HEX displays
    output wire [6:0] HEX1;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;
    output wire [6:0] HEX5;

    output wire [9:0] LEDR;     // DE-series LEDs   
    output wire [9:0] VGA_X;
    output wire [8:0] VGA_Y;
    output wire [23:0] VGA_COLOR;
    output wire plot;

    // The VGA resolution, which can be set to "640x480", "320x240", or "160x120"
    parameter RESOLUTION = "160x120";
    parameter COLOR_DEPTH = 9; // Can be set to 9, 6, or 3
    // VGA x bitwidth
    parameter n = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);
    vga_demo U1 (CLOCK_50, SW, KEY, LEDR, VGA_X[n-1:0], VGA_Y[n-2:0], VGA_COLOR, plot);
        defparam U1.RESOLUTION = RESOLUTION;
        defparam U1.COLOR_DEPTH = COLOR_DEPTH;

endmodule

