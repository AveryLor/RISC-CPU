`timescale 1ns / 1ns
`default_nettype none

module tb();

    // === Signals ===
    reg CLOCK_50 = 0;
    reg [3:0] KEY = 4'b1111;
    reg [7:0] SW = 8'b0;

    wire VGA_SYNC;
    wire [23:0] VGA_COLOR;

    // === Instantiate the top module ===
    vga_demo DUT (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .VGA_SYNC(VGA_SYNC)
    );

    // === Clock generation (50 MHz) ===
    always #10 CLOCK_50 = ~CLOCK_50;

    // === Test stimulus ===
    initial begin
        // Reset pulse
        KEY[0] = 0;
        #50;
        KEY[0] = 1;

        // Toggle write key
        #100;
        KEY[3] = 0;
        #20;
        KEY[3] = 1;

        // Change switches
        SW = 8'hFF;
        #200;

        $finish;
    end

endmodule
