// top.v - DESim VGA Demo (Corrected Logic)
// This file contains all modules, with corrected signal and logic flows.

// Top-level module for DESim board
module vga_display(CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, register_file);
	// Input ports
	input CLOCK_50;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;
	wire [9:0] VGA_X; // Previously 8:0
	wire [8:0] VGA_Y; // Previously 7:0 
	wire [8:0] VGA_COLOR; 
	input [1:1] KEY; 
	input [31:0] register_file [7:0]; 
	wire resetn = KEY[1]; 

	// Control wires
	wire [9:0] title_x, title_y; // For title drawing
	wire [8:0] title_color;  
	wire title_done; 
	
	wire [9:0] regs_x, regs_y; // For register drawing 
	wire [8:0] regs_color;
	wire register_done; 

	wire [9:0] pipeline_x, pipeline_y; // For pipeline drawing
	wire [8:0] pipeline_color; 
	wire pipeline_done; 
	
	// FSM control for drawing 
	reg[1:0] state; 
	parameter DRAW_TITLE = 3'b001;
	parameter DRAW_REGISTERS = 3'b010; 
	parameter DRAW_PIPELINE = 3'b100; 

	// Title -> Register -> Pipeline drawing
	always @(posedge CLOCK_50) begin
		if (!resetn) begin
			state <= DRAW_TITLE; 
		end
		case (state) 
			DRAW_TITLE: begin
				if (title_done) begin
					state <= DRAW_REGISTERS; 
				end
			end
			DRAW_REGISTERS: begin  
				if (register_done) begin
					state <= DRAW_REGISTERS; 	 
				end
			end
			DRAW_PIPELINE: begin
				if (pipeline_done) begin
					state <= DRAW_REGISTERS; 
				end
			end
			default: state <= DRAW_TITLE; 
		endcase
	end

	// Selects which pointer to follow based off of FSM
	assign VGA_X = (state == DRAW_TITLE) ? title_x : regs_x;
	assign VGA_Y = (state == DRAW_TITLE) ? title_y : regs_y;
	assign VGA_COLOR = (state == DRAW_TITLE) ? title_color : regs_color;
	
	wire [31:0] test_input 8'hAAAAAAAA; 

	reg_title_drawer rtd (CLOCK_50, resetn, title_x, title_y, title_color, title_done); 
   register_drawer rd (CLOCK_50, resetn, regs_x, regs_y, regs_color, register_file, register_done); // Primary writer for displays 
	pipeline_drawer(CLOCK_50, resetn, test_input, test_input, test_input, test_input, test_input, pipeline_x, pipeline_y, pipeline_color, pipeline_done);
   vga_adapter VGA (
		.resetn(resetn),
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

module pipeline_drawer(clock, resetn, IF_PC_VALUE, ID_VAL_A, EX_ALU_RESULT, MEM_DATA_OUT, WB_DATA_IN, pipeline_x, pipeline_y, pipeline_color, pipeline_done); 
	 input clock;  
    input resetn; 
    
    // Data from control unit (example registers)
    input [31:0] IF_PC_VALUE; 
    input [31:0] ID_VAL_A; 
    input [31:0] EX_ALU_RESULT;
    input [31:0] MEM_DATA_OUT;
    input [31:0] WB_DATA_IN;
    
    // VGA output coordinates and color
    output wire [9:0] pipeline_x;    // 10-bit X coordinate
    output wire [8:0] pipeline_y;    // 9-bit Y coordinate
    output wire [8:0] pipeline_color; // 9-bit color output
    output wire pipeline_done; // Set high when all drawing is complete

	 localparam NUM_STAGES = 5;
    localparam LABEL_WIDTH = 3; // e.g., "IF "
    localparam DATA_WIDTH = 8;  // 8 hex digits (32 bits)
    localparam CHARS_PER_LINE = LABEL_WIDTH + DATA_WIDTH; // 11
    localparam MAX_CHARS = NUM_STAGES * CHARS_PER_LINE; // 55
    
    localparam START_X = 300;
    localparam START_Y = 150;
    localparam CHAR_SPACING = 9; // 8 pixels + 1 spacing
    localparam LINE_HEIGHT = 10; // 8 pixels + 2 spacing
    
    localparam LABEL_COLOR = 9'b111000000; // Bright Red
    localparam DATA_COLOR  = 9'b000111000; // Bright Green
    localparam BACKGROUND_COLOR = 9'b000000000; // Black

    // --- Wires from Character Logic ---
    wire char_drawer_done;
    wire [5:0] char_idx; // Needs to be wide enough for MAX_CHARS (55)
    wire [2:0] pixel_x;
    wire [2:0] pixel_y;
    
    // --- Drawing State Variables ---
    wire [2:0] stage_index; // Current stage being drawn (0 to 4)
    wire [3:0] char_line_idx; // Current char position within the 11-char line (0 to 10)
    wire [31:0] current_value; // The 32-bit value being displayed
    
    // Stage Index and Character Position
    assign stage_index = char_idx / CHARS_PER_LINE; // 0-IF, 1-ID, 2-EX, 3-MEM, 4-WB
    assign char_line_idx = char_idx % CHARS_PER_LINE; // 0-2 for label, 3-10 for data

    // --- Instantiate Reusable Logic ---
    char_drawer_logic cdl_inst (
        .clock(clock), 
        .resetn(resetn), 
        .char_count(MAX_CHARS), 
        .done(char_drawer_done), 
        .char_idx(char_idx), 
        .pixel_x(pixel_x), 
        .pixel_y(pixel_y)
    );

	// Connect done signal
    assign pipe_done = char_drawer_done;

    // --- Data Selection Logic ---
    // Select the 32-bit value corresponding to the current stage
    always @(*) begin
        case (stage_index)
            3'd0: current_value = IF_PC_VALUE;
            3'd1: current_value = ID_VAL_A;
            3'd2: current_value = EX_ALU_RESULT;
            3'd3: current_value = MEM_DATA_OUT;
            3'd4: current_value = WB_DATA_IN;
            default: current_value = 32'hDEADBEEF; // Error/Default
        endcase
    end
    
    // --- Stage Label Definitions (ASCII values) ---
    // Stage names: IF, ID, EX, MEM, WB
    wire [7:0] stage_labels[0:4][0:2]; // [Stage][Char]
    
    // Stage 0: IF
    assign stage_labels[0][0] = 8'h49; // 'I'
    assign stage_labels[0][1] = 8'h46; // 'F'
    assign stage_labels[0][2] = 8'h20; // ' '
    // Stage 1: ID
    assign stage_labels[1][0] = 8'h49; // 'I'
    assign stage_labels[1][1] = 8'h44; // 'D'
    assign stage_labels[1][2] = 8'h20; // ' '
    // Stage 2: EX
    assign stage_labels[2][0] = 8'h45; // 'E'
    assign stage_labels[2][1] = 8'h58; // 'X'
    assign stage_labels[2][2] = 8'h20; // ' '
    // Stage 3: MEM
    assign stage_labels[3][0] = 8'h4D; // 'M'
    assign stage_labels[3][1] = 8'h45; // 'E'
    assign stage_labels[3][2] = 8'h4D; // 'M'
    // Stage 4: WB
    assign stage_labels[4][0] = 8'h57; // 'W'
    assign stage_labels[4][1] = 8'h42; // 'B'
    assign stage_labels[4][2] = 8'h20; // ' '

    // --- Character ROM Input Selection ---
    wire [7:0] char_ascii; // ASCII code of the character to draw
    
    // Determine the character based on whether we are drawing the label (0-2) or the data (3-10)
    always @(*) begin
        if (char_line_idx < LABEL_WIDTH) begin
            // Drawing the Label (Static)
            char_ascii = stage_labels[stage_index][char_line_idx];
        end else begin
            // Drawing the Data (Dynamic Hex)
            // char_line_idx runs from 3 to 10 (8 hex digits). Index 3 draws the MSB (byte 7)
            // We use the full 32-bit value to get the correct hex digit
            char_ascii = current_value[(DATA_WIDTH - 1 - (char_line_idx - LABEL_WIDTH)) * 4 +: 4];
            
            // This 4-bit value needs to be converted to ASCII hex (0-9, A-F)
            // Assuming you have a separate hex_to_ascii module or logic.
            // For now, let's assume the hex_to_ascii conversion is done in the character module
            // or handled by a separate conversion module (which is best practice).
            // Lacking that module, let's assume 'character' can convert 4 bits to ASCII hex,
            // or we will hardcode the conversion here:
            case (char_ascii)
                4'h0: char_ascii = 8'h30; // '0'
                4'h1: char_ascii = 8'h31; // '1'
                // ... fill in 4'h2 to 4'h9
                4'ha: char_ascii = 8'h41; // 'A'
                // ... fill in 4'hb to 4'hf
                default: char_ascii = 8'h3F; // '?' (Fallback)
            endcase
        end
    end
    
    // --- Instantiate the Character ROM ---
    wire [63:0] pixelLine;
    character bmp_inst (
        .digit(char_ascii),
        .pixelLine(pixelLine)
    );

    // --- Coordinate and Color Generation ---

    // X/Y Calculation
    assign pipeline_x = 300 + (char_line_idx * 9) + pixel_x; 
    assign pipeline_y = 25 + (stage_index * 15) + pixel_y; 

    // Pixel decoding and Color Assignment
    wire [7:0] current_row = pixelLine[(pixel_y * 8) +: 8]; 
    wire pixel_on = current_row[7 - pixel_x];
    
    assign pipe_color = pixel_on ? 9'b111111111 : 3'b000;

endmodule

// Draws out the title above the register
module reg_title_drawer(clock, resetn, title_x, title_y, title_color, title_done);
	// Standard inputs
	input clock; 
	input resetn; 
	output wire [9:0] title_x;    // 10-bit X coordinate
   output wire [8:0] title_y;    // 9-bit Y coordinate
   output wire [8:0] title_color; // 9-bit color output
	output wire title_done; 

	// Spelling out title
	wire [7:0] title[0:15]; // 16-character title
	assign title[0] = 8'd16; // G
	assign title[1] = 8'd14; // E
	assign title[2] = 8'd23; // N
	assign title[3] = 8'd14; // E
	assign title[4] = 8'd27; // R
	assign title[5] = 8'd10; // A
	assign title[6] = 8'd21; // L
	assign title[7] = 8'd37; // space
	assign title[8] = 8'd27; // R
	assign title[9] = 8'd14; // E
	assign title[10] = 8'd16; // G
	assign title[11] = 8'd18; // I
	assign title[12] = 8'd28; // S
	assign title[13] = 8'd29; // T
	assign title[14] = 8'd14; // E
	assign title[15] = 8'd27; // R

	// Keeps track of drawing logic 
	parameter max_chars = 16; 
	wire char_drawer_done;
	reg [4:0] char_idx; // 0->15
	reg [2:0] pixel_x; // 0->7 for character width 
    reg [2:0] pixel_y; // 0->7 for character height
	char_drawer_logic cdl_inst (
        .clock(clock), 
        .resetn(resetn), 
        .char_count(max_chars), 
        .done(char_drawer_done), 
        .char_idx(char_idx), 
        .pixel_x(pixel_x), 
        .pixel_y(pixel_y)
    );
	
	wire [63:0] pixelLine;
	character bmp_inst (
		.digit(title[char_idx]),
		.pixelLine(pixelLine)
	);

	// Each character is 8 pixels wide, with 1 pixel spacing
	assign title_x = 10 + (char_idx * 9) + pixel_x; 
	assign title_y = 10 + pixel_y; // You can set the vertical base

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
	assign title_color = pixel_on ? 9'b111111111 : 3'b000;

	// Final analysis for if drawing is done
	assign title_done = char_drawer_done; 
endmodule 

module char_drawer_logic(clock, resetn, char_count, done, char_idx, done, pixel_x, pixel_y); 
	input clock; 
    input resetn; 
    input [4:0] char_count; // Max number of characters to draw (e.g., 16)
    output reg done;        // Set high when all characters are drawn
    output reg [4:0] char_idx; // Current character index (0 to CHAR_COUNT-1)
    output reg [2:0] pixel_x;  // Current pixel column (0 to 7)
    output reg [2:0] pixel_y;   // Current pixel row (0 to 7)

	// Draws out the title 
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            pixel_x <= 0;
            pixel_y <= 0;
            char_idx <= 0;
            done <= 1'b0;
        end else begin
            // Clear done signal at the start of a cycle
            done <= 1'b0;
            
            if (char_idx == char_count) begin
                // If we've drawn all characters, set done and reset
                done <= 1'b1;
                pixel_x <= 0;
                pixel_y <= 0;
                char_idx <= 0;
            end else begin
                // Iterate through X pixels (0 -> 7)
                if (pixel_x == 7) begin 
                    pixel_x <= 0;
                    // Iterate through Y pixels (0 -> 7)
                    if (pixel_y == 7) begin
                        pixel_y <= 0;
                        // Iterate through characters (0 -> CHAR_COUNT-1)
                        char_idx <= char_idx + 1;
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

// Generates the (X, Y) coordinates, 3-bit color, and write pulse (plot).
module register_drawer(clock, resetn, regs_x, regs_y, regs_color, register_file, register_done);
    input wire clock; 
    input wire resetn;
	input [31:0] register_file [7:0]; 
	output register_done; 
    
    // Outputs to VGA Adapter
    output wire [9:0] regs_x;    // Corrected width to 10 bits (0-639)
    output wire [8:0] regs_y;    // Used to be 9:0
    output wire [8:0] regs_color; // 9-bit color output

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
    assign regs_x = 10 + (col_idx * 9) + pixel_x; 
    
    // Y position: Start at base row coordinate, offset by inner pixel y
    assign regs_y = y_coordinate[row_idx] + pixel_y; 

    wire pixel_on;
    assign pixel_on = pixels[pixel_y][7-pixel_x];

	 // Display pixels in white
    assign regs_color = pixel_on ? 9'b111111111 : 3'b000;
	 assign register_done = (row_idx == 7 && col_idx == 11); 

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

				16: begin // G
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b11110000;
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
				36: begin // :
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
