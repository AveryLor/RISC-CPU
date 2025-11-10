module control_unit(SW, LEDR, KEY, HEX0, HEX1);
  // Hardware I/O
  input [9:0] SW;    // Machine code expressed on switches.
  input [1:0] KEY;   // Clock pulse
  output [9:0] LEDR; // LEDR used to display register values (first 4 bits of R1 and R2).
  output [6:0] HEX0;
  output [6:0] HEX1;
 
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
 
  parameter [2:0] ADD = 3'b001,
                  INC = 3'b011;
 
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
  ALU alu_inst(opcode, arithmetic_result, register_value_1, register_value_2);
 
  // Display R1 on the hex display.
  display_hex hex_displayer1(R1, HEX0);
  display_hex hex_displayer2(R2, HEX1);

  // Next-state + dedicated stage logic: On each clock pulse, go to the next stage of the fetch-execute loop.
  always @ (negedge clock_pulse, negedge resetn) begin // account for resetn? then it just turns everything to 0.
    if (!resetn) begin
      mode <= 0;
      opcode <= 0;
      register_encoding_1 <= 0;
      register_encoding_2 <= 0;
      register_value_1 <= 0;
      register_value_2 <= 0;
 
      R1 <= 0;
      R2 <= 0;
      IR <= 0;
    end
    else begin
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
        next_state = W;
      end
      W: begin
        if (register_encoding_1 == 2'b00)
          R1 <= arithmetic_result;
        else
          R2 <= arithmetic_result;
        next_state = F;
      end
      default: next_state = F;
    endcase end
  end
 
  // State Flip-Flops
  always @ (posedge clock_pulse, negedge resetn) begin
    if (!resetn)
      present_state <= F;
    else
      present_state <= next_state;
  end
 
  // assign LEDR values to the current state value.
  assign LEDR[1:0] = present_state;
endmodule

/* This is the ALU module */
/* Capable of performing ADD and INC instructions */
module ALU(opcode, arithmetic_result, register_value_1, register_value_2);
  parameter [2:0] ADD = 3'b001,
                  INC = 3'b011;

  input [2:0] opcode;
  input [31:0] register_value_1;
  input [31:0] register_value_2;
  
  output reg [31:0] arithmetic_result;
  always @ (*) begin
    case (opcode) 
      ADD: arithmetic_result <= register_value_1 + register_value_2; 
      INC: arithmetic_result <= register_value_1 + 1; 
    endcase
  end
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
