module top(
    input CLOCK_50,
    input [0:0] KEY,
    input [7:0] SW,
    input write,
    output [9:0] VGA_X,
    output [8:0] VGA_Y,
    output [23:0] VGA_COLOR,
    output plot,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);

    vga_demo U1 (
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

endmodule
