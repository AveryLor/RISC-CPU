`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20;
    parameter RESOLUTION = "160x120"; // "640x480", "320x240", "160x120"
    parameter n = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);

    reg CLOCK_50;	
	reg [9:0] SW;
	reg [3:0] KEY;
	wire [9:0] LEDR;
    wire [6:0] HEX3, HEX2, HEX1, HEX0;
	wire [n-1:0] VGA_X;
	wire [n-2:0] VGA_Y;
	wire [23:0] VGA_COLOR;

	initial begin
        CLOCK_50 <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
	end
	
	initial begin
        KEY[0] <= 1'b0; KEY[1] <= 1'b1; KEY[2] <= 1'b1; KEY[3] <= 1'b1; SW <= 10'b0;
        #20 KEY[0] <= 1'b1; // reset
	end // initial

	vga_demo U1 (CLOCK_50, SW, KEY, LEDR, VGA_X, VGA_Y, VGA_COLOR, plot);
        defparam U1.RESOLUTION = RESOLUTION;

endmodule
