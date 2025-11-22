module vga_display(CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, register_file, PC_value, IR_value, ram);
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
	wire [9:0] VGA_X;
	wire [8:0] VGA_Y;
	wire [8:0] VGA_COLOR;
	input [0:0] KEY;
	input [31:0] register_file [7:0];
	input [31:0] PC_value;    // Program Counter input
	input [31:0] IR_value;    // Instruction Register input
	wire resetn = KEY[0];
	input [31:0] ram [7:0]; 

	// Control wires for title
	wire [9:0] title_x, title_y;
	wire [8:0] title_color;
	wire title_done;
	
	// Control wires for registers
	wire [9:0] regs_x, regs_y;
	wire [8:0] regs_color;
	wire register_done;

	// Control wires for pipeline
	wire [9:0] pipeline_x, pipeline_y;
	wire [8:0] pipeline_color;
	wire pipeline_done;
	
	// Control wires for PC/IR
	wire [9:0] pc_ir_x, pc_ir_y;
	wire [8:0] pc_ir_color;
	wire pc_ir_done;
	
	// Control wires for memory
	wire [9:0] memory_x, memory_y;
	wire [8:0] memory_color;
	wire memory_done;
	
	// Control wires memory title
	wire [9:0] memory_title_x, memory_title_y;
	wire [8:0] memory_title_color;
	wire memory_title_done;
	
	// Control wires pipeline title
	wire [9:0] pipeline_title_x, pipeline_title_y;
	wire [8:0] pipeline_title_color;
	wire pipeline_title_done;
	
	// FSM control for drawing
	reg [3:0] state;
	reg [3:0] next_state;
	parameter DRAW_TITLE = 4'b0001;
	parameter DRAW_REGISTERS = 4'b0010;
	parameter DRAW_PIPELINE = 4'b0011;
	parameter DRAW_PC_IR = 4'b0100;
	parameter DRAW_MEMORY = 4'b0101;
	parameter DRAW_MEMORY_TITLE = 4'b0110;
	parameter DRAW_PIPELINE_TITLE = 4'b0111; 

	// Separate done signal detection
	reg title_done_prev;
	reg register_done_prev;
	reg pipeline_done_prev;
	reg pc_ir_done_prev;
	reg memory_done_prev;
	reg memory_title_done_prev; 
	reg pipeline_title_done_prev; 
	
	always @(posedge CLOCK_50 or negedge resetn) begin
		if (!resetn) begin
			title_done_prev <= 1'b0;
			register_done_prev <= 1'b0;
			pipeline_done_prev <= 1'b0;
			pc_ir_done_prev <= 1'b0;
			memory_done_prev <= 1'b0;
			memory_title_done_prev <= 1'b0;
			pipeline_title_done_prev <= 1'b0; 
		end else begin
			title_done_prev <= title_done;
			register_done_prev <= register_done;
			pipeline_done_prev <= pipeline_done;
			pc_ir_done_prev <= pc_ir_done;
			memory_done_prev <= memory_done; 
			memory_title_done_prev <= memory_title_done; 
			pipeline_title_done_prev <= pipeline_title_done; 
		end
	end

	// Main FSM - State transitions
	always @(posedge CLOCK_50 or negedge resetn) begin
		if (!resetn) begin
			state <= DRAW_TITLE;
		end else begin
			state <= next_state;
		end
	end

	// Next state logic
	always @(*) begin
		case (state)
			DRAW_TITLE: begin
				if (title_done == 1'b1) begin
					next_state = DRAW_REGISTERS;
				end else begin
					next_state = DRAW_TITLE;
				end
			end
			
			DRAW_REGISTERS: begin
				if (register_done == 1'b1) begin
					next_state = DRAW_PIPELINE;
				end else begin
					next_state = DRAW_REGISTERS;
				end
			end
			
			DRAW_PIPELINE: begin
				if (pipeline_done == 1'b1) begin
					next_state = DRAW_PC_IR;
				end else begin
					next_state = DRAW_PIPELINE;
				end
			end
			
			DRAW_PC_IR: begin
				if (pc_ir_done == 1'b1) begin
					next_state = DRAW_MEMORY;
				end else begin
					next_state = DRAW_PC_IR;
				end
			end
			
			DRAW_MEMORY: begin
				if (memory_done == 1'b1) begin
					next_state = DRAW_MEMORY_TITLE;
				end else begin
					next_state = DRAW_MEMORY;
				end
			end
			
			DRAW_MEMORY_TITLE: begin
				if (memory_title_done == 1'b1) begin
					next_state = DRAW_PIPELINE_TITLE;
				end else begin
					next_state = DRAW_MEMORY_TITLE; 
				end
			end
			
			DRAW_PIPELINE_TITLE: begin
				if (pipeline_title_done == 1'b1) begin
					next_state = DRAW_TITLE;
				end else begin
					next_state = DRAW_PIPELINE_TITLE; 
				end
			end
			
			default: begin
				next_state = DRAW_TITLE;
			end
		endcase
	end

	// State-based reset signals
	wire title_local_resetn = resetn && (state == DRAW_TITLE);
	wire register_local_resetn = resetn && (state == DRAW_REGISTERS);
	wire pipeline_local_resetn = resetn && (state == DRAW_PIPELINE);
	wire pc_ir_local_resetn = resetn && (state == DRAW_PC_IR);
	wire memory_local_resetn = resetn && (state == DRAW_MEMORY); 
	wire memory_title_local_resetn = resetn && (state == DRAW_MEMORY_TITLE); 
	wire pipeline_title_resetn = resetn && (state == DRAW_PIPELINE_TITLE); 

	// MUX for output selection
	assign VGA_X = (state == DRAW_TITLE) ? title_x 
					: (state == DRAW_REGISTERS) ? regs_x 
					: (state == DRAW_PIPELINE) ? pipeline_x 
					: (state == DRAW_PC_IR) ? pc_ir_x
					: (state == DRAW_MEMORY) ? memory_x
					: (state == DRAW_MEMORY_TITLE) ? memory_title_x
					: pipeline_title_x; 
	
	assign VGA_Y = (state == DRAW_TITLE) ? title_y 
					: (state == DRAW_REGISTERS) ? regs_y 
					: (state == DRAW_PIPELINE) ? pipeline_y 
					: (state == DRAW_PC_IR) ? pc_ir_y
					: (state == DRAW_MEMORY) ? memory_y
					: (state == DRAW_MEMORY_TITLE) ? memory_title_y
					: pipeline_title_y;
	
	assign VGA_COLOR = (state == DRAW_TITLE) ? title_color 
					: (state == DRAW_REGISTERS) ? regs_color 
					: (state == DRAW_PIPELINE) ? pipeline_color 
					: (state == DRAW_PC_IR) ? pc_ir_color
					: (state == DRAW_MEMORY) ? memory_color
					: (state == DRAW_MEMORY_TITLE) ? memory_title_color
					: pipeline_title_color;
	
	wire [31:0] test_input = 32'hAAAAAAAA;


	// Instantiate all drawing modules
	reg_title_drawer rtd (
		.clock(CLOCK_50), 
		.resetn(title_local_resetn), 
		.title_x(title_x), 
		.title_y(title_y), 
		.title_color(title_color), 
		.title_done(title_done)
	);
	
	register_drawer rd (
		.clock(CLOCK_50), 
		.resetn(register_local_resetn), 
		.regs_x(regs_x), 
		.regs_y(regs_y), 
		.regs_color(regs_color), 
		.register_file(register_file), 
		.register_done(register_done)
	);
	
	pipeline_drawer pd (
		.clock(CLOCK_50), 
		.resetn(pipeline_local_resetn), 
		.IF_PC_VALUE(test_input), 
		.ID_VAL_A(test_input), 
		.EX_ALU_RESULT(test_input), 
		.MEM_DATA_OUT(test_input), 
		.WB_DATA_IN(test_input), 
		.pipeline_x(pipeline_x), 
		.pipeline_y(pipeline_y), 
		.pipeline_color(pipeline_color), 
		.pipeline_done(pipeline_done)
	);
	
	pc_ir_drawer pc_ir (
		.clock(CLOCK_50),
		.resetn(pc_ir_local_resetn),
		.PC_value(PC_value),
		.IR_value(IR_value),
		.pc_ir_x(pc_ir_x),
		.pc_ir_y(pc_ir_y),
		.pc_ir_color(pc_ir_color),
		.pc_ir_done(pc_ir_done)
	);
	
	memory_drawer m_d (
		.clock(CLOCK_50), 
		.resetn(memory_local_resetn), 
		.memory(ram), 
		.memory_x(memory_x), 
		.memory_y(memory_y), 
		.memory_color(memory_color), 
		.memory_done(memory_done)
	); 
	
	memory_title(
		.clock(CLOCK_50), 
		.resetn(memory_title_local_resetn), 
		.vga_x(memory_title_x), 
		.vga_y(memory_title_y), 
		.vga_color(memory_title_color), 
		.done(memory_title_done)
	);
	
	pipeline_title_drawer(
		.clock(CLOCK_50), 
		.resetn(pipeline_title_resetn), 
		.title_x(pipeline_title_x), 
		.title_y(pipeline_title_y), 
		.title_color(pipeline_title_color), 
		.title_done(pipeline_title_done)
	); 

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
	defparam VGA.BACKGROUND_IMAGE = "./bmp_640_9.mif";

endmodule

// Draws out the title above the register
module pipeline_title_drawer(clock, resetn, title_x, title_y, title_color, title_done);
	// Standard inputs
	input clock; 
	input resetn; 
	output wire [9:0] title_x;    // 10-bit X coordinate
   output wire [8:0] title_y;    // 9-bit Y coordinate
   output wire [8:0] title_color; // 9-bit color output
	output wire title_done; 

	// Spelling out title "PIPELINE:"
    wire [7:0] title[0:8]; // 9-character title
    assign title[0] = 8'd25; // P
    assign title[1] = 8'd18;  // I
    assign title[2] = 8'd25; // P
    assign title[3] = 8'd14;  // E
    assign title[4] = 8'd21; // L
    assign title[5] = 8'd18;  // I
    assign title[6] = 8'd23; // N
    assign title[7] = 8'd14;  // E
    assign title[8] = 8'd36; // ':' (example code for colon, adjust to your character map)

    // Keeps track of drawing logic 
    parameter max_chars = 9;
    wire char_drawer_done;
    reg [5:0] char_idx; // 0 -> 8
    reg [2:0] pixel_x;  // 0 -> 7 for character width
    reg [2:0] pixel_y;  // 0 -> 7 for character height

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
    assign title_x = 300 + (char_idx * 9) + pixel_x; 
    assign title_y = 10 + pixel_y; // vertical base

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
    assign title_color = pixel_on ? 9'b111111111 : 9'b000000000;

    // Final analysis for if drawing is done
    assign title_done = char_drawer_done; 

endmodule


module memory_title(clock, resetn, vga_x, vga_y, vga_color, done);

	 input clock;
    input resetn;
    output logic [9:0]  vga_x; 
    output logic [8:0]  vga_y; 
    output logic [8:0]  vga_color; 
    output logic done;

    // Parameters
    parameter num_rows = 2;  // "CPU RAM:" + header row
    parameter chars_per_row = 20; // max characters per row
    parameter max_chars = num_rows * chars_per_row;

    // Pixel tracking
    logic [6:0] char_idx;  // 0 -> max_chars-1
    logic [2:0] pixel_x;
    logic [2:0] pixel_y;
    logic char_drawer_done;

    // Character drawer instance
    char_drawer_logic cdl_inst (
        .clock(clock),
        .resetn(resetn),
        .char_count(max_chars),
        .done(char_drawer_done),
        .char_idx(char_idx),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // Determine row and position
    wire [3:0] row_num = char_idx / chars_per_row;
    wire [4:0] char_in_row = char_idx % chars_per_row;

    // Character code
    wire [7:0] char_code;

    always @ (posedge clock) begin
        case (row_num)
            0: begin
                // Row 0: "CPU RAM:"
                case (char_in_row)
                    0: char_code = 8'd12; // C
                    1: char_code = 8'd25; // P 
                    2: char_code = 8'd30; // U
                    3: char_code = 8'd37; // space
                    4: char_code = 8'd27; // R
                    5: char_code = 8'd10; // A
                    6: char_code = 8'd22; // M
                    7: char_code = 8'd36; // :
                    default: char_code = 8'd37;
                endcase
            end
            1: begin
                // Row 1: "    +0 +1 +2 +3"
                case (char_in_row)
                    0,1,2,3: char_code = 8'd37; // leading spaces
                    4: char_code = 8'd38; // +
                    5: char_code = 8'd0; // 0 
                    6: char_code = 8'd37; // space
                    7: char_code = 8'd38; // +
                    8: char_code = 8'd1; // 1
                    9: char_code = 8'd37; // space
                    10: char_code = 8'd38; // + 
                    11: char_code = 8'd2; // 2
                    12: char_code = 8'd37; // space
                    13: char_code = 8'd38; // + 
                    14: char_code = 8'd3; // 3 
                    default: char_code = 8'd37; // space
                endcase
            end
            default: char_code = " ";
        endcase
    end

    // Character bitmap
    logic [63:0] pixelLine;
    character bmp_inst (
        .digit(char_code),
        .pixelLine(pixelLine)
    );

    // Map pixel coordinates
    assign vga_x = 15 + (char_in_row * 9) + pixel_x;
    assign vga_y = 310 + (row_num * 15) + pixel_y;

    // Pixel color
    logic [7:0] pixels [7:0];
    assign pixels[0] = pixelLine[7:0];
    assign pixels[1] = pixelLine[15:8];
    assign pixels[2] = pixelLine[23:16];
    assign pixels[3] = pixelLine[31:24];
    assign pixels[4] = pixelLine[39:32];
    assign pixels[5] = pixelLine[47:40];
    assign pixels[6] = pixelLine[55:48];
    assign pixels[7] = pixelLine[63:56];

    assign vga_color = pixels[pixel_y][7-pixel_x] ? 9'b111111111 : 9'b000000000;

    // Done signal
    assign done = char_drawer_done;

endmodule

// Draws memory contents on screen
// Format: 0: 00 00 00 00 (8 rows)
module memory_drawer(clock, resetn, memory, memory_x, memory_y, memory_color, memory_done);
	// Standard inputs
	input clock; 
	input resetn;
	input [31:0] memory [7:0];  // 8 memory locations, 32-bit each
	
	// Outputs
	output wire [9:0] memory_x;     // 10-bit X coordinate
	output wire [8:0] memory_y;     // 9-bit Y coordinate
	output wire [8:0] memory_color; // 9-bit color output
	output wire memory_done;
	
	// Logic for tracking address's 
	wire [7:0] addr = row_num * 4;
	wire [3:0] addr_high = addr[7:4]; // Second digit
	wire [3:0] addr_low  = addr[3:0]; // First digit
	
	// 15 * 8 charcters 
	parameter chars_per_row = 15;
	parameter num_rows = 8;
	parameter max_chars = chars_per_row * num_rows; // 112
	
	wire char_drawer_done;
	reg [6:0] char_idx; // 0->111
	reg [2:0] pixel_x;  // 0->7 for character width
	reg [2:0] pixel_y;  // 0->7 for character height
	
	char_drawer_logic cdl_inst (
		.clock(clock), 
		.resetn(resetn), 
		.char_count(max_chars), 
		.done(char_drawer_done), 
		.char_idx(char_idx), 
		.pixel_x(pixel_x), 
		.pixel_y(pixel_y)
	);
	
	// Determine which row and position within row
	wire [3:0] row_num = char_idx / chars_per_row;      // 0-7 (which row)
	wire [3:0] char_in_row = char_idx % chars_per_row;  // 0-13 (position in row)
	
	// Get current 32-bit memory value for this row
	wire [31:0] current_mem = memory[row_num];
	
	// Build character code for this position
	// Layout: "00: 00 00 00 00"
	// Positions: 0-1 = address (FF), 2 = :, 3 = space
	
	wire [7:0] char_code;
	
	always @(*) begin
		case (char_in_row)
			// Address bytes (FF, FE, FD, ... F8)
			0: char_code = addr_high; // First F in address
			1: char_code = addr_low; // Second hex digit of address
			
			2: char_code = 8'd36; // ':'
			3: char_code = 8'd37; // space
			
			// Byte 0 (bits 31:24)
			4: char_code = current_mem[31:28];
			5: char_code = current_mem[27:24];
			6: char_code = 8'd37; // space
			
			// Byte 1 (bits 23:16)
			7: char_code = current_mem[23:20];
			8: char_code = current_mem[19:16];
			9: char_code = 8'd37; // space
			
			// Byte 2 (bits 15:8)
			10: char_code = current_mem[15:12];
			11: char_code = current_mem[11:8];
			12: char_code = 8'd37; // space
			
			// Byte 3 (bits 7:0)
			13: char_code = current_mem[7:4];
			14: char_code = current_mem[3:0];
			
			default: char_code = 8'd37; // space
		endcase
	end
	
	// Get character bitmap
	wire [63:0] pixelLine;
	character bmp_inst (
		.digit(char_code),
		.pixelLine(pixelLine)
	);
	
	// Each character is 8 pixels wide, with 1 pixel spacing
	// Start at X=300, Y=200
	assign memory_x = 15 + (char_in_row * 9) + pixel_x;
	assign memory_y = 340 + (row_num * 15) + pixel_y;
	
	// Decode pixel data
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
	assign memory_color = pixel_on ? 9'b111111111 : 9'b000000000;
	
	// Final analysis for if drawing is done
	assign memory_done = char_drawer_done;

endmodule


// Draws PC: [32-bit value] and IR: [32-bit value] on screen
module pc_ir_drawer(clock, resetn, PC_value, IR_value, pc_ir_x, pc_ir_y, pc_ir_color, pc_ir_done);
	// Standard inputs
	input clock; 
	input resetn;
	input [31:0] PC_value; // Program Counter 32-bit value
	input [31:0] IR_value; // Instruction Register 32-bit value
	
	// Outputs
	output wire [9:0] pc_ir_x; // 10-bit X coordinate
	output wire [8:0] pc_ir_y; // 9-bit Y coordinate
	output wire [8:0] pc_ir_color; // 9-bit color output
	output wire pc_ir_done;
	
	// Character array: "PC: " (4 chars) + 8 hex digits + "IR: " (4 chars) + 8 hex digits = 24 total
	// PC line: P C : space [8 hex]
	// IR line: I R : space [8 hex]
	wire [7:0] pc_line[0:11];   // "PC: " + 8 hex digits
	wire [7:0] ir_line[0:11];   // "IR: " + 8 hex digits
	
	// PC Label: "PC: "
	assign pc_line[0] = 8'd25; // P
	assign pc_line[1] = 8'd12; // C
	assign pc_line[2] = 8'd36; // :
	assign pc_line[3] = 8'd37; // space
	
	// IR Label: "IR: "
	assign ir_line[0] = 8'd18; // I
	assign ir_line[1] = 8'd27; // R
	assign ir_line[2] = 8'd36; // :
	assign ir_line[3] = 8'd37; // space
	
	// Keeps track of drawing logic
	parameter max_chars = 24; // 2 lines * 12 chars per line
	wire char_drawer_done;
	reg [5:0] char_idx; // 0->23
	reg [2:0] pixel_x;  // 0->7 for character width
	reg [2:0] pixel_y;  // 0->7 for character height
	
	char_drawer_logic cdl_inst (
		.clock(clock), 
		.resetn(resetn), 
		.char_count(max_chars), 
		.done(char_drawer_done), 
		.char_idx(char_idx), 
		.pixel_x(pixel_x), 
		.pixel_y(pixel_y)
	);
	
	// Determine which line and position within line
	wire [4:0] line_num = char_idx / 12;      // 0 = PC line, 1 = IR line
	wire [3:0] char_in_line = char_idx % 12;  // 0-11 within each line
	
	// Select current 32-bit value based on which line
	wire [31:0] current_value = (line_num == 0) ? PC_value : IR_value;
	
	// Select label or hex digit
	wire [7:0] char_code;
	assign char_code = (char_in_line < 4) ? 
		((line_num == 0) ? pc_line[char_in_line] : ir_line[char_in_line]) :
		hex_to_char(current_value[(31 - (char_in_line - 4) * 4) -: 4]);
	
	// Function to convert 4-bit hex to character code
	function [7:0] hex_to_char(input [3:0] hex_digit);
		begin
			if (hex_digit < 10) begin
				hex_to_char = 8'd0 + hex_digit;        // 0-9 map to char codes 0-9
			end else begin
				hex_to_char = 8'd10 + (hex_digit - 10); // A-F map to char codes 10-15
			end
		end
	endfunction
	
	// Get character bitmap
	wire [63:0] pixelLine;
	character bmp_inst (
		.digit(char_code),
		.pixelLine(pixelLine)
	);
	
	// Each character is 8 pixels wide, with 1 pixel spacing
	// PC line at Y=150, IR line at Y=165
	assign pc_ir_x = 10 + (char_in_line * 9) + pixel_x;
	assign pc_ir_y = 250 + (line_num * 15) + pixel_y;
	
	// Decode pixel data
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
	assign pc_ir_color = pixel_on ? 9'b111111111 : 9'b000000000;
	
	// Final analysis for if drawing is done
	assign pc_ir_done = char_drawer_done;

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

	 // Drawing parameters
	 localparam NUM_STAGES = 5;
    localparam LABEL_WIDTH = 5; // e.g., "IF://"
    localparam DATA_WIDTH = 8;  // 8 hex digits DATA_WIDTH(32 bits)
    localparam CHARS_PER_LINE = LABEL_WIDTH + DATA_WIDTH; // 13
    localparam MAX_CHARS = NUM_STAGES * CHARS_PER_LINE; // 65
    
    localparam START_X = 300;
    localparam START_Y = 25;
    localparam CHAR_SPACING = 9; // 8 pixels + 1 spacing
    localparam LINE_HEIGHT = 10; // 8 pixels + 2 spacing
    
    localparam LABEL_COLOR = 9'b111000000; // Bright Red
    localparam DATA_COLOR  = 9'b000111000; // Bright Green
    localparam BACKGROUND_COLOR = 9'b000000000; // Black
	
    // Wires from Character Logic ---
    wire char_drawer_done;
    wire [7:0] char_idx; // Needs to be wide enough for MAX_CHARS (55)
    wire [2:0] pixel_x;
    wire [2:0] pixel_y;
    
    // Drawing State Variables
    wire [2:0] stage_index; // Current stage being drawn (0 to 4)
    wire [3:0] char_line_idx; // Current char position within the 11-char line (0 to 10)
    wire [31:0] current_value; // The 32-bit value being displayed
    
    // Stage Index and Character Position
    assign stage_index = char_idx / CHARS_PER_LINE; // 0-IF, 1-ID, 2-EX, 3-MEM, 4-WB
    assign char_line_idx = char_idx % CHARS_PER_LINE; // 0-2 for label, 3-10 for data

    // Instantiate drawing logic 
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
    assign pipeline_done = char_drawer_done;

    // Select the 32-bit value corresponding to the current drawing stage
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
    
    // Stage names: IF, ID, EX, MEM, WB
    wire [7:0] stage_labels[0:4][0:4]; // [Stage][Char]
	// 5 stages, 4 characters each, 8 
    
    // Stage 0: IF
    assign stage_labels[0][0] = 8'd18; // 'I'
    assign stage_labels[0][1] = 8'd15; // 'F'
	 assign stage_labels[0][2] = 8'd36; // ':'
    assign stage_labels[0][3] = 8'd37; // ' '
	 assign stage_labels[0][4] = 8'd37; // ' '
    // Stage 1: ID
    assign stage_labels[1][0] = 8'd18; // 'I'
    assign stage_labels[1][1] = 8'd13; // 'D'
	 assign stage_labels[1][2] = 8'd36; // ':'
    assign stage_labels[1][3] = 8'd37; // ' '
	 assign stage_labels[1][4] = 8'd37; // ' '
    
	// Stage 2: EX
    assign stage_labels[2][0] = 8'd14; // 'E'
    assign stage_labels[2][1] = 8'd33; // 'X'
    assign stage_labels[2][2] = 8'd36; // ':'
	 assign stage_labels[2][3] = 8'd37; // ' '
	 assign stage_labels[2][4] = 8'd37; // ' '

    // Stage 3: MEM
    assign stage_labels[3][0] = 8'd22; // 'M'
    assign stage_labels[3][1] = 8'd14; // 'E'
    assign stage_labels[3][2] = 8'd22; // 'M'
	 assign stage_labels[3][3] = 8'd36; // ':'
	 assign stage_labels[3][4] = 8'd37; // ' '
    
	// Stage 4: WB
    assign stage_labels[4][0] = 8'd32; // 'W'
    assign stage_labels[4][1] = 8'd11; // 'B'
	assign stage_labels[4][2] = 8'd36; // ':'
    assign stage_labels[4][3] = 8'd37; // ' '
	assign stage_labels[4][4] = 8'd37; // ' '
	
	

    // --- Character ROM Input Selection ---
    wire [7:0] char_ascii; // ASCII code of the character to draw
    
    // Determine the character based on whether we are drawing the label (0-2) or the data (3-10)
    always @(*) begin
        if (char_line_idx < LABEL_WIDTH) begin
            // Drawing the Label (Static)
            char_ascii = stage_labels[stage_index][char_line_idx];
        end else begin
            // Drawing the Data (Dynamic Hex)
            char_ascii = current_value[(DATA_WIDTH - 1 - (char_line_idx - LABEL_WIDTH)) * 4 +: 4]; // Extract 4 bits
        end
    end
    
    // --- Instantiate the Character ROM ---
    wire [63:0] pixelLine;
    character bmp_inst (
        .digit(char_ascii),
        .pixelLine(pixelLine)
    );

    // X/Y Calculation
    assign pipeline_x = 300 + (char_line_idx * 9) + pixel_x; 
    assign pipeline_y = 25 + (stage_index * 15) + pixel_y; 

    // Pixel decoding and Color Assignment
    wire [7:0] current_row = pixelLine[(pixel_y * 8) +: 8]; 
    wire pixel_on = current_row[7 - pixel_x];
    
    assign pipeline_color = pixel_on ? 9'b111111111 : 3'b000;

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
	wire [7:0] title[0:16]; // 16-character title
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
	assign title[16] = 8'd28; // S

	// Keeps track of drawing logic 
	parameter max_chars = 17;
	wire char_drawer_done;
	reg [5:0] char_idx; // 0->16
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
	assign title_color = pixel_on ? 9'b111111111 : 9'b000000000;

	// Final analysis for if drawing is done
	assign title_done = char_drawer_done; 
endmodule 

module char_drawer_logic(clock, resetn, char_count, done, char_idx, pixel_x, pixel_y); 
	input clock; 
    input resetn; 
    input [7:0] char_count; // Max number 128
    output reg done;        // Set high when all characters are drawn
    output reg [6:0] char_idx; // Current character index (0 to CHAR_COUNT-1)
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
					 done <= 1'b0; 
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
	 output reg register_done; 
    
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
    assign column_values[4] = curRegister[31:28]; // A
	 assign column_values[5] = curRegister[27:24]; // A
	 assign column_values[6] = curRegister[23:20]; // A
	 assign column_values[7] = curRegister[19:16]; // A
	 assign column_values[8] = curRegister[15:12]; // 0
	 assign column_values[9] = curRegister[11:8]; // 0
	 assign column_values[10] = curRegister[7:4]; // 0
	 assign column_values[11] = curRegister[3:0]; // 1
    
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
	 assign regs_color = pixel_on ? 9'b111111111 : 9'b000000000;

	 // Display pixels in white
    always_ff @(posedge clock or negedge resetn) begin
		 if (!resetn) begin
			  register_done <= 0;
		 end else begin
			  if (finishedCharacter && row_idx == 7 && col_idx == 11) begin
					register_done <= 1'b1;
			  end else begin
					register_done <= 1'b0;
			  end
		 end
	end

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
					pixels[1] = 8'b10000001;
					pixels[2] = 8'b10000001;
					pixels[3] = 8'b10000001;
					pixels[4] = 8'b10011001;
					pixels[5] = 8'b10011001;
					pixels[6] = 8'b10100101;
					pixels[7] = 8'b10100101;
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
				38: begin // +
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b00001000;
					pixels[2] = 8'b00001000;
					pixels[3] = 8'b00001000;
					pixels[4] = 8'b01111111;
					pixels[5] = 8'b00001000;
					pixels[6] = 8'b00001000;
					pixels[7] = 8'b00001000;
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
