module reg_file(clk, resetn, we, r_enc_0, r_enc_1, r_write_enc, reg_out_0, reg_out_1, wdata, R0_val, R1_val); 
  parameter [2:0] R0_ENC = 3'b000,
                  R1_ENC = 3'b001,
                  R2_ENC = 3'b010,
                  R3_ENC = 3'b011,
                  R4_ENC = 3'b100,
                  R5_ENC = 3'b101,
                  R6_ENC = 3'b110,
                  R7_ENC = 3'b111;

  input [1;0] we; // Indicates if we are doing a write (write enable)
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
    endcase
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
    if (we[0]) begin
      case (r_write_enc) 
        R0_ENC: R0[15:0] <= wdata[15:0]; 
        R1_ENC: R1[15:0] <= wdata[15:0];
        R2_ENC: R2[15:0] <= wdata[15:0];
        R3_ENC: R3[15:0] <= wdata[15:0];
        R4_ENC: R4[15:0] <= wdata[15:0];
        R5_ENC: R5[15:0] <= wdata[15:0];
        R6_ENC: R6[15:0] <= wdata{15:0];
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
        R6_ENC: R6[31:16] <= wdata{31:16];
        R7_ENC: R7[31:16] <= wdata[31:16];
      endcase
    end
  end

  assign R0_val = R0; 
  assign R1_val = R1;
endmodule
