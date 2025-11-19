`timescale 1ns/1ps

module HDU_tb;

  // Inputs
  reg [7:0] ID_instruct;
  reg [7:0] EX_instruct;
  reg [7:0] MEM_instruct;
  reg [7:0] WB_instruct;

  // Outputs
  wire stall;
  wire out;

  // Instantiate DUT
  HDU dut (
    .ID_instruct (ID_instruct),
    .EX_instruct (EX_instruct),
    .MEM_instruct(MEM_instruct),
    .WB_instruct (WB_instruct),
    .stall       (stall),
    .out         (out)
  );

  // Encodings:
  // [7]   = mode (ignored by HDU here, we keep 0)
  // [6:4] = opcode: NOP=000, ADD=001, INC=011
  // [3:2] = reg1 (destination / first src)
  // [1:0] = reg2 (second source, ignored for INC)

  // Helper task for readability
  task apply_case;
    input [7:0] id_i;
    input [7:0] ex_i;
    input [7:0] mem_i;
    input [7:0] wb_i;
    input [127:0] description;
  begin
    ID_instruct  = id_i;
    EX_instruct  = ex_i;
    MEM_instruct = mem_i;
    WB_instruct  = wb_i;
    #5; // small delay to let combinational logic settle

    $display("Time %0t | %s | ID=%b EX=%b MEM=%b WB=%b | stall=%b",
             $time, description, ID_instruct, EX_instruct, MEM_instruct, WB_instruct, stall);
  end
  endtask

  // Convenience function to build an instruction
  function [7:0] instr;
    input [2:0] opcode;
    input [1:0] reg1;
    input [1:0] reg2;
  begin
    instr = {1'b0, opcode, reg1, reg2};  // mode=0
  end
  endfunction

  initial begin
    // Initialize
    ID_instruct  = 8'b0;
    EX_instruct  = 8'b0;
    MEM_instruct = 8'b0;
    WB_instruct  = 8'b0;
    #5;

    // 1) All NOPs: should NOT stall
    apply_case(instr(3'b000, 2'b00, 2'b00),  // ID: NOP
               instr(3'b000, 2'b00, 2'b00),  // EX: NOP
               instr(3'b000, 2'b00, 2'b00),  // MEM: NOP
               instr(3'b000, 2'b00, 2'b00),  // WB: NOP
               "All NOPs (no hazard, stall=0 expected)");

    // 2) RAW hazard on reg1 between ID and EX:
    //    ID: ADD R0, R1
    //    EX: ADD R0, R2 (EX writes R0, ID reads R0) -> stall=1
    apply_case(instr(3'b001, 2'b00, 2'b01),  // ID: ADD R0, R1
               instr(3'b001, 2'b00, 2'b10),  // EX: ADD R0, R2
               instr(3'b000, 2'b00, 2'b00),  // MEM: NOP
               instr(3'b000, 2'b00, 2'b00),  // WB: NOP
               "Hazard on ID_reg1 vs EX_reg1 (stall=1 expected)");

    // 3) RAW hazard on reg2 (only for non-INC):
    //    ID: ADD R1, R0 (uses R0 as second operand)
    //    EX: ADD R0, R2 (writes R0) -> stall=1
    apply_case(instr(3'b001, 2'b01, 2'b00),  // ID: ADD R1, R0
               instr(3'b001, 2'b00, 2'b10),  // EX: ADD R0, R2
               instr(3'b000, 2'b00, 2'b00),  // MEM: NOP
               instr(3'b000, 2'b00, 2'b00),  // WB: NOP
               "Hazard on ID_reg2 vs EX_reg1 for ADD (stall=1 expected)");

    // 4) No hazard on reg2 for INC:
    //    ID: INC R1 (reg2 ignored)
    //    EX: ADD R0, R1
    //    Even if ID_reg2 matches EX_reg1, opcode=INC => should NOT stall
    apply_case(instr(3'b011, 2'b01, 2'b00),  // ID: INC R1 (reg2=don't care)
               instr(3'b001, 2'b00, 2'b01),  // EX: ADD R0, R1
               instr(3'b000, 2'b00, 2'b00),  // MEM: NOP
               instr(3'b000, 2'b00, 2'b00),  // WB: NOP
               "INC uses only reg1, so reg2 hazard ignored (stall=0 expected)");

    // 5) Hazard coming from MEM stage:
    //    ID: ADD R1, R2
    //    MEM: ADD R1, R0 (writes R1) -> stall=1
    apply_case(instr(3'b001, 2'b01, 2'b10),  // ID: ADD R1, R2
               instr(3'b000, 2'b00, 2'b00),  // EX: NOP
               instr(3'b001, 2'b01, 2'b00),  // MEM: ADD R1, R0
               instr(3'b000, 2'b00, 2'b00),  // WB: NOP
               "Hazard on ID_reg1 vs MEM_reg1 (stall=1 expected)");

    // 6) Hazard coming from WB stage:
    //    ID: ADD R0, R1
    //    WB: ADD R0, R2 (writes R0) -> stall=1
    apply_case(instr(3'b001, 2'b00, 2'b01),  // ID: ADD R0, R1
               instr(3'b000, 2'b00, 2'b00),  // EX: NOP
               instr(3'b000, 2'b00, 2'b00),  // MEM: NOP
               instr(3'b001, 2'b00, 2'b10),  // WB: ADD R0, R2
               "Hazard on ID_reg1 vs WB_reg1 (stall=1 expected)");

    // 7) No hazard: registers differ
    //    ID: ADD R0, R1
    //    EX: ADD R2, R0 (writes R2, independent)
    apply_case(instr(3'b001, 2'b00, 2'b01),  // ID: ADD R0, R1
               instr(3'b001, 2'b10, 2'b00),  // EX: ADD R2, R0
               instr(3'b000, 2'b00, 2'b00),  // MEM: NOP
               instr(3'b000, 2'b00, 2'b00),  // WB: NOP
               "No overlapping dest/src (stall=0 expected)");

    $display("HDU testbench finished at time %0t", $time);
    $stop;
  end

endmodule
