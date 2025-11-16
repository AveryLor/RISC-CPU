`timescale 1ns / 1ns
`default_nettype none

module tb();

// === Input Signals (reg) ===
    reg CLOCK_50 = 1'b0;
    reg [3:0] KEY = 4'b1111; // KEY[0] is active-low reset
    reg [7:0] SW = 8'h00; // Assumed input for vga_writer
    reg [31:0] register_value = 32'hFEEDF00D; // Input from simulation environment

// === Output Signals (wire) ===
    wire [8:0] addr; // Output address for simulation environment  
    wire finished_register; // Output to signal data finished

    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;

// === Instantiate the top module (DUT) ===
    vga_demo DUT (
        // Clock & Reset
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        // Simulation Interface
        .addr(addr),
        .register_value(register_value),
        .finished_register(finished_register),

        // Assumed 'SW' input
        .SW(SW), 
        // VGA Output Ports
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

endmodule