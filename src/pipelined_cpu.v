module control_unit(SW, LEDR, KEY, HEX0, HEX1);
  // Hardware I/O
  input [9:0] SW;
  input [2:0] KEY;
  output [9:0] LEDR;
  output [6:0] HEX0;
  output [6:0] HEX1;


  // Necessary values
  wire [7:0] instruction_state = SW[7:0];

  // Clock pulse and reset
  wire clock_pulse = ~KEY[0];
  wire resetn = KEY[1];
  wire stall = ~KEY[2]; // This will be changed later. It is kept just for testing the module.

  // Registers
  wire [31:0] IR; // Special purpose
  
  // Pipeline registers
  wire [7:0] if_id_reg;
  
  wire id_ex_reg_mode;
  wire [2:0] id_ex_reg_opcode;
  wire [31:0] id_ex_reg_val1;
  wire [31:0] id_ex_reg_val2;
  wire [31:0] id_ex_reg_wb_enc; 


  // Register file conntrol
  wire we;
  wire [31:0] wdata; 
  wire [1:0] r_write_enc;

  wire [1:0] r_enc_0;
  wire [1:0] r_enc_1;

  // Register file instantiation
  reg_file reg_file_inst(clk, we, r_enc_0, r_enc_1, r_write_enc, id_ex_reg_val1, id_ex_reg_val2, wdata); 
  
  instr_fetch instr_fetch_inst(clock_pulse, stall, instruction_state, if_id_reg);
  instr_decode instr_decode_inst(clock_pulse, stall, r_enc_0, r_enc_1, if_id_reg, id_ex_reg_mode, id_ex_reg_opcode, id_ex_reg_wb_enc);
  
  assign LEDR[9:7] = if_id_reg[6:4];
  assign LEDR[6:4] = id_ex_reg_opcode; 
endmodule

// Register file module 
module reg_file(clk, we, r_enc_0, r_enc_1, r_write_enc, reg_out_0, reg_out_1, wdata); // this will stay combinational for reads and will become sequential when writes are added.
  input we; // Indicates if we are doing a write (write enable)
  input clk;

  input [1:0] r_enc_0; // Register encodings 
  input [1:0] r_enc_1; 
  input [1:0] r_write_enc;
  input [31:0] wdata;

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
  always @ (posedge clk) begin
    if (we) begin
      if (r_write_enc == 2'b00) R0 <= wdata;
      else R1 <= wdata; 
    end
  end
endmodule


module instr_fetch(clk, stall, switches_state, if_id_reg);
  input clk;
  input stall;
  input [7:0] switches_state; 
  output reg [7:0] if_id_reg;  

  always @ (posedge clk) begin 
    if (stall == 0) if_id_reg <= switches_state;
    else if_id_reg <= if_id_reg;
  end
endmodule

module instr_decode(clk, stall, rf_enc_0, rf_enc_1, if_id_reg, id_ex_reg_mode, id_ex_reg_opcode, id_ex_reg_wb_enc);
  input clk;
  input stall;
  input [7:0] if_id_reg;
  
  output reg id_ex_reg_mode;
  output reg [2:0] id_ex_reg_opcode;
  output reg [1:0] id_ex_reg_wb_enc;

  // Register file control
  output reg [1:0] rf_enc_0;
  output reg [1:0] rf_enc_1;
  
  // values will be given by the register file once it is instantiated.
  always @ (posedge clk) begin
    if (!stall) begin
      id_ex_reg_mode <= if_id_reg[7];
      id_ex_reg_opcode <= if_id_reg[6:4];
      id_ex_reg_wb_enc <= if_id_reg[3:2];

      rf_enc_0 <= if_id_reg[3:2];
      rf_enc_1 <= if_id_reg[1:0];
    end
  end
endmodule
