// top.v - DESim VGA Demo (Corrected Logic)
// This file contains all modules, with corrected signal and logic flows.

// Top-level module for DESim board
module vga_display(CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, register_file);
	input CLOCK_50;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;
	wire [8:0] VGA_X;
	wire [7:0] VGA_Y;
	wire [8:0] VGA_COLOR; 
	input [3:3] KEY; 
	input [31:0] register_file [7:0]; 
	
	register_drawer rd (CLOCK_50, 1'b1, VGA_X, VGA_Y, VGA_COLOR, register_file); // Primary writer for displays
	reg_title_drawer rtd(CLOCK_50, 1'b1, VGA_X, VGA_Y, VGA_COLOR); 
    vga_adapter VGA (
		.resetn(1'b1),
		.clock(CLOCK_50),
		.color(VGA_COLOR),
		.x(VGA_X),
		.y(VGA_Y),
		.write(1'b1),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "640x480";

endmodule

module reg_title_drawer(clock, resetn, VGA_X, VGA_Y, VGA_COLOR);
	input clock; 
	input resetn; 

	wire [4:0] col_idx; // 0->16 columns

	wire [7:0] title[0:15]; // 16-character title

	assign title[0]  = 8'd16; // G
	assign title[1]  = 8'd14; // E
	assign title[2]  = 8'd23; // N
	assign title[3]  = 8'd14; // E
	assign title[4]  = 8'd27; // R
	assign title[5]  = 8'd10; // A
	assign title[6]  = 8'd21; // L
	assign title[7]  = 8'd37; // space
	assign title[8]  = 8'd27; // R
	assign title[9]  = 8'd14; // E
	assign title[10] = 8'd16; // G
	assign title[11] = 8'd18; // I
	assign title[12] = 8'd28; // S
	assign title[13] = 8'd29; // T
	assign title[14] = 8'd14; // E
	assign title[15] = 8'd27; // R

	
	reg [4:0] char_idx; // 0->15
	always @(posedge clock or negedge resetn) begin
		if (!resetn) begin
			pixel_x <= 0;
			pixel_y <= 0;
			char_idx <= 0;
		end else begin
			if (pixel_x == 7) begin
				pixel_x <= 0;
				if (pixel_y == 7) begin
					pixel_y <= 0;
					if (char_idx < 16)
						char_idx <= char_idx + 1;
					else
						char_idx <= 0; // wrap-around or stop
				end else begin
					pixel_y <= pixel_y + 1;
				end
			end else begin
				pixel_x <= pixel_x + 1;
			end
		end
	end
	wire [63:0] pixelLine;
	character bmp_inst (
		.digit(title[char_idx]),
		.pixelLine(pixelLine)
	);

	// Each character is 8 pixels wide, with 1 pixel spacing
	assign VGA_X = 10 + (char_idx * 9) + pixel_x; 
	assign VGA_Y =10 + pixel_y; // You can set the vertical base

	wire [7:0] pixels [7:0];
	assign pixels[0] = pixelLine[7:0];
	assign pixels[1] = pixelLine[15:8];
	assign pixels[2] = pixelLine[23:16];
	assign pixels[3] = pixelLine[31:24];
	assign pixels[4] = pixelLine[39:32];
	assign pixels[5] = pixelLine[47:40];
	assign pixels[6] = pixelLine[55:48];
	assign pixels[7] = pixelLine[63:56];

	wire pixel_on = pixels[pixel_y][7-pixel_x];
	assign VGA_COLOR = pixel_on ? 9'b111111111 : 3'b000;
endmodule 


// Generates the (X, Y) coordinates, 3-bit color, and write pulse (plot).
//------------------------------------------------------------------
module register_drawer(clock, resetn, VGA_X, VGA_Y, VGA_COLOR, register_file);
    input wire clock; 
    input wire resetn;
	input [31:0] register_file [7:0]; 
    
    // Outputs to VGA Adapter
    output wire [9:0] VGA_X;    // Corrected width to 10 bits (0-639)
    output wire [9:0] VGA_Y;    // Corrected width to 10 bits (0-479)
    output wire [8:0] VGA_COLOR; // 3-bit color output

    // Character Index Pointers
    wire [2:0] row_idx; // 0->7 rows
    wire [4:0] col_idx; // 0->11 columns
    
    // Pixel Pointers (Run on every clock cycle to iterate 8x8 character)
    reg [2:0] pixel_x; // 0->7 for character width 
    reg [2:0] pixel_y; // 0->7 for character height
    
    // Counters and Flags
    wire finishedCharacter; 
    wire [5:0] counter;

    // --- Register Coordinate Definitions (Unchanged) ---
    reg [9:0] y_coordinate [0:7]; // Corrected width to 10 bits
    
    initial begin
        // Y-coordinates corrected to be 10 bits wide
        y_coordinate[0] = 25;
        y_coordinate[1] = 40;
        y_coordinate[2] = 55;
        y_coordinate[3] = 70;
        y_coordinate[4] = 85;
        y_coordinate[5] = 100;
        y_coordinate[6] = 115;
		  y_coordinate[7] = 130;
    end

    // --- Module Instantiations ---

    // 1. Pixel Counter/Finished Character Flag
    one_char_counter occ (
        .resetn(resetn), 
        .clock(clock), 
        .counter(counter), 
        .finishedCharacter(finishedCharacter)
    ); 

    // 2. Character Position Stepper (New name for row_drawer)
    row_drawer rd (
        .clock(clock), 
        .resetn(resetn), 
        .finishedCharacter(finishedCharacter), 
        .row_idx(row_idx), 
        .col_idx(col_idx)
    ); 
    
    // 3. Pixel Coordinates Stepper (Runs on every clock cycle)
    // This logic was originally incorrectly placed in row_drawer
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            pixel_x <= 0;
            pixel_y <= 0;
        end else begin
            if (pixel_x == 7) begin
                pixel_x <= 0;
                if (pixel_y == 7) begin
                    pixel_y <= 0;
                end else begin
                    pixel_y <= pixel_y + 1;
                end
            end else begin
                pixel_x <= pixel_x + 1;
            end
        end
    end

    // Defines 4 columns, 8 bit identifier each 
    wire [7:0] column_values [11:0]; 
    
    // We only need an initial block for initial values, but for dynamic content it should be a wire/reg
    // Example payload: AAAA0001
    wire [31:0] curRegister = register_file[row_idx]; 
    assign column_values[0] = 8'd27; // R
    assign column_values[1] = row_idx; // Number identifier 
    assign column_values[2] = 8'd36; // : 
	assign column_values[3] = 8'd37; // Space
    assign column_values[4] = curRegister[31:28]; //  A
	assign column_values[5] = curRegister[27:24]; //   A
	assign column_values[6] = curRegister[23:20]; //   A
	assign column_values[7] = curRegister[19:16]; //   A
	assign column_values[8] = curRegister[15:12]; //   0
	assign column_values[9] = curRegister[11:8]; //   0
	assign column_values[10] = curRegister[7:4]; //  0
	assign column_values[11] = curRegister[3:0]; //  1
    
    // --- Map character to bitmap ---
    wire [7:0] current_char_code; // Corrected width to 8 bits for char_bitmap input
    assign current_char_code = column_values[col_idx]; // Use col_idx (0-3) to select char code
    
    wire [63:0] pixelLine;
    character bmp_inst(
        .digit(current_char_code), 
        .pixelLine(pixelLine)
    );

    // Re-organize pixelLine into an array of 8 rows (8 bits each)
    wire [7:0] pixels [7:0];
    assign pixels[0] = pixelLine[7:0];
    assign pixels[1] = pixelLine[15:8];
    assign pixels[2] = pixelLine[23:16];
    assign pixels[3] = pixelLine[31:24];
    assign pixels[4] = pixelLine[39:32];
    assign pixels[5] = pixelLine[47:40];
    assign pixels[6] = pixelLine[55:48];
    assign pixels[7] = pixelLine[63:56];


    // X position: Start at 10, offset by column index * 9, offset by inner pixel x
    assign VGA_X = 10 + (col_idx * 9) + pixel_x; 
    
    // Y position: Start at base row coordinate, offset by inner pixel y
    assign VGA_Y = y_coordinate[row_idx] + pixel_y; 

    wire pixel_on;
    assign pixel_on = pixels[pixel_y][7-pixel_x];

	 // Display pixels in white
    assign VGA_COLOR = pixel_on ? 9'b111111111 : 3'b000;
    
    // The plot signal should be asserted only when the VGA adapter is ready to write
endmodule

// Increments row
module row_drawer(clock, resetn, finishedCharacter, col_idx, row_idx); 
    input wire clock, resetn, finishedCharacter; 
    output reg [2:0] row_idx; 
    output reg [4:0] col_idx; // 0 to 11

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            row_idx <= 0;
            col_idx <= 0;
        end else if (finishedCharacter) begin // Only steps forward when character is done
            if (col_idx == 11) begin // Finished the 4th column (0, 1, 2, 3)
                col_idx <= 0;
                
                if (row_idx == 7) // Finished the 8th row (0 to 7)
                    row_idx <= 0; // Wrap back to the first row
                else
                    row_idx <= row_idx + 1; // Move to the next row
                    
            end else begin
                col_idx <= col_idx + 1; // Move to the next column
            end
        end
    end
endmodule

// Keeps track of when one character is done counting
module one_char_counter(resetn, clock, counter, finishedCharacter);
    input resetn, clock; 
    output reg [5:0] counter; 
    output reg finishedCharacter; 
    
    always @ (posedge clock) begin
        if (!resetn) begin
            counter <= 0; 
            finishedCharacter <= 0; 
        end else begin
            if (counter == 6'd63) begin
                counter <= 0;
                finishedCharacter <= 1;
            end else begin
                counter <= counter + 1;
                finishedCharacter <= 0;
            end
        end
    end
endmodule


module character(digit, pixelLine);
	input wire [7:0] digit;
	output wire [63:0] pixelLine;
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
				// Uppercase A-Z
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
					pixels[1] = 8'b11111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b11111000;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b11111000;
				end
				12: begin // C
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b10000010;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b10000000;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000010;
					pixels[7] = 8'b01111100;
				end
				13: begin // D
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11110000;
					pixels[2] = 8'b10001000;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b10000100;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10001000;
					pixels[7] = 8'b11110000;
				end
				14: begin // E
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111100;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000000;
					pixels[7] = 8'b11111100;
				end
				15: begin // F
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111100;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000000;
					pixels[7] = 8'b10000000;
				end
				16: begin // G
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b10000010;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b10001110;
					pixels[5] = 8'b10000010;
					pixels[6] = 8'b10000010;
					pixels[7] = 8'b01111100;
				end
				17: begin // H
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000100;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b11111100;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b10000100;
				end
				18: begin // I
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b00010000;
					pixels[3] = 8'b00010000;
					pixels[4] = 8'b00010000;
					pixels[5] = 8'b00010000;
					pixels[6] = 8'b00010000;
					pixels[7] = 8'b01111100;
				end
				19: begin // J
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b00011110;
					pixels[2] = 8'b00001000;
					pixels[3] = 8'b00001000;
					pixels[4] = 8'b00001000;
					pixels[5] = 8'b10001000;
					pixels[6] = 8'b10001000;
					pixels[7] = 8'b01110000;
				end
				20: begin // K
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000100;
					pixels[2] = 8'b10001000;
					pixels[3] = 8'b10010000;
					pixels[4] = 8'b11100000;
					pixels[5] = 8'b10010000;
					pixels[6] = 8'b10001000;
					pixels[7] = 8'b10000100;
				end
				21: begin // L
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000000;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b10000000;
					pixels[4] = 8'b10000000;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000000;
					pixels[7] = 8'b11111100;
				end
				22: begin // M
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000010;
					pixels[2] = 8'b11000110;
					pixels[3] = 8'b10101010;
					pixels[4] = 8'b10010010;
					pixels[5] = 8'b10000010;
					pixels[6] = 8'b10000010;
					pixels[7] = 8'b10000010;
				end
				23: begin // N
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000010;
					pixels[2] = 8'b11000010;
					pixels[3] = 8'b10100010;
					pixels[4] = 8'b10010010;
					pixels[5] = 8'b10001010;
					pixels[6] = 8'b10000110;
					pixels[7] = 8'b10000010;
				end
				24: begin // O
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b10000100;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b01111000;
				end
				25: begin // P
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b11111000;
					pixels[5] = 8'b10000000;
					pixels[6] = 8'b10000000;
					pixels[7] = 8'b10000000;
				end
				26: begin // Q
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b10000100;
					pixels[5] = 8'b10010100;
					pixels[6] = 8'b10001000;
					pixels[7] = 8'b01110100;
				end
				27: begin // R
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111000;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b11111000;
					pixels[5] = 8'b10010000;
					pixels[6] = 8'b10001000;
					pixels[7] = 8'b10000100;
				end
				28: begin // S
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01111100;
					pixels[2] = 8'b10000000;
					pixels[3] = 8'b01111100;
					pixels[4] = 8'b00000100;
					pixels[5] = 8'b00000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b01111000;
				end
				29: begin // T
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111110;
					pixels[2] = 8'b00100000;
					pixels[3] = 8'b00100000;
					pixels[4] = 8'b00100000;
					pixels[5] = 8'b00100000;
					pixels[6] = 8'b00100000;
					pixels[7] = 8'b00100000;
				end
				30: begin // U
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000100;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b10000100;
					pixels[5] = 8'b10000100;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b01111000;
				end
				31: begin // V
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000100;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10000100;
					pixels[4] = 8'b10000100;
					pixels[5] = 8'b01001000;
					pixels[6] = 8'b00110000;
					pixels[7] = 8'b00000000;
				end
				32: begin // W
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000100;
					pixels[2] = 8'b10000100;
					pixels[3] = 8'b10010010;
					pixels[4] = 8'b10101010;
					pixels[5] = 8'b10101010;
					pixels[6] = 8'b01000100;
					pixels[7] = 8'b00000000;
				end
				33: begin // X
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000100;
					pixels[2] = 8'b01001000;
					pixels[3] = 8'b00110000;
					pixels[4] = 8'b00110000;
					pixels[5] = 8'b01001000;
					pixels[6] = 8'b10000100;
					pixels[7] = 8'b00000000;
				end
				34: begin // Y
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b10000100;
					pixels[2] = 8'b01001000;
					pixels[3] = 8'b00110000;
					pixels[4] = 8'b00100000;
					pixels[5] = 8'b00100000;
					pixels[6] = 8'b00100000;
					pixels[7] = 8'b00100000;
				end
				35: begin // Z
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11111110;
					pixels[2] = 8'b00000100;
					pixels[3] = 8'b00001000;
					pixels[4] = 8'b00010000;
					pixels[5] = 8'b00100000;
					pixels[6] = 8'b01000000;
					pixels[7] = 8'b11111110;
				end
				36: begin //:
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b01100000;
					pixels[2] = 8'b01100000;
					pixels[3] = 8'b00000000;
					pixels[4] = 8'b00000000;
					pixels[5] = 8'b01100000;
					pixels[6] = 8'b01100000;
					pixels[7] = 8'b00000000;					
				end	
				37: begin // space (null char)
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b00000000;
					pixels[2] = 8'b00000000;
					pixels[3] = 8'b00000000;
					pixels[4] = 8'b00000000;
					pixels[5] = 8'b00000000;
					pixels[6] = 8'b00000000;
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
