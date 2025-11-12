// top.v - DESim top wrapper for VGA demo
`timescale 1ns / 1ns
`default_nettype none

module top(
    input  wire CLOCK_50,
    input  wire [3:0] KEY,
    input  wire [31:0] register_value,
    output wire [8:0] addr,
    output wire finished_register,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire VGA_BLANK_N,
    output wire VGA_SYNC_N,
    output wire VGA_CLK
);

    // Instantiate VGA demo
    vga_demo U1 (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(8'd0),                  // Not used in this demo
        .register_value(register_value),
        .addr(addr),
        .finished_register(finished_register),
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
