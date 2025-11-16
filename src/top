module top(CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, SW, LEDR, HEX0, HEX1);
	// Logical inputs
	input [9:0] SW;   	
	input CLOCK_50;	
	input [3:0] KEY; 
	// Logical outputs
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;
	output [9:0] LEDR; // LEDR used to display register values (first 4 bits of R1 and R2).
	output [6:0] HEX0;
	output [6:0] HEX1;
	
	control_unit cu (SW, LEDR, KEY, HEX0, HEX1); 
	vga_display vd (CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK); 

endmodule
