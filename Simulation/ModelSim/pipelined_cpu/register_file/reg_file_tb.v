`timescale 1ns/1ps

module reg_file_tb;

  // Inputs to DUT
  reg         clk;
  reg         resetn;
  reg         we;
  reg  [1:0]  r_enc_0;
  reg  [1:0]  r_enc_1;
  reg  [1:0]  r_write_enc;
reg  [31:0] wdata;

  // Outputs from DUT
  wire [31:0] R0_val;
  wire [31:0] R1_val;
  wire [31:0] reg_out_0;
  wire [31:0] reg_out_1;

  // Instantiate the DUT
  reg_file dut (
    .clk        (clk),
    .resetn     (resetn),
    .we         (we),
    .r_enc_0    (r_enc_0),
    .r_enc_1    (r_enc_1),
    .r_write_enc(r_write_enc),
    .reg_out_0  (reg_out_0),
    .reg_out_1  (reg_out_1),
    .wdata      (wdata),
    .R0_val     (R0_val),
    .R1_val     (R1_val)
  );

  // Clock generator: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Simple task to perform a write on the negedge
  task write_reg;
    input [1:0]  enc;
    input [31:0] value;
  begin
    we         = 1'b1;
    r_write_enc = enc;
    wdata      = value;
    @(negedge clk);   // write happens here
    we         = 1'b0;
  end
  endtask

  // Simple task to set read encodings
  task set_read_encodings;
    input [1:0] enc0;
    input [1:0] enc1;
  begin
    r_enc_0 = enc0;
    r_enc_1 = enc1;
    #1; // small delay to let combinational outputs settle
  end
  endtask

  initial begin
    // Initialize inputs
    we         = 0;
    r_enc_0    = 2'b00;
    r_enc_1    = 2'b00;
    r_write_enc= 2'b00;
    wdata      = 32'd0;

    // Apply reset
    resetn = 0;
    @(negedge clk);
    @(negedge clk);
    resetn = 1;

    // After reset, R0 and R1 should both be 3
    set_read_encodings(2'b00, 2'b01);
    $display("Time %0t: After reset R0_val=%0d R1_val=%0d reg_out_0=%0d reg_out_1=%0d",
             $time, R0_val, R1_val, reg_out_0, reg_out_1);

    // Write 10 into R0
    write_reg(2'b00, 32'd10);
    // Read both registers: r_enc_0 selects R0, r_enc_1 selects R1
    set_read_encodings(2'b00, 2'b01);
    $display("Time %0t: After write R0=10, R0_val=%0d R1_val=%0d reg_out_0=%0d reg_out_1=%0d",
             $time, R0_val, R1_val, reg_out_0, reg_out_1);

    // Write 20 into R1
    write_reg(2'b01, 32'd20);
    set_read_encodings(2'b00, 2'b01);
    $display("Time %0t: After write R1=20, R0_val=%0d R1_val=%0d reg_out_0=%0d reg_out_1=%0d",
             $time, R0_val, R1_val, reg_out_0, reg_out_1);

    // Swap read encodings to check both ports
    set_read_encodings(2'b01, 2'b00);
    $display("Time %0t: Swap read ports, R0_val=%0d R1_val=%0d reg_out_0=%0d reg_out_1=%0d",
             $time, R0_val, R1_val, reg_out_0, reg_out_1);

    // Test that we=0 prevents writes
    write_reg(2'b00, 32'd99);
    // Force we low so the task does not write this time
    we = 1'b0;
    r_write_enc = 2'b00;
    wdata = 32'd123;
    @(negedge clk);  // no write should occur
    set_read_encodings(2'b00, 2'b01);
    $display("Time %0t: After blocked write, R0_val=%0d R1_val=%0d reg_out_0=%0d reg_out_1=%0d",
             $time, R0_val, R1_val, reg_out_0, reg_out_1);

    $display("Testbench finished at time %0t", $time);
    $stop;
  end

endmodule
