`timescale 1ns / 1ns
`default_nettype none

module tb();

    // Inputs
    reg CLOCK_50 = 0;
    reg [0:0] KEY = 0;
    reg [7:0] SW = 0;
    reg write = 1'b1; // keep write asserted for test

    // VGA Outputs
    wire [9:0] VGA_X;
    wire [8:0] VGA_Y;
    wire [23:0] VGA_COLOR;
    wire plot;
    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;

    // Instantiate the top module
    top DUT (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .write(write),
        .VGA_X(VGA_X),
        .VGA_Y(VGA_Y),
        .VGA_COLOR(VGA_COLOR),
        .plot(plot),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    // 50 MHz clock generator
    always #10 CLOCK_50 = ~CLOCK_50;

    // Optional reset pulse at start
    initial begin
        KEY = 0;
        #50;
        KEY = 1;  // release reset
    end

endmodule
`timescale 1ns / 1ns
`default_nettype none

module tb();

    // Inputs
    reg CLOCK_50 = 0;
    reg [0:0] KEY = 0;
    reg [7:0] SW = 0;
    reg write = 1'b1; // keep write asserted for test

    // VGA Outputs
    wire [9:0] VGA_X;
    wire [8:0] VGA_Y;
    wire [23:0] VGA_COLOR;
    wire plot;
    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;

    // Instantiate the top module
    top DUT (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .write(write),
        .VGA_X(VGA_X),
        .VGA_Y(VGA_Y),
        .VGA_COLOR(VGA_COLOR),
        .plot(plot),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    // 50 MHz clock generator
    always #10 CLOCK_50 = ~CLOCK_50;

    // Optional reset pulse at start
    initial begin
        KEY = 0;
        #50;
        KEY = 1;  // release reset
    end

endmodule
