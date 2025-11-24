// system verilog file
module instr_decode(
	input wire clock,
	input wire reset,
	input stall,
	
	input wire [31:0] if_id_reg,
	
	// Interface with register file
	output [2:0] register_select_1,
	output [2:0] register_select_2,
	input [31:0] selected_register_value_1, 
	input [31:0] selected_register_value_2,
	
	// Instruction specific opcodes
	output reg [2:0] alu_opcode,
	output reg [4:0] memory_access_code,
	output reg [2:0] audio_opcode,
	
	// Operand values 
	output reg [31:0] operand_value1,
	output reg [31:0] operand_value2,
	
	// writeback info
	output reg [1:0] register_writeback_enable,
	output reg [2:0] writeback_register_encoding,
	
	// audio info
	output reg [1:0] audio_channel_select,
	
	// read by the VGA
	output reg [31:0] id_ex_instruction
);

// breaking down full_instruction
wire [31:0] full_instruction   = if_id_reg;
wire         immediate_flag    = if_id_reg[31];
wire [1:0]   instruction_type  = full_instruction[30:29];
wire [2:0]   operation         = full_instruction[28:26];
wire [1:0]   channel_select    = full_instruction[25:24];
wire [1:0]   unused            = full_instruction[23:22];
assign       register_select_1 = full_instruction[21:19];
assign       register_select_2 = full_instruction[18:16];
wire [15:0]  immediate_value   = full_instruction[15:0];

// wires for logic
wire no_op = instruction_type == 2'b00;
wire is_arithmetic = (instruction_type ==  2'b01) && !(operation == 3'b111 || operation == 3'b101 || operation == 3'b110);
wire is_move = (instruction_type ==  2'b01) && (operation == 3'b111 || operation == 3'b101 || operation == 3'b110);
wire is_memory = instruction_type == 2'b10;
wire is_audio = instruction_type == 2'b11;

/* Handle instruction specific opcodes */
always @(posedge clock) begin
	if (no_op) begin
		alu_opcode <= 3'b000;
		memory_access_code <= 5'b00000;
		audio_opcode <= 3'b000;	
	end else
	if (is_move) begin
		alu_opcode <= 3'b000;
		memory_access_code <= 5'b00000;
		audio_opcode <= 3'b000;
	end else
	if (is_arithmetic) begin 
		alu_opcode <= operation;
		memory_access_code <= 5'b00000;
		audio_opcode <= 3'b000;		
	end else
	if(is_memory) begin
		alu_opcode <= 3'b000;
		memory_access_code[4]   <= operation[2];
		memory_access_code[3:2] <= {operation[1], operation[1]};
		memory_access_code[1:0] <= {operation[0], operation[0]};
		audio_opcode <= 3'b000;	
	end else
	if(is_audio) begin
		alu_opcode <= 3'b000;
		memory_access_code <= 5'b00000;
		audio_opcode <= operation;
	end
end
	
/* Handle operand values */
always @(posedge clock) begin
	if (immediate_flag) begin
		// Case: arithmetic immediate, memory immediate, or move lower immediate (3'b101)
		if (is_arithmetic || is_memory || (is_move && (operation == 3'b101))) begin
			operand_value1 <= selected_register_value_1; // not used in move lower
			operand_value2[31:16] <= 16'b0;                      
			operand_value2[15:0]  <= immediate_value;
		end
		// Case: move upper immediate (3'b110)
		else if (is_move && (operation == 3'b110)) begin
			operand_value1 <= selected_register_value_1; // not used
			operand_value2[31:16] <= immediate_value;
			operand_value2[15:0]  <= 16'b0;                      
		end
		// Case: audio amplitude immediate (operation == 3'b100)
		else if (is_audio && (operation == 3'b100)) begin
			operand_value1[31:16] <= immediate_value;
			operand_value1[15:0]  <= 16'b0;
			operand_value2 <= selected_register_value_2; // not used
		end
		// Case: audio period immediate (operation == 3'b110)
		else if (is_audio && (operation == 3'b110)) begin
			operand_value1[31:24] <= 8'b0;                       
			operand_value1[23:8]  <= immediate_value;           
			operand_value1[7:0]   <= 8'b0;                       
			operand_value2 <= selected_register_value_2;
		end
		// default: immediate_flag set but instruction doesn't match expected patterns
		else begin 
			// assume programmer mistakenly set immediate_flag, fall back to register operands
			operand_value1 <= selected_register_value_1;
			operand_value2 <= selected_register_value_2;
		end
	end
	else begin
		// no immediate: both operands come from register file
		operand_value1 <= selected_register_value_1;
		operand_value2 <= selected_register_value_2;
	end
end

/* Handle writeback info */
always @(posedge clock) begin
	writeback_register_encoding <= register_select_1;
	if (is_arithmetic) 
		register_writeback_enable <= 2'b11;
	else if (is_move && (operation == 3'b101) /*move lower*/ || is_memory && (operation == 3'b001) /*load lower*/)
		register_writeback_enable <= 2'b01;
	else if (is_move && (operation == 3'b110) /*move upper*/ || is_memory && (operation == 3'b010) /*load upper*/)
		register_writeback_enable <= 2'b10;
	else
		register_writeback_enable <= 2'b00;
		
end
	
always @(posedge clock) audio_channel_select <= channel_select;
always @(posedge clock) id_ex_instruction <= full_instruction;

endmodule
