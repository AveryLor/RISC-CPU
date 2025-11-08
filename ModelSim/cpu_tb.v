`timescale 1ns/1ps

// Simple stub so the DUT can compile
module display_hex(input [31:0] value, output [6:0] hex);
  assign hex = 7'b0000000;
endmodule

module control_unit_tb;

  // Testbench signals
  reg  [9:0] SW;
  reg  [1:0] KEY;   // KEY[0] = clock, KEY[1] = resetn
  wire [9:0] LEDR;
  wire [6:0] HEX0;
  wire [6:0] HEX1;

  // Instantiate DUT
  control_unit dut (
    .SW(SW),
    .LEDR(LEDR),
    .KEY(KEY),
    .HEX0(HEX0),
    .HEX1(HEX1)
  );

  // Clock generation for KEY[0]
  initial begin
    KEY[0] = 0;
    forever #5 KEY[0] = ~KEY[0];  // 10 ns period
  end

  // Main stimulus
  initial begin
    // Initialize
    SW    = 10'b0;
    KEY[1] = 0;      // hold reset low
    #20;
    KEY[1] = 1;      // release reset

    // Wait until DUT is in Fetch state (LEDR[1:0] == 2'b00)
    wait (LEDR[1:0] == 2'b00);

    // Instruction encoding in your design:
    // [7]   = mode (0 for now)
    // [6:4] = opcode
    // [3:2] = regA (destination in W)
    // [1:0] = regB
    //
    // Opcodes
    // ADD = 3'b001
    // INC = 3'b011
    //
    // R1 is encoded as 2'b00
    // R2 is encoded as anything else (2'b01 is fine)

    // 1) INC R1: 0_011_00_00 = 8'b00110000 = 0x30
    apply_instr(8'h30);

    // 2) INC R1 again
    apply_instr(8'h30);

    // 3) ADD R1,R1: 0_001_00_00 = 8'b00010000 = 0x10
    apply_instr(8'h10);

    // Let it run a bit
    #50;
    $finish;
  end

  // Task to apply a single instruction
  // It waits for Fetch, drives SW, then waits for the full F-D-E-W cycle to complete
  task apply_instr(input [7:0] instr);
  begin
    // Wait until we get to Fetch so IR will sample SW on the next negedge
    wait (LEDR[1:0] == 2'b00);
    SW[7:0] = instr;

    // One full cycle through D, E, W
    // Each state change happens on posedge, work on negedge,
    // so waiting 4 posedges is a simple way to advance
    repeat (4) @(posedge KEY[0]);
  end
  endtask

  // Optional monitor
  // Note: we cannot see R1/R2 directly since they are regs inside the DUT,
  // but we can at least observe state and opcode on LEDR.
  initial begin
    $display("time   state opcode");
    forever begin
      @(posedge KEY[0]);
      $display("%4t   %b     %b", $time, LEDR[1:0], LEDR[9:2]);
    end
  end

endmodule
