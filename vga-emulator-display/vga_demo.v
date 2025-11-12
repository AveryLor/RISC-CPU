// Draw's out the registers

module vga_demo(CLOCK_50, KEY, write, SW, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
    // parameter definitions for 680 x 480 
    parameter nX = 10;
    parameter nY = 9; 
    
    // All program inputs
    input [0:0] KEY; 
    input [7:0] SW; 
    input wire CLOCK_50;	
	output wire [nX-1:0] VGA_X; // for DESim VGA
	output wire [nY-1:0] VGA_Y; // for DESim VGA
	output wire [23:0] VGA_COLOR; // for DESim VGA
	output wire plot; // for DESim VGA

    wire resetn; 
    assign resetn = KEY[0]; 
	input write

    // instantiate the VGA adapter and surrounding support 
	vga_writer writer (CLOCK_50, resetn, VGA_X, VGA_Y, LINE_COLOR, CHAR_COLOR); 
    vga_adapter VGA (
        .resetn(resetn),
        .clock(CLOCK_50),
        .color(color),
        .x(VGA_X),
        .y(VGA_Y),
        .write(write),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    defparam ADAPTER_INST.RESOLUTION = "640x480"; 
    defparam VGA_ADAPT.BACKGROUND_IMAGE = "./mif/0_bmp_640_9.mif" ;
endmodule

// Writes to the screen 
module vga_writer(clock, resetn, VGA_X, VGA_Y, LINE_COLOR, CHAR_COLOR);
	input clock; 
	input resetn;
	output [9:0] VGA_X; 
	output [8:0] VGA_Y; 
	input [7:0] LINE_COLOR; 
	input [7:0] CHAR_COLOR; 

	// Placements for the digits 
	reg [8:0] y_coordinate [0:7];
	reg [3:0] numDigits; 

	initial begin
		y_coordinate[0] = 10;
		y_coordinate[1] = 25;
		y_coordinate[2] = 40;
		y_coordinate[3] = 55;
		y_coordinate[4] = 70;
		y_coordinate[5] = 85;
		y_coordinate[6] = 100;
		y_coordinate[7] = 115;
	end

	// Create 8 registers, each of 4 chars long
	reg [2:0] row_idx; // 0->7 rows
	reg [1:0] col_idx; // 0->3 columns
	reg [2:0] pixel_x; // 0->7 for character width 
	reg [2:0] pixel_y; // 0->7 for character height

	// Checking if we should enable another letter to be drawn
	wire finishedCharacter; 
	wire [5:0] counter;  
	one_char_counter occ (resetn, clock, counter, finishedCharacter); 

	// Moving pixel_x, pixel_y, col_idx and row_idx pointers

	// Each row should start 15 lower than the one before it, each col 9 to the right 
	assign VGA_X = 10 + (col_idx * 9) + pixel_x; // Begin each row at 10, increment to next with col_idx
	assign VGA_Y = y_coordinate[row_idx] + pixel_y; 



endmodule

// Module responsible for incrementing col_idx and row_idx
module row_drawer(clock, resetn, finishedCharacter, COL, ROW); 
	input clock, resetn, finishedCharacter; 
	input [3:0] COL, ROW; 

	always @(posedge clock or negedge resetn) begin
		if (!resetn) begin
			row_idx <= 0;
			col_idx <= 0;
			pixel_x <= 0;
			pixel_y <= 0;
		end else begin
			// move through pixels of one character
			if (finishedCharacter) begin
				if (pixel_x == 7) begin
					pixel_x <= 0;
					if (pixel_y == 7) begin
						pixel_y <= 0;
						// finished this character, move to next column
						if (col_idx == 3) begin
							col_idx <= 0;
							
							// finished this row, move to next row
							if (row_idx == 7)
								row_idx <= 0;
							else
								row_idx <= row_idx + 1;
								
						end else begin
							col_idx <= col_idx + 1;
						end
					end else begin
						pixel_y <= pixel_y + 1;
					end
				end else begin
					pixel_x <= pixel_x + 1;
				end
			end
		end
	end
endmodule

// Module that counts the amount of time it takes to draw one character out
module one_char_counter(resetn, clock, counter, finishedCharacter);
	input resetn, clock; 
	reg [5:0] counter; 
	output reg finishedCharacter; 
	
	always @ (posedge clock) begin
		if (!resetn) begin
			counter <= 0; 
			finishedCharacter <= 0; 
		end else begin
			if (counter == 6'd63) begin
				counter <= 0
				finishedCharacter <= 0;
			end
			counter <= counter + 1;
			finishedCharacter <= 1; // Done 
		end
	end
endmodule


// 8x8 character bitmap for characters space, 0-9, A-F, x and :
module char_bitmap(digit, pixelLine);
	input [7:0] digit;
	output [63:0] pixelLine;
	reg [7:0] pixels [7:0];
	
	assign pixelLine[7:0] = pixels[0];
	assign pixelLine[15:8] = pixels[1];
	assign pixelLine[23:16] = pixels[2];
	assign pixelLine[31:24] = pixels[3];
	assign pixelLine[39:32] = pixels[4];
	assign pixelLine[47:40] = pixels[5];
	assign pixelLine[55:48] = pixels[6];
	assign pixelLine[63:56] = pixels[7];
	
	always @(*) begin
		case(digit[7:0])
				 0: begin // 0
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b10000110;
					pixels[3] = 8'b10001010;
					pixels[4] = 8'b10010010;
					pixels[5] = 8'b10100010;
					pixels[6] = 8'b11000010;
					pixels[7] = 8'b01111100;
				 end
				 1: begin // 1
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01110000;
					pixels[2] = 8'b01010000;
					pixels[3] = 8'b00010000;
					pixels[4] = 8'b00010000;
					pixels[5] = 8'b00010000;
					pixels[6] = 8'b00010000;
					pixels[7] = 8'b11111110;
				 end
				 2: begin// 2
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b00000100;
					pixels[4] = 8'b00001000;
					pixels[5] = 8'b00010000;
					pixels[6] = 8'b00100000;
					pixels[7] = 8'b01111100;
				 end
				 3: begin // 3
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111100;
					pixels[2] = 8'b00000010;
					pixels[3] = 8'b00000010;
					pixels[4] = 8'b00111100;
					pixels[5] = 8'b00000010;
					pixels[6] = 8'b00000010;
					pixels[7] = 8'b11111100;
				 end
				 4: begin // 4
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10001000;
					pixels[2] = 8'b10001000;
					pixels[3] = 8'b10001000;
					pixels[4] = 8'b11111110;
					pixels[5] = 8'b00001000;
					pixels[6] = 8'b00001000;
					pixels[7] = 8'b00001000;
				 end
				 5: begin // 5
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111110;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b00000010;
					pixels[6] = 8'b00000010;
					pixels[7] = 8'b11111100;
				 end
				 6: begin // 6
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b10000010;
					pixels[6] = 8'b10000010;
					pixels[7] = 8'b01111100;
				 end
				 7: begin // 7
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111110;
					pixels[2] = 8'b00000010;
					pixels[3] = 8'b00000100;
					pixels[4] = 8'b00001000;
					pixels[5] = 8'b00010000;
					pixels[6] = 8'b00100000;
					pixels[7] = 8'b01000000;
				 end
				 8: begin // 8
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b10000010;
					pixels[3] = 8'b10000010;
					pixels[4] = 8'b01111100;
					pixels[5] = 8'b10000010;
					pixels[6] = 8'b10000010;
					pixels[7] = 8'b01111100;
				 end
				 9: begin // 9
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b10000010;
					pixels[3] = 8'b10000010;
					pixels[4] = 8'b01111110;
					pixels[5] = 8'b00000010;
					pixels[6] = 8'b00000010;
					pixels[7] = 8'b00000010;
				end
				10: begin // A
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b10000100;
				 end
				 11: begin // B
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11110000;
					pixels[2] = 8'b10001000;
					pixels[3] = 8'b10001000;
					pixels[4] = 8'b11111000;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b11111000;
				 end
				 12: begin // C
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111110;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b10000000;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000000;
					pixels[7] = 8'b01111110;
				 end
				 13: begin // D
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b10000100;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b11111000;
				 end
				 14: begin // E
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111110;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000000;
					pixels[7] = 8'b11111110;
				 end
				 15: begin // F
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111110;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000000;
					pixels[7] = 8'b10000000;
				end
				52: begin // R
					pixels[0] = 8'b11110000;
					pixels[1] = 8'b10001000;
					pixels[2] = 8'b10001000;
					pixels[3] = 8'b11110000;
					pixels[4] = 8'b10100000;
					pixels[5] = 8'b10010000;
					pixels[6] = 8'b10001000;
					pixels[7] = 8'b00000000;
				end
				
				default: begin // space (null char)
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b00000000;
					pixels[2] = 8'b00000000;
					pixels[3] = 8'b00000000;
					pixels[4] = 8'b00000000;
					pixels[5] = 8'b00000000;
					pixels[6] = 8'b00000000;
					pixels[7] = 8'b00000000;
				 end
		endcase
	end
endmodule