module control_unit(SW, LEDR, KEY, HEX5, HEX4, HEX0, HEX1, HEX3, HEX2);
	  // Hardware I/O
  input [9:0] SW;
  input [2:0] KEY;
  output [9:0] LEDR;
  output [6:0] HEX0;
  output [6:0] HEX1;
  output [6:0] HEX3;
  output [6:0] HEX2, HEX5, HEX4;

  // Necessary values
  // wire [7:0] instruction_state = SW[7:0]; <- not used, can remove

  // Clock pulse and reset
  wire clock_pulse = ~KEY[1];
  wire resetn = KEY[0];
  wire stall; // Controlled by HDU.

  //assign stall = 0;

  // Registers
  wire [31:0] IR; // Special purpose

  
  // Register file conntrol
  wire [1:0] we; //
  wire [31:0] wdata; 
  wire [2:0] r_write_enc; //

  wire [2:0] r_enc_0; //
  wire [2:0] r_enc_1; //

  wire [31:0] rf_out_val1;
  wire [31:0] rf_out_val2;

  wire [31:0] R0_val;
  wire [31:0] R1_val;
  
  //assign register_file = regiser_tracker; 

  reg_file reg_file_inst(
      .clk(clock_pulse),
      .resetn(resetn),

      .we(we),

      .r_enc_0(r_enc_0),
      .r_enc_1(r_enc_1),

      .r_write_enc(r_write_enc),

      .reg_out_0(rf_out_val1),
      .reg_out_1(rf_out_val2),

      .wdata(wdata),

      .R0_val(R0_val),
      .R1_val(R1_val), 
		//.register_output(regiser_tracker) 
  );

  // Hex display for register file

  
  display_hex display_hex_inst5(pc[3:0], HEX5);
  display_hex display_hex_inst4({2'b0,we}, HEX4); 
  display_hex display_hex_inst3({1'b0, r_write_enc}, HEX3);
  display_hex display_hex_inst2(0, HEX2);  
  display_hex display_hex_inst1({1'b0, ex_mem_reg_wb_data_select_hotcode}, HEX1);
  display_hex display_hex_inst0(R0_val, HEX0);  
  
  
  // Audio control
  wire [2:0] audio_opcode;
  wire [1:0] audio_channel_select;
  
  // Audio instantiation

  // ALU Control 
  wire [2:0] alu_opcode;
  wire [31:0] alu_reg_val1;
  wire [31:0] alu_reg_val2;
  wire [31:0] alu_result; 

  wire bs;  // lol

  // ALU instantiation
  ALU alu_inst(
    .opcode(alu_opcode),
    .arithmetic_result(alu_result), 
    .register_value_1(alu_reg_val1),
    .register_value_2(alu_reg_val2)
  );


  HDU hdu_inst(
    .ID_instruct(if_id_reg),
    .EX_instruct(ex_instruct),
    .MEM_instruct(mem_instruct),
    .WB_instruct(wb_instruct),

    .stall(stall),
    .out(bs)
  );
	wire [14:0] pc;
	wire [31:0] catheter;
  instr_fetch instr_fetch_inst(
      .clk(clock_pulse),
      .stall(stall),
      .resetn(resetn),
		.catheter(catheter),
      .if_id_reg(if_id_reg),
		.pc_out(pc)
  );
  
  // IF/ID Registers
  wire [31:0] if_id_reg; // Doubles as ID_instruct // 32
  
  instr_decode instr_decode_inst(
		.clk(clock_pulse),
		.resetn(resetn), // to be changed
		.stall(stall), 
		
		.if_id_reg(if_id_reg),
		.register_select_1(r_enc_0),
		.register_select_2(r_enc_1),
		
		.selected_register_value_1(rf_out_val1),
		.selected_register_value_2(rf_out_val2),
		
		.alu_opcode(id_ex_reg_alu_opcode),
		.memory_access_code(id_ex_reg_memory_access_code),
		
		.audio_opcode(id_ex_reg_audio_opcode),
		.audio_channel_select(id_ex_reg_audio_channel_select),
		
		.operand_value1(id_ex_reg_operand_val1),
		.operand_value2(id_ex_reg_operand_val2),
		
		.register_writeback_enable(id_ex_regwrite),
		.writeback_register_encoding(id_ex_reg_wb_enc),
		.writeback_data_select_hotcode(id_ex_reg_wb_data_select_hotcode),
				
		.id_ex_instruction(ex_instruct) // for hazard and VGA
  );
    
  // ID/EX Registers
  wire [31:0] ex_instruct; 
  wire [1:0] id_ex_regwrite;
  wire [2:0] id_ex_reg_alu_opcode;
  wire [31:0] id_ex_reg_operand_val1;
  wire [31:0] id_ex_reg_operand_val2;
  wire [1:0] id_ex_reg_wb_enc; 
  wire [4:0] id_ex_reg_memory_access_code;
  wire [2:0] id_ex_reg_wb_data_select_hotcode;
    
  wire [2:0] id_ex_reg_audio_opcode;
  wire [1:0] id_ex_reg_audio_channel_select;

  
  // what does instr_decode need to propogate:
  // 4) id_ex_wb_data_select_hotcode
  // 6) id_ex_memory_access_code

  instr_execute instr_execute_inst(
      .clk(clock_pulse),
      .resetn(resetn),
		
		// outputs
      .alu_opcode(alu_opcode),
      .alu_reg_val1(alu_reg_val1),
      .alu_reg_val2(alu_reg_val2),
		
		// inputs
      .alu_result(alu_result),
		
		// outputs to audio unit.
      .audio_opcode(audio_opcode),
		.audio_channel_select(audio_channel_select),
		
		.id_ex_reg_audio_opcode(id_ex_reg_audio_opcode),
		.id_ex_reg_audio_channel_select(id_ex_reg_audio_channel_select),
      .id_ex_reg_alu_opcode(id_ex_reg_alu_opcode),  
      .id_ex_reg_operand_val1(id_ex_reg_operand_val1), // propogate
      .id_ex_reg_operand_val2(id_ex_reg_operand_val2),// propogate
      .id_ex_regwrite(id_ex_regwrite), // propogate
      .id_ex_reg_wb_enc(id_ex_reg_wb_enc), // propogate
		.id_ex_reg_wb_data_select_hotcode(id_ex_reg_wb_data_select_hotcode), // propogate
		.id_ex_reg_memory_access_code(id_ex_reg_memory_access_code), // propogate

      .ex_mem_reg_wb_enc(ex_mem_reg_wb_enc), //
      .ex_mem_regwrite(ex_mem_regwrite), //
		.ex_mem_reg_arithmetic_result(ex_mem_reg_arithmetic_result), //
		
		// New instructions propogating
		.ex_mem_reg_operand_val1(ex_mem_reg_operand_val1),
		.ex_mem_reg_operand_val2(ex_mem_reg_operand_val2),
		.ex_mem_reg_wb_data_select_hotcode(ex_mem_reg_wb_data_select_hotcode),
		.ex_mem_reg_memory_access_code(ex_mem_reg_memory_access_code),

      .ex_instruct(ex_instruct),
      .mem_instruct(mem_instruct)
  ); 
  
  
  // EX/MEM Registers
  wire [31:0] mem_instruct;
  wire [1:0] ex_mem_regwrite;
  wire [31:0] ex_mem_reg_arithmetic_result;
  wire [2:0] ex_mem_reg_wb_enc;
  wire [31:0] ex_mem_reg_operand_val1;
  wire [31:0] ex_mem_reg_operand_val2;
  wire [2:0] ex_mem_reg_wb_data_select_hotcode;
  wire [4:0] ex_mem_reg_memory_access_code;
  
  
  instr_mem instr_mem_inst(
      .clk(clock_pulse),
      .resetn(resetn),

      .ex_mem_regwrite(ex_mem_regwrite),
      .ex_mem_reg_wb_enc(ex_mem_reg_wb_enc),
      .ex_mem_reg_arithmetic_result(ex_mem_reg_arithmetic_result),
		.ex_mem_reg_operand_val1(ex_mem_reg_operand_val1),
		.ex_mem_reg_operand_val2(ex_mem_reg_operand_val2),
		.ex_mem_reg_wb_data_select_hotcode(ex_mem_reg_wb_data_select_hotcode),
		.ex_mem_reg_memory_access_code(ex_mem_reg_memory_access_code),
		
      .mem_wb_reg_wb_enc(mem_wb_reg_wb_enc),
      .mem_wb_reg_arithmetic_result(mem_wb_reg_arithmetic_result),
      .mem_wb_regwrite(mem_wb_regwrite),
		.mem_wb_reg_memory_wb_data(mem_wb_reg_memory_wb_data), // This 
		.mem_wb_reg_operand_val2(mem_wb_reg_operand_val2),
		.mem_wb_reg_wb_data_select_hotcode(mem_wb_reg_wb_data_select_hotcode), 

      .mem_instruct(mem_instruct),
      .wb_instruct(wb_instruct)

  );
  
  
  // MEM/WB Registers
  wire [31:0] wb_instruct;
  
  
  wire [1:0] mem_wb_regwrite;
  wire [2:0] mem_wb_reg_wb_enc;
  wire [31:0] mem_wb_reg_arithmetic_result;
  wire [31:0] mem_wb_reg_memory_wb_data;
  wire [31:0] mem_wb_reg_operand_val2;
  wire [2:0] mem_wb_reg_wb_data_select_hotcode;
  

  instr_wb instr_wb_inst(
      .clk(clock_pulse),
		.resetn(resetn),
		
		.wb_instruct(wb_instruct),
      .mem_wb_regwrite(mem_wb_regwrite),
      .mem_wb_reg_wb_enc(mem_wb_reg_wb_enc),
      .mem_wb_reg_arithmetic_result(mem_wb_reg_arithmetic_result),
		.mem_wb_reg_memory_wb_data(mem_wb_reg_memory_wb_data),
		.mem_wb_reg_operand_val2(mem_wb_reg_operand_val2),
		.mem_wb_reg_wb_data_select_hotcode(mem_wb_reg_wb_data_select_hotcode),

      .reg_file_write_enable(we),
      .reg_file_register_encoding(r_write_enc),
      .reg_file_writeback_data(wdata),
		
		.completed_instruction(completed_instruction)
  );
  
  wire [31:0] completed_instruction;
  
  // Testing decode: 
  assign LEDR[9:8] = if_id_reg[28:26];
  assign LEDR[7:6] = ex_instruct[28:26];
  assign LEDR[5:4] = mem_instruct[28:26];
  assign LEDR[3:2] = wb_instruct[28:26];
  
  
endmodule

module reg_file(clk, resetn, we, r_enc_0, r_enc_1, r_write_enc, reg_out_0, reg_out_1, wdata, R0_val, R1_val); 
  parameter [2:0] R0_ENC = 3'b000,
                  R1_ENC = 3'b001,
                  R2_ENC = 3'b010,
                  R3_ENC = 3'b011,
                  R4_ENC = 3'b100,
                  R5_ENC = 3'b101,
                  R6_ENC = 3'b110,
                  R7_ENC = 3'b111;

  input [1:0] we; // Indicates if we are doing a write (write enable)
  input clk;
  input resetn;

  input [2:0] r_enc_0; // Register encodings 
  input [2:0] r_enc_1; 
  input [2:0] r_write_enc;
  input [31:0] wdata;

  output [31:0] R0_val;
  output [31:0] R1_val;
  
  output reg [31:0] reg_out_0;
  output reg [31:0] reg_out_1;
  
  // The actual registers =)
  reg [31:0] R0; // 000
  reg [31:0] R1; // 001
  reg [31:0] R2; // 010
  reg [31:0] R3; // 011
  reg [31:0] R4; // 100
  reg [31:0] R5; // 101
  reg [31:0] R6; // 110
  reg [31:0] R7; // 111

  // Reading registers
  always @ (*) begin
    case (r_enc_0)
      R0_ENC: reg_out_0 = R0;
      R1_ENC: reg_out_0 = R1;
      R2_ENC: reg_out_0 = R2;
      R3_ENC: reg_out_0 = R3;
      R4_ENC: reg_out_0 = R4;
      R5_ENC: reg_out_0 = R5;
      R6_ENC: reg_out_0 = R6;
      R7_ENC: reg_out_0 = R7;
      default: reg_out_0 = 0;
    endcase

    case (r_enc_1)
      R0_ENC: reg_out_1 = R0;
      R1_ENC: reg_out_1 = R1;
      R2_ENC: reg_out_1 = R2;
      R3_ENC: reg_out_1 = R3;
      R4_ENC: reg_out_1 = R4;
      R5_ENC: reg_out_1 = R5;
      R6_ENC: reg_out_1 = R6;
      R7_ENC: reg_out_1 = R7;
      default: reg_out_1 = 0;
    endcase
  end
  
  always @ (negedge clk or negedge resetn) begin
    if (!resetn) begin
      R0 <= 32'd0;
      R1 <= 32'd0;
      R2 <= 32'd0;
      R3 <= 32'd0;
      R4 <= 32'd0;
      R5 <= 32'd0;
      R6 <= 32'd0;
      R7 <= 32'd0;
    end
    else begin
      if (we[0]) begin
        case (r_write_enc) 
          R0_ENC: R0[15:0] <= wdata[15:0]; 
          R1_ENC: R1[15:0] <= wdata[15:0];
          R2_ENC: R2[15:0] <= wdata[15:0];
          R3_ENC: R3[15:0] <= wdata[15:0];
          R4_ENC: R4[15:0] <= wdata[15:0];
          R5_ENC: R5[15:0] <= wdata[15:0];
          R6_ENC: R6[15:0] <= wdata[15:0];
          R7_ENC: R7[15:0] <= wdata[15:0];
        endcase
      end
      if (we[1]) begin
        case (r_write_enc) 
          R0_ENC: R0[31:16] <= wdata[31:16]; 
          R1_ENC: R1[31:16] <= wdata[31:16];
          R2_ENC: R2[31:16] <= wdata[31:16];
          R3_ENC: R3[31:16] <= wdata[31:16];
          R4_ENC: R4[31:16] <= wdata[31:16];
          R5_ENC: R5[31:16] <= wdata[31:16];
          R6_ENC: R6[31:16] <= wdata[31:16];
          R7_ENC: R7[31:16] <= wdata[31:16];
        endcase
      end
    end
  end

  assign R0_val = R0; 
  assign R1_val = R1;
endmodule

// ALU Module
module ALU(opcode, arithmetic_result, register_value_1, register_value_2);
  parameter [2:0] ADD = 3'b001,
                  INC = 3'b011;

  input [2:0] opcode;
  input [31:0] register_value_1;
  input [31:0] register_value_2;
  
  output reg [31:0] arithmetic_result;
  always @ (*) begin
    case (opcode) 
      ADD: arithmetic_result = register_value_1 + register_value_2; 
      INC: arithmetic_result = register_value_1 + 1; 
      default: arithmetic_result = 32'b0;
    endcase
  end
endmodule

module instr_fetch(clk, resetn, stall, catheter, if_id_reg, pc_out);
  input clk;
  input resetn;
  input stall;
  output [14:0] pc_out;
  reg [14:0] pc;				// program counter (new)
  output reg [31:0] if_id_reg;		// changed to 32 bits. instead of a reg, this is now a wire to a BRAM DataOut reg.
  output [31:0] catheter; assign catheter = instr_rom_out;
  wire [31:0] instr_rom_out;
  assign pc_out = pc;
  
  instruction_rom instruction_rom(
	.address(pc),
	.clock(clk),
	.data(),
	.wren(0),
	.q(instr_rom_out)
	
	);
  
  reg load_enable;
  
  reg [4:0] warmup_cnt;
  wire warmup_done = (warmup_cnt == 2'd2); // change this to <=
  wire warmup_really_done = (warmup_cnt >= 2);
  always @ (posedge clk or negedge resetn) begin
    if (!resetn) begin 
      pc <= 0;
      if_id_reg <= 0;
      load_enable <= 1;
		warmup_cnt <= 0;
    end
	 else if (warmup_done) begin 
		pc <= 0;
		if_id_reg <= 8'd0;
		load_enable <= 1'b1;
		warmup_cnt <= 3;
	 end
    else if (stall) begin 
      pc <= pc;
      if (load_enable) begin
        if_id_reg <= instr_rom_out;
        load_enable <= 0;
      end
      else if_id_reg <= if_id_reg;
    end
    else begin
      pc <= pc + 1;
      if_id_reg <= instr_rom_out;
      load_enable <= 1;
		if(!warmup_really_done) warmup_cnt <= warmup_cnt + 2'd1;
    end
	 
  end
endmodule

module instr_decode(
	input wire clk,
	input wire resetn,
	input wire stall,
	
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
	output reg [2:0] writeback_data_select_hotcode,
	
	// audio info
	output reg [1:0] audio_channel_select,
	
	// read by the VGA
	output reg [31:0] id_ex_instruction
);

	// breaking down full_instruction
	wire [31:0] full_instruction   = if_id_reg;
	wire         immediate_flag    = full_instruction[31];
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
	always @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			alu_opcode <= 3'b000;
			memory_access_code <= 5'b00000;
			audio_opcode <= 3'b000;	
		end else
		if (no_op || stall) begin
			alu_opcode <= 3'b000;
			memory_access_code <= 5'b00000;
			audio_opcode <= 3'b000;	
		end else
		if (no_op || stall) begin
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
	always @(posedge clk) begin
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
	always @(posedge clk, negedge resetn) begin
		writeback_register_encoding <= register_select_1;
		if (~resetn)
			register_writeback_enable <= 2'b00;
		else if (no_op || stall)
			register_writeback_enable <= 2'b00;
		else if (is_move && (operation == 3'b101) /*move lower*/ || is_memory && (operation == 3'b001) /*load lower*/)
			register_writeback_enable <= 2'b01;
		else if (is_move && (operation == 3'b110) /*move upper*/ || is_memory && (operation == 3'b010) /*load upper*/)
			register_writeback_enable <= 2'b10;
		else if (is_arithmetic || is_move) 
			register_writeback_enable <= 2'b11;
		else
			register_writeback_enable <= 2'b00;
	end

	always @(posedge clk, negedge resetn) writeback_data_select_hotcode <=
		{
			is_arithmetic, 
			is_memory, 
			is_move
		};
		
	always @(posedge clk) audio_channel_select <= channel_select;

	always @(posedge clk, negedge resetn) begin
		if (~resetn)
			id_ex_instruction <= 32'd0;
		else if (stall || no_op)
			id_ex_instruction <= 32'd0;
		else
			id_ex_instruction <= full_instruction;
	end

endmodule

module instr_execute(
  input clk,
  input resetn,
  
  // From ID/EX pipeline
  
  input [31:0] ex_instruct, 
  input [1:0] id_ex_regwrite,
  input [2:0] id_ex_reg_alu_opcode,
  input [31:0] id_ex_reg_operand_val1,
  input [31:0] id_ex_reg_operand_val2,
  input [1:0] id_ex_reg_wb_enc, 
  input [4:0] id_ex_reg_memory_access_code,
  input [2:0] id_ex_reg_wb_data_select_hotcode,
  input [2:0] id_ex_reg_audio_opcode,
  input [1:0] id_ex_reg_audio_channel_select,
  
  // EX/MEM Registers
  output reg [31:0] mem_instruct,
  output reg [1:0] ex_mem_regwrite,
  output reg [31:0] ex_mem_reg_arithmetic_result,
  output reg [2:0] ex_mem_reg_wb_enc,
  output reg [31:0] ex_mem_reg_operand_val1,
  output reg [31:0] ex_mem_reg_operand_val2,
  output reg [2:0] ex_mem_reg_wb_data_select_hotcode,
  output reg [4:0] ex_mem_reg_memory_access_code,
  
  // Audio Synthesizer Master Interface
  output [2:0] audio_opcode,
  output [1:0] audio_channel_select,
  
  // ALU interface
  output [2:0] alu_opcode,
  output [31:0] alu_reg_val1,
  output [31:0] alu_reg_val2,
  input [31:0] alu_result
  );
  
  
  // To audio unit (combinational - wires)
  assign audio_opcode = id_ex_reg_audio_opcode;
  assign audio_channel_select = id_ex_reg_audio_channel_select;

  // To ALU (combinational - wires)
  assign alu_opcode = id_ex_reg_alu_opcode;
  assign alu_reg_val1 = id_ex_reg_operand_val1;
  assign alu_reg_val2 = id_ex_reg_operand_val2;

  always @ (posedge clk or negedge resetn) begin
    if (!resetn) begin
		mem_instruct <= 0;
		ex_mem_regwrite <= 0;
		ex_mem_reg_arithmetic_result <= 0;
		ex_mem_reg_wb_enc <= 0;
		ex_mem_reg_operand_val1 <= 0;
		ex_mem_reg_operand_val2 <= 0;
		ex_mem_reg_wb_data_select_hotcode <= 0;
		ex_mem_reg_memory_access_code <= 0;
    end
    else begin
		mem_instruct <= ex_instruct;
		ex_mem_regwrite <= id_ex_regwrite;
		ex_mem_reg_arithmetic_result <= alu_result;
		ex_mem_reg_wb_enc <= id_ex_reg_wb_enc;
		ex_mem_reg_operand_val1 <= id_ex_reg_operand_val1;
		ex_mem_reg_operand_val2 <= id_ex_reg_operand_val2;
		ex_mem_reg_wb_data_select_hotcode <= id_ex_reg_wb_data_select_hotcode;
		ex_mem_reg_memory_access_code <= id_ex_reg_memory_access_code;
    end
  end
endmodule

module instr_mem (
    input  wire        clk,
    input  wire        resetn,

    input  wire [1:0]  ex_mem_regwrite,//
    input  wire [2:0]  ex_mem_reg_wb_enc,//
    input  wire [31:0] ex_mem_reg_arithmetic_result,//
    input  wire [31:0] ex_mem_reg_operand_val1,
    input  wire [31:0] ex_mem_reg_operand_val2,
    input  wire [2:0]  ex_mem_reg_wb_data_select_hotcode,//
    input  wire [4:0]  ex_mem_reg_memory_access_code,

    output reg  [2:0]  mem_wb_reg_wb_enc,//
    output reg  [31:0] mem_wb_reg_arithmetic_result,//
    output reg  [1:0]  mem_wb_regwrite,//
    output wire [31:0] mem_wb_reg_memory_wb_data,
    output reg  [31:0] mem_wb_reg_operand_val2,//
    output reg  [2:0]  mem_wb_reg_wb_data_select_hotcode,//

    input  wire [31:0] mem_instruct,//
    output reg  [31:0] wb_instruct,//
	output wire [255:0] memory_first_32_bytes
);

	// Signals propogating through
	always @(posedge clk or negedge resetn) begin
		if (~resetn) begin
			mem_wb_regwrite <= 0;
			mem_wb_reg_wb_enc <= 0;
			mem_wb_reg_wb_data_select_hotcode <= 0;
			
			mem_wb_reg_arithmetic_result <= 0;
			mem_wb_reg_operand_val2 <= 0;
			
			wb_instruct <= 0;
		end 
		else begin
			mem_wb_regwrite <= ex_mem_regwrite;
			mem_wb_reg_wb_enc <= ex_mem_reg_wb_enc;
			mem_wb_reg_wb_data_select_hotcode <= ex_mem_reg_wb_data_select_hotcode;
			
			mem_wb_reg_arithmetic_result <= ex_mem_reg_arithmetic_result;
			mem_wb_reg_operand_val2 <= ex_mem_reg_operand_val2;
			
			wb_instruct <= mem_instruct;
		end
	end
	
	wire [1:0] r_D;
	reg [1:0] r_Q;
	always @(posedge clk) r_Q <= r_D; 
	memory_io_unit memory_io_unit (
		.data_to_store(ex_mem_reg_operand_val1),
		.memory_address(ex_mem_reg_operand_val2),
		.memory_access_code(ex_mem_reg_memory_access_code),	
		.clock(clk),		
		.prev_r(r_Q),	
		
		.writeback_register_data(mem_wb_reg_memory_wb_data),	
		.r(r_D)				
	);

	wire [1:0] r_D2; 
	reg [1:0] r_Q2;
	always @(posedge clk) r_Q2 <= r_D2; 
	memory_for_vga memory_for_vga (
		.data_to_store(ex_mem_reg_operand_val1),
		.memory_address(ex_mem_reg_operand_val2),
		.memory_access_code(ex_mem_reg_memory_access_code),
		.clock(clk),		
		.prev_r(r_Q2),
		
		.writeback_register_data(),
		.r(r_D2),
		.memory_first_32_bytes(memory_first_32_bytes)
	);
endmodule

module instr_wb(
	input clk,
	input resetn,

	input [31:0] wb_instruct,		// For VGA
	input [1:0] mem_wb_regwrite,
	input [2:0] mem_wb_reg_wb_enc,	// From decode stage
	
	input [31:0] mem_wb_reg_memory_wb_data,			// From memory stage
	input [31:0] mem_wb_reg_arithmetic_result,		// From execute stage
	input [31:0] mem_wb_reg_operand_val2, 			// From decode stage (operand_value_2)
	input [2:0] mem_wb_reg_wb_data_select_hotcode,

	/* Signals to register file for writeback */
	output reg [1:0] reg_file_write_enable,
	output reg [2:0] reg_file_register_encoding,
	output reg [31:0] reg_file_writeback_data,
	
	output reg [31:0] completed_instruction		// For VGA
);

parameter [2:0] is_arithmetic = 3'b100,
				is_memory     = 3'b010,
				is_move       = 3'b001;


always@(posedge clk, negedge resetn) begin
	if (!resetn) reg_file_write_enable <= 0; else begin
		case (mem_wb_reg_wb_data_select_hotcode)
			is_arithmetic: 	reg_file_writeback_data <= mem_wb_reg_arithmetic_result;
			is_memory:		reg_file_writeback_data <= mem_wb_reg_memory_wb_data;
			is_move:		reg_file_writeback_data <= mem_wb_reg_operand_val2;
			default:		reg_file_writeback_data <= 0; // unused
		endcase
		reg_file_write_enable <= mem_wb_regwrite;
		reg_file_register_encoding <= mem_wb_reg_wb_enc;
		
		completed_instruction <= wb_instruct; // for VGA
	end 
end
endmodule

module HDU(ID_instruct, EX_instruct, MEM_instruct, WB_instruct, stall, out);
  // I am going to assume we shove the whole instruction through the pipeline.
  parameter [2:0] NOP = 3'b000,
                  ADD = 3'b001,
                  INC = 3'b011;

  input [31:0] ID_instruct;
  input [31:0] EX_instruct;
  input [31:0] MEM_instruct;
  input [31:0] WB_instruct; 

  output reg stall; // This is the stall signal!
  output out;

  wire [2:0] ID_opcode;
  wire [2:0] ID_reg1;
  wire [2:0] ID_reg2;
  
  wire [2:0] EX_opcode;
  wire [2:0] EX_reg1; 

  wire [2:0] MEM_opcode;
  wire [2:0] MEM_reg1;

  wire [2:0] WB_opcode;
  wire [2:0] WB_reg1;

  // have some assigns with the inputs to the wires
  assign ID_opcode = ID_instruct[31:26];
  assign EX_opcode = EX_instruct[31:26];
  assign MEM_opcode = MEM_instruct[31:26];
  assign WB_opcode = WB_instruct[31:26];

  assign ID_reg1 = ID_instruct[21:19]; 
  assign ID_reg2 = ID_instruct[18:16];

  assign EX_reg1 = EX_instruct[21:19];
  assign MEM_reg1 = MEM_instruct[21:19];
  assign WB_reg1 = WB_instruct[21:19];


  always @ (*) begin
    if (ID_opcode != NOP) begin
      if ((EX_opcode != NOP && EX_reg1 == ID_reg1) || (MEM_opcode != NOP && MEM_reg1 == ID_reg1) || (WB_opcode != NOP && WB_reg1 == ID_reg1)) stall = 1;
      else if (ID_opcode != INC && ((EX_opcode != NOP && ID_reg2 == EX_reg1) || (MEM_opcode != NOP && ID_reg2 == MEM_reg1) || (WB_opcode != NOP && ID_reg2 == WB_reg1))) stall = 1;
      else stall = 0;
    end
    else stall = 0;
  end
  assign out = stall;
endmodule

/* Hex display module for displaying first few bytes of the registers on the hex displays*/
module display_hex(input [3:0] dig, output [6:0] HEX);
    reg [6:0] temp;
    assign HEX = temp;   // connect internal signal to output

    always @ (*) begin
        if (dig == 4'h0)
            temp = 7'b1000000;  // 0
        else if (dig == 4'h1)
            temp = 7'b1111001;  // 1
        else if (dig == 4'h2)
            temp = 7'b0100100;  // 2
        else if (dig == 4'h3)
            temp = 7'b0110000;  // 3
        else if (dig == 4'h4)
            temp = 7'b0011001;  // 4
        else if (dig == 4'h5)
            temp = 7'b0010010;  // 5
        else if (dig == 4'h6)
            temp = 7'b0000010;  // 6
        else if (dig == 4'h7)
            temp = 7'b1111000;  // 7
        else if (dig == 4'h8)
            temp = 7'b0000000;  // 8
        else if (dig == 4'h9)
            temp = 7'b0010000;  // 9
        else if (dig == 4'hA)
            temp = 7'b0001000;  // A
        else if (dig == 4'hB)
            temp = 7'b0000011;  // b
        else if (dig == 4'hC)
            temp = 7'b1000110;  // C
        else if (dig == 4'hD)
            temp = 7'b0100001;  // d
        else if (dig == 4'hE)
            temp = 7'b0000110;  // E
        else if (dig == 4'hF)
            temp = 7'b0001110;  // F
        else
            temp = 7'b1111111;  // display off (invalid input)
    end
endmodule

module memory_io_unit (
	/* Inputs are from the execute/memory pipeline register */
	input [31:0] data_to_store,	// only used when storing: regsiter => memory address
					// bytes may be unused if storing halfword & byte
	input [4:0] memory_access_code, // from the op-code: specifies load/store & data size
	input [31:0] memory_address,	// up to 2^18
	input clock,			// clock is only used for storing
	input [1:0] prev_r,			// used for loading
	/* Output is sent DIRECTLY to writeback module, as a wire */
	output [31:0] writeback_register_data,	// only used when loading: memory address => register
	output [1:0] r
);
	
	wire store; // 1: storing in memory, 0: loading from memory
	assign store = memory_access_code[4];
	wire [3:0] byte_enable; // determines which 4 bytes will be written or stored
	assign byte_enable = memory_access_code[3:0];

	// Each B-RAM uses a 16 bit address and loads/stores bytes
	wire [15:0] B_address [3:0];	// 4 addresses for loading/storing up to 4 bytes
	wire [7:0] B_data_to_write [3:0];
	wire [7:0] B_data_to_read [3:0];
	wire [3:0] B_write_enable;

	// bram3 => addresses 4k + 0,
	// bram2 => addresses 4k + 1,
	// bram1 => addresses 4k + 2,
	// bram0 => addresses 4k + 3, k is an integer
	
	// Given a memory address, we need to find the right addresses in the BRAM
	// remainder from memory address divided by 4
	assign r = memory_address[1:0];
	assign B_address[3] = (r < 2'd1) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[2] = (r < 2'd2) ? (memory_address[17:2]) : (memory_address[17:2] + 1); 
	assign B_address[1] = (r < 2'd3) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[0] = (memory_address[17:2]); // r < 4 always


	// The tricky part: which BRAM corresponds to each byte of the data to write?
	// The assignments rotate based on the remainder
	assign B_data_to_write[3] =
	(r == 2'd0) ? data_to_store[31:24] :
	(r == 2'd1) ? data_to_store[ 7: 0] :
	(r == 2'd2) ? data_to_store[15: 8] :
	/*r == 2'd3*/ data_to_store[23:16];

	assign B_data_to_write[2] =
	(r == 2'd0) ? data_to_store[23:16] :
	(r == 2'd1) ? data_to_store[31:24] :
	(r == 2'd2) ? data_to_store[ 7: 0] :
	/*r == 2'd3*/ data_to_store[15: 8];

	assign B_data_to_write[1] =
	(r == 2'd0) ? data_to_store[15: 8] :
	(r == 2'd1) ? data_to_store[23:16] :
	(r == 2'd2) ? data_to_store[31:24] :
	/*r == 2'd3*/ data_to_store[ 7: 0];

	assign B_data_to_write[0] =
	(r == 2'd0) ? data_to_store[ 7: 0] :
	(r == 2'd1) ? data_to_store[15: 8] :
	(r == 2'd2) ? data_to_store[23:16] :
	/*r == 2'd3*/ data_to_store[31:24];

	// Similarly, the write enable will also rotate, and is only enabled if we are storing
	assign B_write_enable[3] = store & (
	(r == 2'd0) ? byte_enable[3] :
	(r == 2'd1) ? byte_enable[0] :
	(r == 2'd2) ? byte_enable[1] :
	/*r == 2'd3*/ byte_enable[2]
	);

	assign B_write_enable[2] = store & (
	(r == 2'd0) ? byte_enable[2] :
	(r == 2'd1) ? byte_enable[3] :
	(r == 2'd2) ? byte_enable[0] :
	/*r == 2'd3*/ byte_enable[1]
	);

	assign B_write_enable[1] = store & (
	(r == 2'd0) ? byte_enable[1] :
	(r == 2'd1) ? byte_enable[2] :
	(r == 2'd2) ? byte_enable[3] :
	/*r == 2'd3*/ byte_enable[0]
	);

	assign B_write_enable[0] = store & (
	(r == 2'd0) ? byte_enable[0] :
	(r == 2'd1) ? byte_enable[1] :
	(r == 2'd2) ? byte_enable[2] :
	/*r == 2'd3*/ byte_enable[3]
	);

	// The order of consecutive bytes we want to read from the BRAM also rotates
	assign writeback_register_data[31:24] =
    	(prev_r == 2'd0) ? B_data_to_read[3] :
	(prev_r == 2'd1) ? B_data_to_read[0] :
	(prev_r == 2'd2) ? B_data_to_read[1] :
	/*prev_r == 2'd3*/ B_data_to_read[2];
	
	assign writeback_register_data[23:16] =
	(prev_r == 2'd0) ? B_data_to_read[2] :
	(prev_r == 2'd1) ? B_data_to_read[3] :
	(prev_r == 2'd2) ? B_data_to_read[0] :
	/*prev_r == 2'd3*/ B_data_to_read[1];
	
	assign writeback_register_data[15:8] =
	(prev_r == 2'd0) ? B_data_to_read[1] :
	(prev_r == 2'd1) ? B_data_to_read[2] :
	(prev_r == 2'd2) ? B_data_to_read[3] :
	/*prev_r == 2'd3*/ B_data_to_read[0];
	
	assign writeback_register_data[7:0] =
    	(prev_r == 2'd0) ? B_data_to_read[0] :
    	(prev_r == 2'd1) ? B_data_to_read[1] :
    	(prev_r == 2'd2) ? B_data_to_read[2] :
	/*prev_r == 2'd3*/ B_data_to_read[3];

	/* TO-DO: MAKE MODULES TO ACCESS B-RAMs */
	

	// --- instantiate 4 byte-wide BRAMs (synchronous) ---

    bram0 bram0 (
        .clock(clock),
        .wren(B_write_enable[0]),
        .address(B_address[0]),
        .data(B_data_to_write[0]),
        .q(B_data_to_read[0])
    );

    bram1 bram1 (
        .clock(clock),
        .wren(B_write_enable[1]),
        .address(B_address[1]),
        .data(B_data_to_write[1]),
        .q(B_data_to_read[1])
    );
    
	 bram2 bram2 (
        .clock(clock),
        .wren(B_write_enable[2]),
        .address(B_address[2]),
        .data(B_data_to_write[2]),
        .q(B_data_to_read[2])
    );
    
	 bram3 bram3 (
        .clock(clock),
        .wren(B_write_enable[3]),
        .address(B_address[3]),
        .data(B_data_to_write[3]),
        .q(B_data_to_read[3])
    );


endmodule
	
module memory_for_vga (
	/* Inputs are from the execute/memory pipeline register */
	input [31:0] data_to_store,
	input [4:0] memory_access_code, 
	input [31:0] memory_address,
	input clock,			
	input [1:0] prev_r,	
	/* Outputs are sent to memory/writeback pipeline register, for memory instructions */
	output [31:0] writeback_register_data,	// Unused, don't connnect to anything
	output [1:0] r,
	output [255:0] memory_first_32_bytes // Array of first 32 bytes in memory
);
	
	wire store; // 1: storing in memory, 0: loading from memory
	assign store = memory_access_code[4];
	wire [3:0] byte_enable; // determines which 4 bytes will be written or stored
	assign byte_enable = memory_access_code[3:0];

	// Each B-RAM uses a 16 bit address and loads/stores bytes
	wire [15:0] B_address [3:0];	// 4 addresses for loading/storing up to 4 bytes
	wire [7:0] B_data_to_write [3:0];
	wire [7:0] B_data_to_read [3:0];
	wire [3:0] B_write_enable;

	// bram3 => addresses 4k + 0,
	// bram2 => addresses 4k + 1,
	// bram1 => addresses 4k + 2,
	// bram0 => addresses 4k + 3, k is an integer
	
	// Given a memory address, we need to find the right addresses in the BRAM
	// remainder from memory address divided by 4
	assign r = memory_address[1:0];
	assign B_address[3] = (r < 2'd1) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[2] = (r < 2'd2) ? (memory_address[17:2]) : (memory_address[17:2] + 1); 
	assign B_address[1] = (r < 2'd3) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[0] = (memory_address[17:2]); // r < 4 always


	// The tricky part: which BRAM corresponds to each byte of the data to write?
	// The assignments rotate based on the remainder
	assign B_data_to_write[3] =
	(r == 2'd0) ? data_to_store[31:24] :
	(r == 2'd1) ? data_to_store[ 7: 0] :
	(r == 2'd2) ? data_to_store[15: 8] :
	/*r == 2'd3*/ data_to_store[23:16];

	assign B_data_to_write[2] =
	(r == 2'd0) ? data_to_store[23:16] :
	(r == 2'd1) ? data_to_store[31:24] :
	(r == 2'd2) ? data_to_store[ 7: 0] :
	/*r == 2'd3*/ data_to_store[15: 8];

	assign B_data_to_write[1] =
	(r == 2'd0) ? data_to_store[15: 8] :
	(r == 2'd1) ? data_to_store[23:16] :
	(r == 2'd2) ? data_to_store[31:24] :
	/*r == 2'd3*/ data_to_store[ 7: 0];

	assign B_data_to_write[0] =
	(r == 2'd0) ? data_to_store[ 7: 0] :
	(r == 2'd1) ? data_to_store[15: 8] :
	(r == 2'd2) ? data_to_store[23:16] :
	/*r == 2'd3*/ data_to_store[31:24];

	// Similarly, the write enable will also rotate, and is only enabled if we are storing
	assign B_write_enable[3] = store & (
	(r == 2'd0) ? byte_enable[3] :
	(r == 2'd1) ? byte_enable[0] :
	(r == 2'd2) ? byte_enable[1] :
	/*r == 2'd3*/ byte_enable[2]
	);

	assign B_write_enable[2] = store & (
	(r == 2'd0) ? byte_enable[2] :
	(r == 2'd1) ? byte_enable[3] :
	(r == 2'd2) ? byte_enable[0] :
	/*r == 2'd3*/ byte_enable[1]
	);

	assign B_write_enable[1] = store & (
	(r == 2'd0) ? byte_enable[1] :
	(r == 2'd1) ? byte_enable[2] :
	(r == 2'd2) ? byte_enable[3] :
	/*r == 2'd3*/ byte_enable[0]
	);

	assign B_write_enable[0] = store & (
	(r == 2'd0) ? byte_enable[0] :
	(r == 2'd1) ? byte_enable[1] :
	(r == 2'd2) ? byte_enable[2] :
	/*r == 2'd3*/ byte_enable[3]
	);

	// The order of consecutive bytes we want to read from the BRAM also rotates
	assign writeback_register_data[31:24] =
    	(prev_r == 2'd0) ? B_data_to_read[3] :
	(prev_r == 2'd1) ? B_data_to_read[0] :
	(prev_r == 2'd2) ? B_data_to_read[1] :
	/*prev_r == 2'd3*/ B_data_to_read[2];
	
	assign writeback_register_data[23:16] =
	(prev_r == 2'd0) ? B_data_to_read[2] :
	(prev_r == 2'd1) ? B_data_to_read[3] :
	(prev_r == 2'd2) ? B_data_to_read[0] :
	/*prev_r == 2'd3*/ B_data_to_read[1];
	
	assign writeback_register_data[15:8] =
	(prev_r == 2'd0) ? B_data_to_read[1] :
	(prev_r == 2'd1) ? B_data_to_read[2] :
	(prev_r == 2'd2) ? B_data_to_read[3] :
	/*prev_r == 2'd3*/ B_data_to_read[0];
	
	assign writeback_register_data[7:0] =
    	(prev_r == 2'd0) ? B_data_to_read[0] :
    	(prev_r == 2'd1) ? B_data_to_read[1] :
    	(prev_r == 2'd2) ? B_data_to_read[2] :
	/*prev_r == 2'd3*/ B_data_to_read[3];

	/* NEW FOR VGA */

	// --- instantiate 4 byte-wide BRAMs (synchronous) ---
	wire [63:0] mem_4k_3;
	wire [63:0] mem_4k_2;
	wire [63:0] mem_4k_1;
	wire [63:0] mem_4k_0;
	
	assign memory_first_32_bytes = {
		mem_4k_0[7:0],   mem_4k_1[7:0],   mem_4k_2[7:0],   mem_4k_3[7:0],
		mem_4k_0[15:8],  mem_4k_1[15:8],  mem_4k_2[15:8],  mem_4k_3[15:8],
		mem_4k_0[23:16], mem_4k_1[23:16], mem_4k_2[23:16], mem_4k_3[23:16],
		mem_4k_0[31:24], mem_4k_1[31:24], mem_4k_2[31:24], mem_4k_3[31:24],
		mem_4k_0[39:32], mem_4k_1[39:32], mem_4k_2[39:32], mem_4k_3[39:32],
		mem_4k_0[47:40], mem_4k_1[47:40], mem_4k_2[47:40], mem_4k_3[47:40],
		mem_4k_0[55:48], mem_4k_1[55:48], mem_4k_2[55:48], mem_4k_3[55:48],
		mem_4k_0[63:56], mem_4k_1[63:56], mem_4k_2[63:56], mem_4k_3[63:56]
	};
	
    bram_8_bytes bram0 (
        .clk(~clock),
        .we(B_write_enable[0]),
        .addr(B_address[0]),
        .din(B_data_to_write[0]),
        .dout(B_data_to_read[0]),
		.memory_array(mem_4k_3)
    );

    bram_8_bytes bram1 (
        .clk(~clock),
        .we(B_write_enable[1]),
        .addr(B_address[1]),
        .din(B_data_to_write[1]),
        .dout(B_data_to_read[1]),
		.memory_array(mem_4k_2)
    );

    bram_8_bytes bram2 (
        .clk(~clock),
        .we(B_write_enable[2]),
        .addr(B_address[2]),
        .din(B_data_to_write[2]),
        .dout(B_data_to_read[2]),
		.memory_array(mem_4k_1)
    );

    bram_8_bytes bram3 (
        .clk(~clock),
        .we(B_write_enable[3]),
        .addr(B_address[3]),
        .din(B_data_to_write[3]),
        .dout(B_data_to_read[3]),
		.memory_array(mem_4k_0)
    );
	
	

endmodule

// simple_sync_bram.v
// Generic single-port synchronous BRAM model for simulation

module bram_8_bytes (
    input  wire        clk,
    input  wire        we,
    input  wire [15:0] addr,
    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    output wire [63:0] memory_array  
);

    // memory array (8 bytes)
    reg [7:0] mem [7:0];

    always @(posedge clk) begin
        if (we && (addr < 16'd8))
            mem[addr] <= din;
        dout <= mem[addr];
    end

    assign memory_array[7:0]    = mem[0];
    assign memory_array[15:8]   = mem[1];
    assign memory_array[23:16]  = mem[2];
    assign memory_array[31:24]  = mem[3];
    assign memory_array[39:32]  = mem[4];
    assign memory_array[47:40]  = mem[5];
    assign memory_array[55:48]  = mem[6];
    assign memory_array[63:56]  = mem[7];

endmodule
