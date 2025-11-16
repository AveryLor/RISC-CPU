`timescale 1ns / 1ns
`default_nettype none

// top.v - DESim top wrapper for VGA demo
// This module exposes all necessary I/O signals, including the VGA signals
// and the new simulation interface ports (addr, register_value, finished_register).
module top(
    input wire CLOCK_50,
    input wire [3:0] KEY,

    // Simulation Interface Ports (required by vga_demo)
    output wire [8:0] addr,
    input wire [31:0] register_value,
    output wire finished_register,

    // VGA Output Ports
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire VGA_BLANK_N,
    output wire VGA_SYNC_N,
    output wire VGA_CLK
);

    // Instantiate VGA demo module
    // Note: The .SW port was removed as it was not present in the vga_demo module's port list.
    vga_demo U1 (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),

        // Simulation/Register connections
        .addr(addr),
        .register_value(register_value),
        .finished_register(finished_register),

        // VGA connections
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