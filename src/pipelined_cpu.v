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
  
  // General purpose
  wire [31:0] R0;
  wire [31:0] R1;
  wire [31:0] R2;
  wire [31:0] R3;
  wire [31:0] R4;
  wire [31:0] R5;
  wire [31:0] R6;
  wire [31:0] R7;

  // Pipeline registers
  wire [7:0] if_id_reg;

  instr_fetch instr_fetch_inst(clock_pulse, stall, instruction_state, if_id_reg);

  assign LEDR[7:0] = if_id_reg;
endmodule

module instr_fetch(clk, stall, switches_state, if_id_reg);
  input clk;
  input stall;
  input [7:0] switches_state; 
  output reg [7:0] if_id_reg;  // should be the size of our instruction. 

  always @ (posedge clk) begin // KEY[0] signal will be negative.
    if (stall == 0) if_id_reg <= switches_state;
    else if_id_reg <= if_id_reg;
  end
endmodule

