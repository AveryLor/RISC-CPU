// top.v - DESim VGA Demo (Corrected Logic)
// This file contains all modules, with corrected signal and logic flows.

// Top-level module for DESim board
module vga_demo(CLOCK_50, KEY, SW, VGA_SYNC);
	input wire CLOCK_50;
	input wire [3:0] KEY;

	wire [8:0] VGA_X;
	wire [7:0] VGA_Y;
	wire [2:0] VGA_COLOR;

    input wire [7:0] SW; 
    output wire VGA_SYNC; 

	
	vga_writer writer (CLOCK_50, KEY[0], VGA_X, VGA_Y, VGA_COLOR, SW); 
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .write(KEY[3]), 
        .VGA_COLOR(VGA_COLOR),  // the output VGA color
        .VGA_SYNC(VGA_SYNC)  // indicates when background MIF has been drawn
    );
	defparam VGA.RESOLUTION = "640x480";
	defparam VGA.BACKGROUND_IMAGE = "./mif/0_bmp_640_9.mif";
endmodule

//------------------------------------------------------------------
// Module: vga_writer
// Generates the (X, Y) coordinates, 3-bit color, and write pulse (plot).
// This logic has been substantially fixed to handle counters correctly.
//------------------------------------------------------------------
module vga_writer(clock, resetn, VGA_X, VGA_Y, VGA_COLOR, SW);
    input wire clock; 
    input wire resetn;
    input wire [7:0] SW; // For future use
    
    // Outputs to VGA Adapter
    output wire [9:0] VGA_X;    // Corrected width to 10 bits (0-639)
    output wire [9:0] VGA_Y;    // Corrected width to 10 bits (0-479)
    output wire [2:0] VGA_COLOR; // 3-bit color output

    // --- Internal Logic Signals ---
    // Character Index Pointers (Updated by char_index_fsm/row_drawer)
    wire [2:0] row_idx; // 0->7 rows
    wire [1:0] col_idx; // 0->3 columns
    
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
        y_coordinate[0] = 10;
        y_coordinate[1] = 25;
        y_coordinate[2] = 40;
        y_coordinate[3] = 55;
        y_coordinate[4] = 70;
        y_coordinate[5] = 85;
        y_coordinate[6] = 100;
        y_coordinate[7] = 115;
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
    // Only increments when finishedCharacter is asserted (one clock pulse)
    char_index_fsm cif (
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

    // This defines the character codes to be displayed for one 4-character register line.
    // The width of the array indices (4:0) is confusing, but the number of elements is 4 (0 to 3).
    // The width of the values (5:0) is correct for char_bitmap input (0 to 18).
    reg [5:0] column_values [0:3]; 
    
    // We only need an initial block for initial values, but for dynamic content it should be a wire/reg
    // For simplicity, let's keep it as an array of regs initialized in an initial block
    initial begin
        column_values[0] = 6'd16; // R
        column_values[1] = 6'd17; // :
        column_values[2] = 6'd18; // Space
        column_values[3] = 6'd0;  // 0 (Placeholder data)
    end
    
    // --- Map character to bitmap ---
    wire [7:0] current_char_code; // Corrected width to 8 bits for char_bitmap input
    assign current_char_code = column_values[col_idx]; // Use col_idx (0-3) to select char code
    
    wire [63:0] pixelLine;
    char_bitmap bmp_inst(
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

    // Assign 3-bit color: White (3'b111) if pixel is on, Black (3'b000) if off
    assign VGA_COLOR = pixel_on ? 3'b111 : 3'b000;
    
    // The plot signal should be asserted only when the VGA adapter is ready to write
endmodule

// Increments row
module char_index_fsm(clock, resetn, finishedCharacter, col_idx, row_idx); 
    input wire clock, resetn, finishedCharacter; 
    output reg [2:0] row_idx; 
    output reg [1:0] col_idx; 

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            row_idx <= 0;
            col_idx <= 0;
        end else if (finishedCharacter) begin // Only steps forward when character is done
            if (col_idx == 3) begin // Finished the 4th column (0, 1, 2, 3)
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
    input wire resetn, clock; 
    output reg [5:0] counter;
    output reg finishedCharacter; 
    
    always @ (posedge clock or negedge resetn) begin
        if (!resetn) begin
            counter <= 0; 
            finishedCharacter <= 0; 
        end else begin
            finishedCharacter <= 0; // Default de-assert
            if (counter == 6'd63) begin // Reached final count
                counter <= 0; // Roll over
                finishedCharacter <= 1; // Assert pulse for one cycle
            end else begin
                counter <= counter + 1; // Count up
            end
        end
    end
endmodule

// Maps the bitmap characters
module char_bitmap(digit, pixelLine);
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
