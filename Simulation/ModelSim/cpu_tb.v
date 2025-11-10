`timescale 1ns/1ps

module control_unit_tb;

  // DUT inputs
  reg  [9:0] SW;
  reg  [1:0] KEY;

  // DUT outputs
  wire [9:0] LEDR;
  wire [6:0] HEX0;
  wire [6:0] HEX1;

  // Instantiate DUT
  control_unit dut (
    .SW(SW),
    .KEY(KEY),
    .LEDR(LEDR),
    .HEX0(HEX0),
    .HEX1(HEX1)
  );

  // Clock generation on KEY[0]
  initial begin
    KEY[0] = 0;
    forever #5 KEY[0] = ~KEY[0]; // 10 ns period
  end

  // Main stimulus
  initial begin
    // Hold reset low
    KEY[1] = 0;     // resetn = 0
    SW     = 10'b0;
    #20;
    KEY[1] = 1;     // release reset

    // Instruction encoding (as per your comment):
    // bit7 = mode (we keep 0)
    // bits6:4 = opcode
    // bits3:2 = RegA (destination)
    // bits1:0 = RegB (second source)
    //
    // Your ALU supports:
    // ADD = 3'b001
    // INC = 3'b011

    // 1) INC R1
    // 0_011_00_00 = 8'h30
    SW[7:0] = 8'h30;
    // let FSM do F, D, E, W → about 4 cycles.
    // Our clock is 10 ns, so 40–80 ns is safe. Use 80 to be relaxed.
    #80;

    // 2) INC R1 again
    SW[7:0] = 8'h30;
    #80;

    // Now R1 should be 2.

    // 3) ADD R1, R1 -> R1
    // 0_001_00_00 = 8'h10
    SW[7:0] = 8'h10;
    #80;

    // At this point, since R1 was 2, ADD R1+R1 should give 4 into R1.

    // Print out internal values
    $display("t=%0t FINAL: R1=%0d R2=%0d state=%0d",
              $time, dut.R1, dut.R2, dut.present_state);

    #50;
    $stop;
  end

  // Optional live monitor
  initial begin
    $monitor("t=%0t clk=%b rstn=%b SW=%h state=%0d R1=%0d R2=%0d",
              $time, KEY[0], KEY[1], SW[7:0],
              dut.present_state, dut.R1, dut.R2);
  end

endmodule
