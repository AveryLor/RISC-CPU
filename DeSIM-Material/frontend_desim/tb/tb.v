// tb.v - testbench for DESim VGA Demo
`timescale 1ns / 1ns
`default_nettype none

module tb();

    // Clock and inputs
    reg CLOCK_50 = 0;
    reg [3:0] KEY = 4'b1111;
    reg [31:0] register_value = 32'h12345678;

    // Outputs
    wire [8:0] addr;
    wire finished_register;
    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;

    // Instantiate top-level module
    top DUT (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
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

    // Generate 50 MHz clock
    always #10 CLOCK_50 = ~CLOCK_50;

    // Example stimulus
    initial begin
        // Initial reset
        KEY = 4'b0000; // reset
        #50;
        KEY = 4'b1111; // release reset

        // Toggle write pulse (KEY[3])
        #100 KEY[3] = 0;
        #20  KEY[3] = 1;
        #200 $stop;
    end

endmodule
