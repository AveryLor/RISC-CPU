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
	
	// Control wires for drawing the log out
	wire [9:0] log_x, log_y;
	wire [8:0] log_color;
	wire log_done;
	
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
	parameter DRAW_LOG = 4'b1000; 

	// Separate done signal detection
	reg title_done_prev;
	reg register_done_prev;
	reg pipeline_done_prev;
	reg pc_ir_done_prev;
	reg memory_done_prev;
	reg memory_title_done_prev; 
	reg pipeline_title_done_prev; 
	reg log_done_prev; 

	always @(posedge CLOCK_50 or negedge resetn) begin
		if (!resetn) begin
			title_done_prev <= 1'b0;
			register_done_prev <= 1'b0;
			pipeline_done_prev <= 1'b0;
			pc_ir_done_prev <= 1'b0;
			memory_done_prev <= 1'b0;
			memory_title_done_prev <= 1'b0;
			pipeline_title_done_prev <= 1'b0; 
		   log_done_prev <= 1'b0; 
		end else begin
			title_done_prev <= title_done;
			register_done_prev <= register_done;
			pipeline_done_prev <= pipeline_done;
			pc_ir_done_prev <= pc_ir_done;
			memory_done_prev <= memory_done; 
			memory_title_done_prev <= memory_title_done; 
			pipeline_title_done_prev <= pipeline_title_done; 
			log_done_prev <= log_done; 
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
			
//			DRAW_LOG: begin
//				if (log_done == 1'b1) begin
//					next_state = DRAW_TITLE;
//				end else begin
//					next_state = DRAW_LOG; 
//				end
//			end
			
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
	wire log_resetn = resetn && (state == DRAW_LOG); 

	// MUX for output selection
//	assign VGA_X = (state == DRAW_TITLE) ? title_x 
//					: (state == DRAW_REGISTERS) ? regs_x 
//					: (state == DRAW_PIPELINE) ? pipeline_x 
//					: (state == DRAW_PC_IR) ? pc_ir_x
//					: (state == DRAW_MEMORY) ? memory_x
//					: (state == DRAW_MEMORY_TITLE) ? memory_title_x
//					: (state == DRAW_PIPELINE_TITLE) ? pipeline_title_x
//					: log_x; 
//	
//	assign VGA_Y = (state == DRAW_TITLE) ? title_y 
//					: (state == DRAW_REGISTERS) ? regs_y 
//					: (state == DRAW_PIPELINE) ? pipeline_y 
//					: (state == DRAW_PC_IR) ? pc_ir_y
//					: (state == DRAW_MEMORY) ? memory_y
//					: (state == DRAW_MEMORY_TITLE) ? memory_title_y
//					: (state == DRAW_PIPELINE_TITLE) ? pipeline_title_y
//					: log_y;
//	
//	assign VGA_COLOR = (state == DRAW_TITLE) ? title_color 
//					: (state == DRAW_REGISTERS) ? regs_color 
//					: (state == DRAW_PIPELINE) ? pipeline_color 
//					: (state == DRAW_PC_IR) ? pc_ir_color
//					: (state == DRAW_MEMORY) ? memory_color
//					: (state == DRAW_MEMORY_TITLE) ? memory_title_color
//					: (state == DRAW_PIPELINE_TITLE) ? pipeline_title_color
//					: log_color;

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
	
	// First command: ADD R1, R2
	wire [31:0] test_input1 = 32'b00100100000001000000000000000000;  // ADD R1, r1, r5 (for MIPS)

	// Second command: INC R1
	wire [31:0] test_input2 = 32'b00101000000000010000000000000000;  // SUB R1, R1, R2 (for MIPS)
	// R1 = 21, 20, 19
	// R2 = 18, 17, 16
	
	wire [31:0] test_input3 = 32'b11001100000110000000000000111010;  // SUB R1, R1, R2 (for MIPS)
	
	wire [31:0] test_input4 = 32'b01100110000000000000000000000000;  // SUB R1, R1, R2 (for MIPS)
	
	wire [31:0] test_input5 = 32'b11110001000000000011111111111111;  // SUB R1, R1, R2 (for MIPS)

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
		.IF_PC_VALUE(test_input1), 
		.ID_VAL_A(test_input2), 
		.EX_ALU_RESULT(test_input3), 
		.MEM_DATA_OUT(test_input4), 
		.WB_DATA_IN(test_input5), 
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
	
//	instruction_log_drawer ild(
//		.clock(CLOCK_50),
//		.resetn(log_resetn), 
//		.WB_instruction(32'hAAAAAAAA), 
//		.WB_valid(1'b0), 
//		.log_x(log_x), 
//		.log_y(log_y), 
//		.log_color(log_color), 
//		.log_done(log_done)
//	); 

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
//
//// Instruction Log Drawer - Displays WB stage instructions as a scrolling log
//// Shows last 10 instructions with the latest in red, older ones in white
//// When log is full, new instructions overwrite oldest ones
//module instruction_log_drawer(clock, resetn, WB_instruction, WB_valid, log_x, log_y, log_color, log_done);
//	// Inputs
//	input clock;
//	input resetn;
//	input [31:0] WB_instruction;  // 32-bit instruction from WB stage
//	input WB_valid;                // Pulsed high when new instruction enters WB
//	
//	// Outputs
//	output wire [9:0] log_x;
//	output wire [8:0] log_y;
//	output wire [8:0] log_color;
//	output wire log_done;
//	
//	// ===== CIRCULAR BUFFER FOR INSTRUCTION LOG =====
//	reg [31:0] instruction_buffer [9:0];  // Stores last 10 instructions (0 = oldest, 9 = newest)
//	reg [3:0] buffer_head;                // Points to next write location (0-9)
//	reg [3:0] current_instr_idx;          // Index of current instruction being drawn
//	
//	integer i;
//	
//	// Initialize buffer
//	initial begin
//		for (i = 0; i < 10; i = i + 1) begin
//			instruction_buffer[i] = 32'h00000000;
//		end
//		buffer_head = 4'd0;
//	end
//	
//	// ===== UPDATE BUFFER WHEN NEW INSTRUCTION ARRIVES =====
//	always @(posedge clock or negedge resetn) begin
//		if (!resetn) begin
//			buffer_head <= 4'd0;
//			for (i = 0; i < 10; i = i + 1) begin
//				instruction_buffer[i] <= 32'h00000000;
//			end
//		end else if (WB_valid) begin
//			// Store new instruction at head position
//			instruction_buffer[buffer_head] <= WB_instruction;
//			
//			// Increment head (circular)
//			if (buffer_head == 4'd9) begin
//				buffer_head <= 4'd0;
//			end else begin
//				buffer_head <= buffer_head + 1'b1;
//			end
//		end
//	end
//	
//	// ===== CHARACTER DRAWING LOGIC =====
//	// Each instruction displays as: "[RED ARROW] XXXXXXXX" (16 chars per row)
//	// 10 instructions total = 160 characters
//	
//	parameter chars_per_instruction = 16;  // "►" (1 char) + space (1) + 8 hex (8) + 6 spaces = 16 total
//	parameter num_instructions = 10;
//	parameter max_chars = chars_per_instruction * num_instructions;  // 160
//	
//	wire char_drawer_done;
//	reg [7:0] char_idx;  // 0->159
//	reg [2:0] pixel_x;   // 0->7
//	reg [2:0] pixel_y;   // 0->7
//	
//	char_drawer_logic cdl_inst (
//		.clock(clock),
//		.resetn(resetn),
//		.char_count(max_chars),
//		.done(char_drawer_done),
//		.char_idx(char_idx),
//		.pixel_x(pixel_x),
//		.pixel_y(pixel_y)
//	);
//	
//	// Determine which instruction row and character position
//	wire [3:0] instr_row = char_idx / chars_per_instruction;      // 0-9 (which instruction row)
//	wire [4:0] char_in_instr = char_idx % chars_per_instruction;  // 0-15 (position within row)
//	
//	// Get the instruction to display (accounting for circular buffer)
//	// Row 0 = oldest, Row 9 = newest
//	wire [3:0] buffer_idx = (buffer_head + instr_row) % 10;  // Map row to buffer position
//	wire [31:0] display_instruction = instruction_buffer[buffer_idx];
//	
//	// Determine if this is the newest instruction (red) or older (white)
//	wire is_newest = (instr_row == 9);
//	
//	// Build character code for current position
//	wire [7:0] char_code;
//	
//	always @(*) begin
//		case (char_in_instr)
//			// Position 0: Arrow (►) for newest, space for others
////			0: char_code = is_newest ? 8'd39 : 8'd37;  // 39 = ►, 37 = space
//			0: char_code = 8'd39;  
//			// Position 1: Space
//			1: char_code = 8'd37;
//			
//			// Positions 2-9: 8 hex digits of instruction
//			2: char_code = hex_to_char(display_instruction[31:28]);
//			3: char_code = hex_to_char(display_instruction[27:24]);
//			4: char_code = hex_to_char(display_instruction[23:20]);
//			5: char_code = hex_to_char(display_instruction[19:16]);
//			6: char_code = hex_to_char(display_instruction[15:12]);
//			7: char_code = hex_to_char(display_instruction[11:8]);
//			8: char_code = hex_to_char(display_instruction[7:4]);
//			9: char_code = hex_to_char(display_instruction[3:0]);
//			
//			// Positions 10-15: Padding spaces
//			10, 11, 12, 13, 14, 15: char_code = 8'd37;
//			
//			default: char_code = 8'd37;
//		endcase
//	end
//	
//	// Function to convert 4-bit hex to character code
//	function [7:0] hex_to_char(input [3:0] hex_digit);
//		begin
//			if (hex_digit < 10) begin
//				hex_to_char = 8'd0 + hex_digit;        // 0-9
//			end else begin
//				hex_to_char = 8'd10 + (hex_digit - 10); // A-F
//			end
//		end
//	endfunction
//	
//	// Get character bitmap
//	wire [63:0] pixelLine;
//	character bmp_inst (
//		.digit(char_code),
//		.pixelLine(pixelLine)
//	);
//	
//	// Position on screen
//	// Start at X=350, Y=20, each instruction row 15 pixels apart
//	assign log_x = 350 + (char_in_instr * 9) + pixel_x;
//	assign log_y = 25 + (instr_row * 15) + pixel_y;
//	
//	// Color: Red for newest (is_newest), white for others
//	wire [7:0] pixels [7:0];
//	assign pixels[0] = pixelLine[7:0];
//	assign pixels[1] = pixelLine[15:8];
//	assign pixels[2] = pixelLine[23:16];
//	assign pixels[3] = pixelLine[31:24];
//	assign pixels[4] = pixelLine[39:32];
//	assign pixels[5] = pixelLine[47:40];
//	assign pixels[6] = pixelLine[55:48];
//	assign pixels[7] = pixelLine[63:56];
//	
//	wire pixel_on = pixels[pixel_y][7-pixel_x];
//	
//	// Color assignment: Red for newest, white for older
//	assign log_color = pixel_on ? (is_newest ? 9'b110000000 : 9'b111111111) : 9'b000000000;
//	
//	// Done signal
//	assign log_done = char_drawer_done;
//
//endmodule

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
    assign title_x = 200 + (char_idx * 9) + pixel_x; 
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

//
//module pipeline_drawer(clock, resetn, IF_PC_VALUE, ID_VAL_A, EX_ALU_RESULT, MEM_DATA_OUT, WB_DATA_IN, pipeline_x, pipeline_y, pipeline_color, pipeline_done); 
//	input clock;  
//    input resetn; 
//    
//    // Data from control unit (example registers)
//    input [31:0] IF_PC_VALUE; 
//    input [31:0] ID_VAL_A; 
//    input [31:0] EX_ALU_RESULT;
//    input [31:0] MEM_DATA_OUT;
//    input [31:0] WB_DATA_IN;
//    
//    // VGA output coordinates and color
//    output wire [9:0] pipeline_x;    // 10-bit X coordinate
//    output wire [8:0] pipeline_y;    // 9-bit Y coordinate
//    output wire [8:0] pipeline_color; // 9-bit color output
//    output wire pipeline_done; // Set high when all drawing is complete
//
//	 // Drawing parameters
//	 localparam NUM_STAGES = 5;
//    localparam LABEL_WIDTH = 5; // e.g., "IF://"
//    localparam DATA_WIDTH = 8;  // 8 hex digits DATA_WIDTH(32 bits)
//    localparam CHARS_PER_LINE = LABEL_WIDTH + DATA_WIDTH; // 13
//    localparam MAX_CHARS = NUM_STAGES * CHARS_PER_LINE; // 65
//    
//    localparam START_X = 200;
//    localparam START_Y = 25;
//    localparam CHAR_SPACING = 9; // 8 pixels + 1 spacing
//    localparam LINE_HEIGHT = 10; // 8 pixels + 2 spacing
//    
//    localparam LABEL_COLOR = 9'b111000000; // Bright Red
//    localparam DATA_COLOR  = 9'b000111000; // Bright Green
//    localparam BACKGROUND_COLOR = 9'b000000000; // Black
//	
//    // Wires from Character Logic ---
//    wire char_drawer_done;
//    wire [7:0] char_idx; // Needs to be wide enough for MAX_CHARS (55)
//    wire [2:0] pixel_x;
//    wire [2:0] pixel_y;
//    
//    // Drawing State Variables
//    wire [2:0] stage_index; // Current stage being drawn (0 to 4)
//    wire [3:0] char_line_idx; // Current char position within the 11-char line (0 to 10)
//    wire [31:0] current_value; // The 32-bit value being displayed
//    
//    // Stage Index and Character Position
//    assign stage_index = char_idx / CHARS_PER_LINE; // 0-IF, 1-ID, 2-EX, 3-MEM, 4-WB
//    assign char_line_idx = char_idx % CHARS_PER_LINE; // 0-2 for label, 3-10 for data
//
//    // Instantiate drawing logic 
//    char_drawer_logic cdl_inst (
//        .clock(clock), 
//        .resetn(resetn), 
//        .char_count(MAX_CHARS), 
//        .done(char_drawer_done), 
//        .char_idx(char_idx), 
//        .pixel_x(pixel_x), 
//        .pixel_y(pixel_y)
//    );
//
//	// Connect done signal
//    assign pipeline_done = char_drawer_done;
//
//    // Select the 32-bit value corresponding to the current drawing stage
//    always @(*) begin
//        case (stage_index)
//            3'd0: current_value = IF_PC_VALUE;
//            3'd1: current_value = ID_VAL_A;
//            3'd2: current_value = EX_ALU_RESULT;
//            3'd3: current_value = MEM_DATA_OUT;
//            3'd4: current_value = WB_DATA_IN;
//            default: current_value = 32'hDEADBEEF; // Error/Default
//        endcase
//    end
//    
//    // Stage names: IF, ID, EX, MEM, WB
//    wire [7:0] stage_labels[0:4][0:4]; // [Stage][Char]
//	// 5 stages, 4 characters each, 8 
//    
//    // Stage 0: IF
//    assign stage_labels[0][0] = 8'd18; // 'I'
//    assign stage_labels[0][1] = 8'd15; // 'F'
//	 assign stage_labels[0][2] = 8'd36; // ':'
//    assign stage_labels[0][3] = 8'd37; // ' '
//	 assign stage_labels[0][4] = 8'd37; // ' '
//    // Stage 1: ID
//    assign stage_labels[1][0] = 8'd18; // 'I'
//    assign stage_labels[1][1] = 8'd13; // 'D'
//	 assign stage_labels[1][2] = 8'd36; // ':'
//    assign stage_labels[1][3] = 8'd37; // ' '
//	 assign stage_labels[1][4] = 8'd37; // ' '
//    
//	// Stage 2: EX
//    assign stage_labels[2][0] = 8'd14; // 'E'
//    assign stage_labels[2][1] = 8'd33; // 'X'
//    assign stage_labels[2][2] = 8'd36; // ':'
//	 assign stage_labels[2][3] = 8'd37; // ' '
//	 assign stage_labels[2][4] = 8'd37; // ' '
//
//    // Stage 3: MEM
//    assign stage_labels[3][0] = 8'd22; // 'M'
//    assign stage_labels[3][1] = 8'd14; // 'E'
//    assign stage_labels[3][2] = 8'd22; // 'M'
//	 assign stage_labels[3][3] = 8'd36; // ':'
//	 assign stage_labels[3][4] = 8'd37; // ' '
//    
//	// Stage 4: WB
//    assign stage_labels[4][0] = 8'd32; // 'W'
//    assign stage_labels[4][1] = 8'd11; // 'B'
//	 assign stage_labels[4][2] = 8'd36; // ':'
//    assign stage_labels[4][3] = 8'd37; // ' '
//	 assign stage_labels[4][4] = 8'd37; // ' '
//	 
//	 // --- CUSTOM CHARACTER MAPPING CONSTANTS ---
//    // These match YOUR character module exactly
//    localparam C_0 = 8'd0;  localparam C_8 = 8'd8;  localparam C_G = 8'd16; localparam C_O = 8'd24; localparam C_W = 8'd32;
//    localparam C_1 = 8'd1;  localparam C_9 = 8'd9;  localparam C_H = 8'd17; localparam C_P = 8'd25; localparam C_X = 8'd33;
//    localparam C_2 = 8'd2;  localparam C_A = 8'd10; localparam C_I = 8'd18; localparam C_Q = 8'd26; localparam C_Y = 8'd34;
//    localparam C_3 = 8'd3;  localparam C_B = 8'd11; localparam C_J = 8'd19; localparam C_R = 8'd27; localparam C_Z = 8'd35;
//    localparam C_4 = 8'd4;  localparam C_C = 8'd12; localparam C_K = 8'd20; localparam C_S = 8'd28; 
//    localparam C_5 = 8'd5;  localparam C_D = 8'd13; localparam C_L = 8'd21; localparam C_T = 8'd29; localparam C_COL = 8'd36; // :
//    localparam C_6 = 8'd6;  localparam C_E = 8'd14; localparam C_M = 8'd22; localparam C_U = 8'd30; localparam C_SP  = 8'd37; // Space
//    localparam C_7 = 8'd7;  localparam C_F = 8'd15; localparam C_N = 8'd23; localparam C_V = 8'd31; localparam C_PLS = 8'd38; // +
//
//    // --- ASSEMBLY DECODING LOGIC ---
//
//    // Define 16 columns (128 bits total string width)
//    wire [7:0] column_values [15:0]; 
//    wire [31:0] curRegister = register_file[row_idx]; 
//    
//    // This wire holds the full 16-character string derived from the function
//    wire [127:0] assembly_string;
//    
//    // Call the function combinatorially
//    assign assembly_string = get_assembly_string(curRegister);
//
//    // Map the big string into the character array
//    genvar i;
//    generate
//        for (i = 0; i < 16; i = i + 1) begin : assign_chars
//            assign column_values[i] = assembly_string[ (127 - (i*8)) -: 8 ];
//        end
//    endgenerate
//
//    // --- FUNCTION: Binary to Custom Assembly String ---
//    function [127:0] get_assembly_string;
//        input [31:0] inst;
//        
//        reg [5:0] opcode;
//        reg [2:0] r1;
//        reg [2:0] r2;
//        reg [15:0] imd;
//        
//        reg [7:0] r1_c;
//        reg [7:0] r2_c;
//        reg [7:0] h1, h2, h3, h4; 
//        
//        begin
//            // Initialize with spaces
//            get_assembly_string = {16{C_SP}};
//            
//            opcode = inst[31:26];
//            r1 = inst[25:23]; 
//            r2 = inst[22:20]; 
//            imd = inst[15:0]; 
//            
//            // Convert Registers indices to characters (0->0, 7->7)
//            r1_c = hex2char({1'b0, r1}); 
//            r2_c = hex2char({1'b0, r2});
//            
//            // Convert Immediate to characters
//            h1 = hex2char(imd[15:12]);
//            h2 = hex2char(imd[11:8]);
//            h3 = hex2char(imd[7:4]);
//            h4 = hex2char(imd[3:0]);
//
//            case (opcode)
//                // NOP
//                6'b000000: get_assembly_string = {C_N, C_O, C_P, {13{C_SP}}};
//                
//                // MVW R1, R2 -> M V W _ R 1 _ R 2
//                6'b001111: get_assembly_string = {C_M, C_V, C_W, C_SP, C_R, r1_c, C_SP, C_R, r2_c, {7{C_SP}}};
//                6'b001101: get_assembly_string = {C_M, C_V, C_L, C_SP, C_R, r1_c, C_SP, C_R, r2_c, {7{C_SP}}};
//                6'b001110: get_assembly_string = {C_M, C_V, C_U, C_SP, C_R, r1_c, C_SP, C_R, r2_c, {7{C_SP}}};
//                
//                // INC R1
//                6'b001011: get_assembly_string = {C_I, C_N, C_C, C_SP, C_R, r1_c, {10{C_SP}}};
//                
//                // ADD R1, R2
//                6'b001001: get_assembly_string = {C_A, C_D, C_D, C_SP, C_R, r1_c, C_SP, C_R, r2_c, {7{C_SP}}};
//                6'b001010: get_assembly_string = {C_S, C_U, C_B, C_SP, C_R, r1_c, C_SP, C_R, r2_c, {7{C_SP}}};
//                6'b001100: get_assembly_string = {C_M, C_U, C_L, C_SP, C_R, r1_c, C_SP, C_R, r2_c, {7{C_SP}}};
//
//                // ADD R1, #IMD -> A D D _ R 1 _ + H H H H (Using + as #)
//                6'b101100: get_assembly_string = {C_A, C_D, C_D, C_SP, C_R, r1_c, C_SP, C_PLS, h1, h2, h3, h4, {2{C_SP}}};
//                6'b101001: get_assembly_string = {C_S, C_U, C_B, C_SP, C_R, r1_c, C_SP, C_PLS, h1, h2, h3, h4, {2{C_SP}}};
//                6'b101010: get_assembly_string = {C_M, C_U, C_L, C_SP, C_R, r1_c, C_SP, C_PLS, h1, h2, h3, h4, {2{C_SP}}};
//
//                // LDW R1, *R2
//                6'b010011: get_assembly_string = {C_L, C_D, C_W, C_SP, C_R, r1_c, C_SP, C_PLS, C_R, r2_c, {5{C_SP}}};
//                6'b010010: get_assembly_string = {C_S, C_T, C_W, C_SP, C_R, r1_c, C_SP, C_PLS, C_R, r2_c, {5{C_SP}}};
//                
//                // Memory with Immediate Ptr
//                6'b110011: get_assembly_string = {C_L, C_D, C_W, C_SP, C_R, r1_c, C_SP, C_PLS, h1, h2, h3, h4, {1{C_SP}}};
//                6'b110010: get_assembly_string = {C_S, C_T, C_W, C_SP, C_R, r1_c, C_SP, C_PLS, h1, h2, h3, h4, {1{C_SP}}};
//                
//                // DI1
//                6'b111001: get_assembly_string = {C_D, C_I, C_1, {13{C_SP}}};
//                
//                // EN
//                6'b111010: get_assembly_string = {C_E, C_N, {14{C_SP}}};
//                
//                // Default: UNK HHHH
//                default:   get_assembly_string = {C_U, C_N, C_K, C_SP, hex2char(inst[31:28]), hex2char(inst[27:24]), {10{C_SP}}};
//            endcase
//        end
//    endfunction
//
//    // --- Character ROM Input Selection ---
//    wire [7:0] char_ascii; // ASCII code of the character to draw
//    
//    // Determine the character based on whether we are drawing the label (0-2) or the data (3-10)
//    always @(*) begin
//        if (char_line_idx < LABEL_WIDTH) begin
//            // Drawing the Label (Static)
//            char_ascii = stage_labels[stage_index][char_line_idx];
//        end else begin
//            // Drawing the Data (Dynamic Hex)
//            char_ascii = current_value[(DATA_WIDTH - 1 - (char_line_idx - LABEL_WIDTH)) * 4 +: 4]; // Extract 4 bits
//        end
//    end
//    
//    // --- Instantiate the Character ROM ---
//    wire [63:0] pixelLine;
//    character bmp_inst (
//        .digit(char_ascii),
//        .pixelLine(pixelLine)
//    );
//
//    // X/Y Calculation
//    assign pipeline_x = 200 + (char_line_idx * 9) + pixel_x; 
//    assign pipeline_y = 25 + (stage_index * 15) + pixel_y; 
//
//    // Pixel decoding and Color Assignment
//    wire [7:0] current_row = pixelLine[(pixel_y * 8) +: 8]; 
//    wire pixel_on = current_row[7 - pixel_x];
//    
//    assign pipeline_color = pixel_on ? 9'b111111111 : 3'b000;
//
//endmodule


module pipeline_drawer(
    input clock,  
    input resetn, 
    
    // NOTE: These inputs must be the 32-bit INSTRUCTION for that stage
    input [31:0] IF_PC_VALUE, 
    input [31:0] ID_VAL_A, 
    input [31:0] EX_ALU_RESULT,
    input [31:0] MEM_DATA_OUT,
    input [31:0] WB_DATA_IN,
    
    // VGA output coordinates and color
    output wire [9:0] pipeline_x,
    output wire [8:0] pipeline_y,
    output wire [8:0] pipeline_color,
    output wire pipeline_done
);

    // --- Drawing parameters ---
    localparam NUM_STAGES = 5;
    
    // Widths
    localparam LABEL_WIDTH = 4;      // "IF: "
    localparam ASM_WIDTH = 16;       // "ADD R0, #FFFF   "
    localparam CHARS_PER_LINE = LABEL_WIDTH + ASM_WIDTH; // 20
    localparam MAX_CHARS = NUM_STAGES * CHARS_PER_LINE;  // 100
    
    localparam START_X = 200;
    localparam START_Y = 25;
    
    // --- Custom Character Constants (Based on your character module) ---
    localparam C_0 = 8'd0;  localparam C_8 = 8'd8;  localparam C_G = 8'd16; localparam C_O = 8'd24; localparam C_W = 8'd32;
    localparam C_1 = 8'd1;  localparam C_9 = 8'd9;  localparam C_H = 8'd17; localparam C_P = 8'd25; localparam C_X = 8'd33;
    localparam C_2 = 8'd2;  localparam C_A = 8'd10; localparam C_I = 8'd18; localparam C_Q = 8'd26; localparam C_Y = 8'd34;
    localparam C_3 = 8'd3;  localparam C_B = 8'd11; localparam C_J = 8'd19; localparam C_R = 8'd27; localparam C_Z = 8'd35;
    localparam C_4 = 8'd4;  localparam C_C = 8'd12; localparam C_K = 8'd20; localparam C_S = 8'd28; 
    localparam C_5 = 8'd5;  localparam C_D = 8'd13; localparam C_L = 8'd21; localparam C_T = 8'd29; localparam C_COL = 8'd36; // :
    localparam C_6 = 8'd6;  localparam C_E = 8'd14; localparam C_M = 8'd22; localparam C_U = 8'd30; localparam C_SP  = 8'd37; // Space
    localparam C_7 = 8'd7;  localparam C_F = 8'd15; localparam C_N = 8'd23; localparam C_V = 8'd31; localparam C_PLS = 8'd38; // +
    localparam C_CM = 8'd40; // , (Comma)
	 localparam C_AST = 8'd41; 

    // Wires from Character Logic
    wire char_drawer_done;
    wire [7:0] char_idx; 
    wire [2:0] pixel_x;
    wire [2:0] pixel_y;
    
    // Drawing State Variables
    wire [2:0] stage_index;    // 0 to 4
    wire [4:0] char_line_idx;  // 0 to 19 (Position in line)
    
    reg [31:0] current_instruction; // The 32-bit instruction being processed
    wire [127:0] decoded_string;    // The decoded assembly text (16 chars * 8 bits)
	 reg [39:0] op_imm_r1_only; // R1, #IMD, or nothing

    // Stage Index and Character Position
    assign stage_index = char_idx / CHARS_PER_LINE; 
    assign char_line_idx = char_idx % CHARS_PER_LINE; 

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

    assign pipeline_done = char_drawer_done;

    // --- 1. Select Instruction based on Stage ---
    always @(*) begin
        case (stage_index)
            3'd0: current_instruction = IF_PC_VALUE;
            3'd1: current_instruction = ID_VAL_A;
            3'd2: current_instruction = EX_ALU_RESULT;
            3'd3: current_instruction = MEM_DATA_OUT;
            3'd4: current_instruction = WB_DATA_IN;
            default: current_instruction = 32'h00000000; // NOP
        endcase
    end
    
    // --- 2. Decode Instruction to String ---
    assign decoded_string = get_assembly_string(current_instruction);

    // --- 3. Stage Labels ---
    reg [7:0] current_label_char;
    always @(*) begin
        case (stage_index)
            3'd0: begin // "IF: "
                if(char_line_idx==0) current_label_char = C_I;
                else if(char_line_idx==1) current_label_char = C_F;
                else if(char_line_idx==2) current_label_char = C_COL;
                else current_label_char = C_SP;
            end
            3'd1: begin // "ID: "
                if(char_line_idx==0) current_label_char = C_I;
                else if(char_line_idx==1) current_label_char = C_D;
                else if(char_line_idx==2) current_label_char = C_COL;
                else current_label_char = C_SP;
            end
            3'd2: begin // "EX: "
                if(char_line_idx==0) current_label_char = C_E;
                else if(char_line_idx==1) current_label_char = C_X;
                else if(char_line_idx==2) current_label_char = C_COL;
                else current_label_char = C_SP;
            end
            3'd3: begin // "MM: "
                if(char_line_idx==0) current_label_char = C_M;
                else if(char_line_idx==1) current_label_char = C_M;
                else if(char_line_idx==2) current_label_char = C_COL;
                else current_label_char = C_SP;
            end
            3'd4: begin // "WB: "
                if(char_line_idx==0) current_label_char = C_W;
                else if(char_line_idx==1) current_label_char = C_B;
                else if(char_line_idx==2) current_label_char = C_COL;
                else current_label_char = C_SP;
            end
            default: current_label_char = C_SP;
        endcase
    end

    // --- 4. Character Selection ---
    reg [7:0] char_to_draw;
    
    always @(*) begin
        if (char_line_idx < LABEL_WIDTH) begin
            // Draw Label (e.g. "IF: ")
            char_to_draw = current_label_char;
        end else begin
            // Draw Assembly String
            // Calculate index into the 128-bit string
            integer string_char_idx;
            string_char_idx = char_line_idx - LABEL_WIDTH;
            char_to_draw = decoded_string[ (127 - (string_char_idx * 8)) -: 8 ];
        end
    end
    
    // --- 5. Bitmap & Output ---
    wire [63:0] pixelLine;
    character bmp_inst (
        .digit(char_to_draw),
        .pixelLine(pixelLine)
    );

    // X/Y Calculation
    assign pipeline_x = START_X + (char_line_idx * 9) + pixel_x; 
    assign pipeline_y = START_Y + (stage_index * 15) + pixel_y; 

    // Pixel decoding
    wire [7:0] current_row = pixelLine[(pixel_y * 8) +: 8]; 
    wire pixel_on = current_row[7 - pixel_x];
    
    // Color: Red for Label, Green for Text
    assign pipeline_color = pixel_on ? 
                            ((char_line_idx < LABEL_WIDTH) ? 9'b111000000 : 9'b000111000) 
                            : 9'b000000000;

    // --- 6. Helper Functions ---
    
    // 4-bit Hex to Custom Character Index
    function [7:0] hex2char;
        input [3:0] d;
        begin
            hex2char = {4'b0000, d}; // 0->0, A->10 (Matches your map)
        end
    endfunction

    // DECODER FUNCTION
    function [127:0] get_assembly_string;
        input [31:0] inst;
        
        reg [5:0] opcode;
        reg [2:0] r1;
        reg [2:0] r2;
        reg [15:0] imd;
        
        reg [7:0] r1_c, r2_c;
        reg [7:0] h1, h2, h3, h4;
        
        begin
            get_assembly_string = {16{C_SP}}; // Default Empty
            
            opcode = inst[31:26];
            r1 = inst[21:19]; 
            r2 = inst[18:16]; 
            imd = inst[15:0]; 
            
            r1_c = hex2char({1'b0, r1}); 
            r2_c = hex2char({1'b0, r2});
            
            h1 = hex2char(imd[15:12]); h2 = hex2char(imd[11:8]);
            h3 = hex2char(imd[7:4]);   h4 = hex2char(imd[3:0]);
				
				op_imm_r1_only = (opcode[5] == 1) ?
                            // Immediate form (e.g., PD1 #FFFF)
                            {C_PLS, h1, h2, h3, h4} :
                            // Register form (e.g., PD1 R1)
                            {C_R, r1_c, {4{C_SP}}};


            case (opcode)
                // --- REG-REG (Bit 31=0, Bit 30=0) ---
                6'b000000: get_assembly_string = {C_N, C_O, C_P, {13{C_SP}}}; // NOP
                
                6'b001111: get_assembly_string = {C_M, C_V, C_W, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // MVW R1, R2
                6'b001101: get_assembly_string = {C_M, C_V, C_L, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // MVL R1, R2
                6'b001110: get_assembly_string = {C_M, C_V, C_U, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // MVU R1, R2
                
                6'b001011: get_assembly_string = {C_I, C_N, C_C, C_SP, C_R, r1_c, {10{C_SP}}}; // INC R1
                
                // ADD/SUB/MUL (Reg-Reg)
                6'b001001: get_assembly_string = {C_A, C_D, C_D, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // ADD R1, R2
                6'b001010: get_assembly_string = {C_S, C_U, C_B, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // SUB R1, R2
                6'b001100: get_assembly_string = {C_M, C_U, C_L, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // MUL R1, R2

                // --- IMMEDIATE (Bit 31=1, Bit 30=0) ---
                // ADD/SUB/MUL (Reg-Imd) -> ADD R1, #FFFF
                6'b101001: get_assembly_string = {C_A, C_D, C_D, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, h1, h2, h3, h4, {1{C_SP}}};
                6'b101010: get_assembly_string = {C_S, C_U, C_B, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, h1, h2, h3, h4, {1{C_SP}}};
                6'b101100: get_assembly_string = {C_M, C_U, C_L, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, h1, h2, h3, h4, {1{C_SP}}};

                // --- MEMORY (Type=1) ---
                // LDW/STW (Reg Ptr) -> LDW R1, *R2
                6'b010011: get_assembly_string = {C_L, C_D, C_W, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, C_R, r2_c, {4{C_SP}}}; // + used as *
                6'b010001: get_assembly_string = {C_L, C_D, C_L, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, C_R, r2_c, {4{C_SP}}}; 
                6'b010010: get_assembly_string = {C_L, C_D, C_U, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, C_R, r2_c, {4{C_SP}}}; 
                
                6'b010111: get_assembly_string = {C_S, C_T, C_W, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, C_R, r2_c, {4{C_SP}}}; 
                6'b010101: get_assembly_string = {C_S, C_T, C_L, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, C_R, r2_c, {4{C_SP}}}; 
                6'b010110: get_assembly_string = {C_S, C_T, C_U, C_SP, C_R, r1_c, C_CM, C_SP, C_PLS, C_R, r2_c, {4{C_SP}}}; 

                // LDW/STW (Imd Ptr) -> LDW R1, *FFFF
                // FIX: Added {3{C_SP}} padding to fill the remaining 3 characters of the 16-character width.
                6'b110011: get_assembly_string = {C_L, C_D, C_W, C_SP, C_R, r1_c, C_CM, C_SP, C_AST, h1, h2, h3, h4, {3{C_SP}}}; 
                6'b110001: get_assembly_string = {C_L, C_D, C_L, C_SP, C_R, r1_c, C_CM, C_SP, C_AST, h1, h2, h3, h4, {3{C_SP}}}; 
                6'b110010: get_assembly_string = {C_L, C_D, C_U, C_SP, C_R, r1_c, C_CM, C_SP, C_AST, h1, h2, h3, h4, {3{C_SP}}}; 

                6'b110111: get_assembly_string = {C_S, C_T, C_W, C_SP, C_R, r1_c, C_CM, C_SP, C_AST, h1, h2, h3, h4, {3{C_SP}}}; 
                6'b110101: get_assembly_string = {C_S, C_T, C_L, C_SP, C_R, r1_c, C_CM, C_SP, C_AST, h1, h2, h3, h4, {3{C_SP}}}; 
                6'b110110: get_assembly_string = {C_S, C_T, C_U, C_SP, C_R, r1_c, C_CM, C_SP, C_AST, h1, h2, h3, h4, {3{C_SP}}}; 

					 
					 // Pipeline Stage 1 (Assume next block of opcodes, starting at 6'b111000)
                // DI1, EN1, PD1, AM1
                6'b111000: get_assembly_string = {C_D, C_I, C_1, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // DI1 R1, R2
                6'b111001: get_assembly_string = {C_E, C_N, C_1, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // EN1 R1, R2
                6'b111010: get_assembly_string = {C_P, C_D, C_1, C_SP, op_imm_r1_only, {7{C_SP}}}; // PD1 R1 or PD1 #FFFF
                6'b111011: get_assembly_string = {C_A, C_M, C_1, C_SP, op_imm_r1_only, {7{C_SP}}}; // AM1 R1 or AM1 #FFFF

                // DI2, EN2, PD2, AM2, DH2, DQ2, DE2 (7 instructions)
                // Need to use the full 6-bit opcode for differentiation. Assuming the DIx, ENx, AMx are R1,R2 type,
                // and PDx is R1/#IMD type, while DH/DQ/DE are simple instructions (1 operand or none).

                // Assuming R-R format for DIx/ENx/AMx
                6'b111100: get_assembly_string = {C_D, C_I, C_2, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // DI2 R1, R2
                6'b111101: get_assembly_string = {C_E, C_N, C_2, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // EN2 R1, R2
                6'b111110: get_assembly_string = {C_A, C_M, C_2, C_SP, C_R, r1_c, C_CM, C_SP, C_R, r2_c, {6{C_SP}}}; // AM2 R1, R2

                // Assuming R1/#IMD format for PDx
                6'b111111: get_assembly_string = {C_P, C_D, C_2, C_SP, op_imm_r1_only, {7{C_SP}}}; // PD2 R1 or PD2 #FFFF

                // Assuming Simple commands (1 operand R1) for DH/DQ/DE
                6'b000100: get_assembly_string = {C_D, C_H, C_2, C_SP, C_R, r1_c, {10{C_SP}}}; // DH2 R1
                6'b000101: get_assembly_string = {C_D, C_Q, C_2, C_SP, C_R, r1_c, {10{C_SP}}}; // DQ2 R1
                6'b000110: get_assembly_string = {C_D, C_E, C_2, C_SP, C_R, r1_c, {10{C_SP}}}; // DE2 R1

                // Pipeline Stage 3 (Assuming simple R1/#IMD format for PD3, AM3)
                6'b000111: get_assembly_string = {C_P, C_D, C_3, C_SP, op_imm_r1_only, {7{C_SP}}}; // PD3 R1 or PD3 #FFFF
                6'b001000: get_assembly_string = {C_A, C_M, C_3, C_SP, op_imm_r1_only, {7{C_SP}}}; // AM3 R1 or AM3 #FFFF
                
                // Pipeline Stage 4 (Assuming simple R1/#IMD format for PD4, AM4, DI4, EN4)
                6'b001011: get_assembly_string = {C_P, C_D, C_4, C_SP, op_imm_r1_only, {7{C_SP}}}; // PD4 R1 or PD4 #FFFF
                6'b001100: get_assembly_string = {C_A, C_M, C_4, C_SP, op_imm_r1_only, {7{C_SP}}}; // AM4 R1 or AM4 #FFFF
                6'b001101: get_assembly_string = {C_D, C_I, C_4, C_SP, op_imm_r1_only, {7{C_SP}}}; // DI4 R1 or DI4 #FFFF
                6'b001110: get_assembly_string = {C_E, C_N, C_4, C_SP, op_imm_r1_only, {7{C_SP}}}; // EN4 R1 or EN4 #FFFF

                // Special / Unrecognized
                6'b111010: get_assembly_string = {C_E, C_N, {14{C_SP}}}; // EN (Likely enable all or system enable)
                
                // Default
                default:   get_assembly_string = {C_U, C_N, C_K, C_SP, hex2char(inst[31:28]), hex2char(inst[27:24]), {10{C_SP}}};
            endcase
        end
    endfunction

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
				39: begin // arrow
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b00010000;
					pixels[2] = 8'b00011000;
					pixels[3] = 8'b00011100;
					pixels[4] = 8'b11111110;
					pixels[5] = 8'b00011100;
					pixels[6] = 8'b00011000;
					pixels[7] = 8'b00010000;
				end
				40: begin // , (Comma)
					pixels[0] = 8'b00000000;
					pixels[1] = 8'b00000000;
					pixels[2] = 8'b00000000;
					pixels[3] = 8'b00000000;
					pixels[4] = 8'b00000000;
					pixels[5] = 8'b00000000;
					pixels[6] = 8'b00011000;
					pixels[7] = 8'b00010000;
				end
//				41: begin // * (Fuzzy Asterisk)
//					pixels[0] = 8'b10011001; // Row 0
//					pixels[1] = 8'b01011010; // Row 1
//					pixels[2] = 8'b00111100; // Row 2
//					pixels[3] = 8'b11111111; // Row 3
//					pixels[4] = 8'b11111111; // Row 4
//					pixels[5] = 8'b00111100; // Row 5
//					pixels[6] = 8'b01011010; // Row 6
//					pixels[7] = 8'b10011001; // Row 7
//				end
				41: begin //astericks
					pixels[0] = 8'b00010101;
					pixels[1] = 8'b00001110;
					pixels[2] = 8'b00011111;
					pixels[3] = 8'b00001110;
					pixels[4] = 8'b00010101;
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
