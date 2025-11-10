`timescale 1ns/1ps

module control_unit_tb;

  // DUT inputs
  reg  [9:0] SW;
  reg  [1:0] KEY;

  // DUT outputs
  wire [9:0] LEDR;
  wire [6:0] HEX0;
  wire [6:0] HEX1;

  // Instantiate the DUT
  control_unit dut (
    .SW(SW),
    .KEY(KEY),
    .LEDR(LEDR),
    .HEX0(HEX0),
    .HEX1(HEX1)
  );

  // Clock generation: KEY[0] is the clock
  initial begin
    KEY[0] = 0;
    forever #5 KEY[0] = ~KEY[0];   // 10 ns period
  end

  // Stimulus
  initial begin
    // start with reset asserted
    KEY[1] = 0;     // resetn = 0
    SW     = 10'b0;
    #20;
    KEY[1] = 1;     // release reset

    // Instruction format (for your design):
    // bit7 = mode (unused here, keep 0)
    // bits6:4 = opcode
    // bits3:2 = dest/source register
    // bits1:0 = second source register

    // 1. INC R1
    // opcode = 3'b011
    // dest = 00 (R1)
    // src2 = 00 (does not matter for INC)
    // instruction = 0_011_00_00 = 8'h30
    SW[7:0] = 8'h30;
    #80;   // let the FSM go through F, D, E, W

    // 2. INC R1 again
    SW[7:0] = 8'h30;
    #80;

    // At this point R1 should be 2

    // 3. ADD R1, R1 -> R1
    // opcode = 3'b001
    // dest = 00 (R1)
    // src2 = 00 (R1)
    // instruction = 0_001_00_00 = 8'h10
    SW[7:0] = 8'h10;
    #80;

    // After this, R1 should be 4 because it added R1 to R1

    // Show results in transcript
    $display("Time %0t: R1 = %0d, R2 = %0d, state = %0d",
              $time, dut.R1, dut.R2, dut.present_state);

    // Keep some time to look at waveforms
    #50;
    $stop;
  end

endmodule
