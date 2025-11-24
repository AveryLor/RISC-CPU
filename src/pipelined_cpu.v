module cpu(SW, LEDR, KEY, HEX0, HEX1);
  // Hardware I/O
  input [9:0] SW;
  input [2:0] KEY;
  output [9:0] LEDR;
  output [6:0] HEX0;x
  output [6:0] HEX1;

  // Necessary values
  wire [7:0] instruction_state = SW[7:0];

  // Clock pulse and reset
  wire clock_pulse = ~KEY[0];
  wire resetn = KEY[1];
  wire stall; // Controlled by HDU.

  //assign stall = 0;

  // Registers
  wire [31:0] IR; // Special purpose
  
  // Pipeline registers
  // IF/ID Registers
  wire [7:0] if_id_reg; // Doubles as ID_instruct
  
  // ID/EX Registers
  wire [7:0] ex_instruct; 
  wire id_ex_regwrite;
  wire id_ex_reg_mode;
  wire [2:0] id_ex_reg_opcode;
  wire [31:0] id_ex_reg_val1;
  wire [31:0] id_ex_reg_val2;
  wire [1:0] id_ex_reg_wb_enc; 
  
  // EX/MEM Registers
  wire [7:0] mem_instruct;
  wire ex_mem_regwrite;
  wire [31:0] ex_mem_reg_arithmetic_result;
  wire [1:0] ex_mem_reg_wb_enc;
  
  // MEM/WB Registers
  wire [7:0] wb_instruct;
  wire mem_wb_regwrite;
  wire [1:0] mem_wb_reg_wb_enc;
  wire [31:0] mem_wb_reg_arithmetic_result;

  // Register file conntrol
  wire we;
  wire [31:0] wdata; 
  wire [1:0] r_write_enc;

  wire [1:0] r_enc_0;
  wire [1:0] r_enc_1;

  wire [31:0] rf_out_val1;
  wire [31:0] rf_out_val2;

  wire [31:0] R0_val;
  wire [31:0] R1_val;

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
      .R1_val(R1_val)
  );

  // Hex display for register file
  display_hex display_hex_inst0(R0_val, HEX0);
  display_hex display_hex_inst1(R1_val, HEX1);

  // ALU Control 
  wire [2:0] alu_opcode;
  wire [31:0] alu_reg_val1;
  wire [31:0] alu_reg_val2;
  wire [31:0] alu_result; 

  wire bs;

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
 

  instr_fetch instr_fetch_inst(
      .clk(clock_pulse),
      .stall(stall),
      .resetn(resetn),

      .if_id_reg(if_id_reg),
		.pc_out(LEDR[1:0])
  );

  instr_decode instr_decode_inst(
      .clk(clock_pulse),
      .stall(stall),
      .resetn(resetn),

      .rf_enc_0(r_enc_0),
      .rf_enc_1(r_enc_1),

      .rf_out_val1(rf_out_val1),
      .rf_out_val2(rf_out_val2),

      .if_id_reg(if_id_reg), 

      .id_ex_reg_val1(id_ex_reg_val1),
      .id_ex_reg_val2(id_ex_reg_val2), 
      .id_ex_reg_mode(id_ex_reg_mode),
      .id_ex_reg_opcode(id_ex_reg_opcode),
      .id_ex_reg_wb_enc(id_ex_reg_wb_enc),
      .id_ex_regwrite(id_ex_regwrite),

      .ex_instruct(ex_instruct)
  );

  instr_execute instr_execute_inst(
      .clk(clock_pulse),
      .resetn(resetn),

      .alu_opcode(alu_opcode),
      .alu_reg_val1(alu_reg_val1),
      .alu_reg_val2(alu_reg_val2),
      .alu_result(alu_result),
      
      .id_ex_reg_opcode(id_ex_reg_opcode),
      .id_ex_reg_val1(id_ex_reg_val1),
      .id_ex_reg_val2(id_ex_reg_val2),
      .id_ex_regwrite(id_ex_regwrite),
      .id_ex_reg_wb_enc(id_ex_reg_wb_enc),

      .ex_mem_reg_wb_enc(ex_mem_reg_wb_enc),
      .ex_mem_regwrite(ex_mem_regwrite),
      .ex_mem_reg_arithmetic_result(ex_mem_reg_arithmetic_result),

      .ex_instruct(ex_instruct),
      .mem_instruct(mem_instruct)
  ); 
  
  instr_mem instr_mem_inst(
      .clk(clock_pulse),
      .resetn(resetn),

      .ex_mem_regwrite(ex_mem_regwrite),
      .ex_mem_reg_wb_enc(ex_mem_reg_wb_enc),
      .ex_mem_reg_arithmetic_result(ex_mem_reg_arithmetic_result),

      .mem_wb_reg_wb_enc(mem_wb_reg_wb_enc),
      .mem_wb_reg_arithmetic_result(mem_wb_reg_arithmetic_result),
      .mem_wb_regwrite(mem_wb_regwrite),

      .mem_instruct(mem_instruct),
      .wb_instruct(wb_instruct)

  );

  instr_wb instr_wb_inst(
      .clk(clock_pulse),

      .mem_wb_regwrite(mem_wb_regwrite),
      .mem_wb_reg_wb_enc(mem_wb_reg_wb_enc),
      .mem_wb_reg_arithmetic_result(mem_wb_reg_arithmetic_result),

      .rf_we(we),
      .rf_w_enc(r_write_enc),
      .rf_wdata(wdata)
  );
  
  // Testing decode: 
  assign LEDR[9:8] = if_id_reg[5:4];
  assign LEDR[7:6] = ex_instruct[5:4];
  assign LEDR[5:4] = mem_instruct[5:4];
  assign LEDR[3:2] = wb_instruct[5:4];
endmodule

// Register file module 
module reg_file(clk, resetn, we, r_enc_0, r_enc_1, r_write_enc, reg_out_0, reg_out_1, wdata, R0_val, R1_val); 
  input we; // Indicates if we are doing a write (write enable)
  input clk;
  input resetn;

  input [1:0] r_enc_0; // Register encodings 
  input [1:0] r_enc_1; 
  input [1:0] r_write_enc;
  input [31:0] wdata;

  output [31:0] R0_val;
  output [31:0] R1_val;
  
  output reg [31:0] reg_out_0;
  output reg [31:0] reg_out_1;
  
  // The actual registers =)
  reg [31:0] R0;
  reg [31:0] R1;

  // Reading registers
  // We use blocking assignments here because it behaves a little better in simulation.
  always @ (*) begin
    reg_out_0 = (r_enc_0 == 2'b00) ? R0 : R1;
    reg_out_1 = (r_enc_1 == 2'b00) ? R0 : R1;
  end
  
  // Writing to registers.
  always @ (negedge clk or negedge resetn) begin
    if (!resetn) begin
      R0 <= 32'd0;
      R1 <= 32'd0;
    end
    else if (we) begin
      if (r_write_enc == 2'b00) R0 <= wdata;
      else R1 <= wdata; 
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

module instr_fetch(clk, resetn, stall, if_id_reg, pc_out);
  input clk;
  input resetn;
  input stall;
  output [1:0] pc_out;
  reg [15:0] pc;				// program counter (new)
  output reg [7:0] if_id_reg;		// changed to 32 bits. instead of a reg, this is now a wire to a BRAM DataOut reg.

  wire [7:0] instr_rom_out;
  
  assign pc_out = pc;
  
  instr_rom instr_rom(
	.address(pc),
	.clock(clk),
	.data(),
	.wren(0),
	.q(instr_rom_out)
	
	);
  
  reg load_enable;
  
  reg [2:0] warmup_cnt;
  wire warmup_done = (warmup_cnt == 2'd2);
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
		if(!warmup_done) warmup_cnt <= warmup_cnt + 2'd1;
    end
	 
  end
endmodule

module instr_decode(clk, resetn, stall, rf_enc_0, rf_enc_1, rf_out_val1, rf_out_val2, if_id_reg, id_ex_reg_val1, id_ex_reg_val2, id_ex_reg_mode, id_ex_reg_opcode, id_ex_reg_wb_enc, id_ex_regwrite, ex_instruct);
  parameter [2:0] NOP = 3'b000;

  input clk;
  input stall;
  input resetn;

  input [7:0] if_id_reg;

  output reg id_ex_reg_mode;
  output reg [2:0] id_ex_reg_opcode;
  output reg [1:0] id_ex_reg_wb_enc;
  output reg id_ex_regwrite;

  output reg [31:0] id_ex_reg_val1;
  output reg [31:0] id_ex_reg_val2;

  output reg [7:0] ex_instruct;

  // Register file control
  output [1:0] rf_enc_0;
  output [1:0] rf_enc_1;

  input [31:0] rf_out_val1;
  input [31:0] rf_out_val2;
  
  // Must be purely combinational to get timing right.
  assign rf_enc_0 = if_id_reg[3:2];
  assign rf_enc_1 = if_id_reg[1:0];
  
  // values will be given by the register file once it is instantiated.
  always @ (posedge clk or negedge resetn) begin
    if (!resetn) begin
      id_ex_reg_mode <= 1'b0;
      id_ex_reg_opcode <= NOP;
      id_ex_reg_wb_enc <= 2'b00;
      id_ex_reg_val1 <= 32'd0;
      id_ex_reg_val2 <= 32'd0;
      id_ex_regwrite <= 1'b0;
      ex_instruct <= {1'b0, NOP, 2'b00, 2'b00};
    end
    else if (!stall) begin
      id_ex_reg_mode <= if_id_reg[7];
      id_ex_reg_opcode <= if_id_reg[6:4];
      id_ex_reg_wb_enc <= if_id_reg[3:2];

      id_ex_reg_val1 <= rf_out_val1;
      id_ex_reg_val2 <= rf_out_val2;

      ex_instruct <= if_id_reg;
      if (if_id_reg[6:4] != 3'b000) id_ex_regwrite <= 1;
      else id_ex_regwrite <= 0;
    end
    else begin
      id_ex_reg_mode <= 1'b0;
      id_ex_reg_opcode <= NOP;
      id_ex_reg_wb_enc <= 2'b00;
      id_ex_reg_val1 <= 32'd0;
      id_ex_reg_val2 <= 32'd0;
      id_ex_regwrite <= 1'b0;
      ex_instruct <= {1'b0, NOP, 2'b00, 2'b00};
    end
  end
endmodule

module instr_execute(clk, resetn, alu_opcode, alu_reg_val1, alu_reg_val2, alu_result, id_ex_reg_opcode, id_ex_reg_val1, id_ex_reg_val2, id_ex_regwrite, id_ex_reg_wb_enc, ex_mem_reg_wb_enc, ex_mem_regwrite, ex_mem_reg_arithmetic_result, ex_instruct, mem_instruct);
  input clk;
  input resetn;
  
  // From ID/EX pipeline
  input        id_ex_regwrite;
  input [1:0]  id_ex_reg_wb_enc;
  input [2:0]  id_ex_reg_opcode;
  input [31:0] id_ex_reg_val1;
  input [31:0] id_ex_reg_val2;
  
  input [7:0] ex_instruct;

  // EX/MEM pipeline registers
  output reg [1:0] ex_mem_reg_wb_enc;
  output reg ex_mem_regwrite;
  output reg [31:0] ex_mem_reg_arithmetic_result;

  output reg [7:0] mem_instruct;
  
  // To ALU (combinational - wires)  
  output [2:0] alu_opcode;

  output [31:0] alu_reg_val1;
  output [31:0] alu_reg_val2;
  
  // ALU output
  input [31:0] alu_result;
  
  assign alu_opcode = id_ex_reg_opcode;
  assign alu_reg_val1 = id_ex_reg_val1;
  assign alu_reg_val2 = id_ex_reg_val2;

  always @ (posedge clk or negedge resetn) begin
    if (!resetn) begin
      ex_mem_reg_wb_enc <= 2'b00;
      ex_mem_regwrite <= 1'b0;
      ex_mem_reg_arithmetic_result <= 32'd0;
      mem_instruct <= 8'b0;
    end
    else begin
      ex_mem_reg_wb_enc <= id_ex_reg_wb_enc;
      ex_mem_regwrite <= id_ex_regwrite;
      ex_mem_reg_arithmetic_result <= alu_result;
      mem_instruct <= ex_instruct;
    end
  end
endmodule

module instr_mem(clk, resetn, ex_mem_regwrite, ex_mem_reg_wb_enc, ex_mem_reg_arithmetic_result, mem_wb_reg_wb_enc, mem_wb_reg_arithmetic_result, mem_wb_regwrite, mem_instruct, wb_instruct);
  parameter [2:0] NOP = 3'b000;
  input clk;
  input resetn;

  input [1:0] ex_mem_reg_wb_enc;
  input [31:0] ex_mem_reg_arithmetic_result;
  input ex_mem_regwrite;
  input [7:0] mem_instruct;
  
  output reg [1:0] mem_wb_reg_wb_enc;
  output reg [31:0] mem_wb_reg_arithmetic_result;
  output reg mem_wb_regwrite;
  output reg [7:0] wb_instruct;
  
  always @ (posedge clk or negedge resetn) begin
    if (!resetn) begin
      mem_wb_reg_wb_enc <= 0;
      mem_wb_reg_arithmetic_result <= 0;
      mem_wb_regwrite <= 0;
      wb_instruct <= {1'b0, NOP, 2'b00, 2'b00};
    end
    else begin
      mem_wb_reg_wb_enc <= ex_mem_reg_wb_enc;
      mem_wb_reg_arithmetic_result <= ex_mem_reg_arithmetic_result;
      mem_wb_regwrite <= ex_mem_regwrite;

      wb_instruct <= mem_instruct;
    end
  end
endmodule

module instr_wb(clk, mem_wb_regwrite, mem_wb_reg_wb_enc, mem_wb_reg_arithmetic_result, rf_we, rf_w_enc, rf_wdata); 
  input clk;

  input mem_wb_regwrite;
  input [1:0] mem_wb_reg_wb_enc;
  input [31:0] mem_wb_reg_arithmetic_result;

  output reg rf_we;
  output reg [1:0] rf_w_enc; 
  output reg [31:0] rf_wdata;

  always @ (posedge clk) begin
    rf_we <= mem_wb_regwrite;
    rf_w_enc <= mem_wb_reg_wb_enc; 
    rf_wdata <= mem_wb_reg_arithmetic_result;
  end
endmodule

module HDU(ID_instruct, EX_instruct, MEM_instruct, WB_instruct, stall, out);
  // I am going to assume we shove the whole instruction through the pipeline.
  parameter [2:0] NOP = 3'b000,
                  ADD = 3'b001,
                  INC = 3'b011;

  input [7:0] ID_instruct;
  input [7:0] EX_instruct;
  input [7:0] MEM_instruct;
  input [7:0] WB_instruct; 

  output reg stall; // This is the stall signal!
  output out;

  wire [2:0] ID_opcode;
  wire [1:0] ID_reg1;
  wire [1:0] ID_reg2;
  
  wire [2:0] EX_opcode;
  wire [1:0] EX_reg1; 

  wire [2:0] MEM_opcode;
  wire [1:0] MEM_reg1;

  wire [2:0] WB_opcode;
  wire [1:0] WB_reg1;

  // have some assigns with the inputs to the wires
  assign ID_opcode = ID_instruct[6:4];
  assign EX_opcode = EX_instruct[6:4];
  assign MEM_opcode = MEM_instruct[6:4];
  assign WB_opcode = WB_instruct[6:4];

  assign ID_reg1 = ID_instruct[3:2]; 
  assign ID_reg2 = ID_instruct[1:0];

  assign EX_reg1 = EX_instruct[3:2];
  assign MEM_reg1 = MEM_instruct[3:2];
  assign WB_reg1 = WB_instruct[3:2];


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
