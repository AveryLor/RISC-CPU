module control_unit(SW, LEDR, KEY);
  // Hardware I/O
  input [7:0] SW;    // Machine code expressed on switches.
  input [1:0] KEY;   // Clock pulse 
  output [9:0] LEDR; // LEDR used to display register values (first 4 bits of R1 and R2).

  // Clock pulse and reset 
  wire clock_pulse = KEY[0];
  wire resetn = KEY[1];
  
  // Register file (for now).
  reg [31:0] R1; 
  reg [31:0] R2; 
  reg [7:0] IR; // Special-purpose instruction register.

    // Creating readable constants to represent each state.
  // (F)etch, (D)ecode, (E)xecute, (W)riteback
  parameter [1:0] F = 2'b00,
                  D = 2'b01,
                  E = 2'b10,
                  W = 2'b11;

  reg [1:0] present_state, next_state;

  // Command components for decoding.
  // Recall: Format for arithmetic isntruction encoding.
  /* 
     Mode  Opcode   RegA  RegB
     0     1 2 3    4 5   6 7
  */
  reg mode;
  reg [2:0] opcode;
  reg [1:0] register_encoding_1;
  reg [1:0] register_encoding_2;
  reg [31:0] register_value_1;
  reg [31:0] register_value_2;

  // Control to ALU
  reg execute_flag; 
  wire [31:0] arithmetic_result;
  
  // ALU instance 
  ALU alu_inst(mode, opcode, register_value_1, register_value_2, execute_flag, arithmetic_result);

  // Display the first 4 bits of R1 and R2 on LEDR
  assign LEDR[7:4] = R1[3:0];
  assign LEDR[3:0] = R2[3:0];
  
  // Next-state + dedicated stage logic: On each clock pulse, go to the next stage of the fetch-execute loop. 
  always @ (posedge clock_pulse, negedge resetn) begin // account for resetn? then it just turns everything to 0.
    present_state <= next_state;
    case (present_state)
      F: begin
        IR <= SW[7:0]; // Copying the current command into the instruction register
        next_state = D;
      end
      D: begin 
        mode <= IR[7]; 
        opcode <= IR[6:4];
        register_encoding_1 <= IR[3:2];
        register_encoding_2 <= IR[1:0];
  
        register_value_1 <= (IR[3:2] == 2'b00) ? R1 : R2;
        register_value_2 <= (IR[1:0]== 2'b00) ? R1 : R2;

        next_state = E;
      end
      E: begin 
        execute_flag <= 1'b1; // fires up the ALU!
        next_state = W;
      end
      W: begin
        execute_flag <= 1'b0;
        if (register_encoding_1 == 2'b00) 
          R1 <= arithmetic_result;
        else 
          R2 <= arithmetic_result;
        next_state = F;
      end
      default: next_state = F;
    endcase end
endmodule 

/* 
   Capable of performing two instructions:
    - add regA, regB (Adds values in regA and regB, then place tha value in regA)
    - inc reg (adds 1 to value inside of reg, then copies it back.)
 */
module ALU(mode, opcode, register_value_1, register_value_2, execute_flag, result);
  input mode; 
  input execute_flag;
  input [2:0] opcode;
  input [31:0] register_value_1;
  input [31:0] register_value_2;

  output reg [31:0] result; // first two bits are the destination register, rest are the actual result.

  parameter [2:0] ADD = 3'b001, 
                  INC = 3'b011;

  // The ALU will only fire up once it is given the OK by the execute flag.
  always @ (*) begin
    result = 32'b0;
    if (execute_flag)
      case (opcode)
        ADD: begin
          result = register_value_1 + register_value_2;
        end

        INC: begin
          result = register_value_1 + 1;
      end
    endcase
  end
endmodule
        
