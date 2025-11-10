module vga_demo_auto_manual(
    input CLOCK_50,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);

    parameter nX = 10;
    parameter nY = 9;

    // VGA coordinates
    wire [nX-1:0] draw_x;
    wire [nY-1:0] draw_y;

    reg [8:0] pixel_color;

    // VGA adapter instantiation
    vga_adapter VGA_OUT (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .color(pixel_color),
        .x(draw_x),
        .y(draw_y),
        .write(1'b1),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    // --- Box parameters ---
    parameter BOX_SIZE = 32;
    parameter BOX_HALF_SIZE = BOX_SIZE / 2;
    parameter Y_CENTER = 240;

    // Bright white lines (111111111)
    parameter LINE_COLOR = 9'b111111111;

    // Box center X coordinates
    parameter X0 = 40;
    parameter X1 = 120;
    parameter X2 = 200;
    parameter X3 = 280;
    parameter X4 = 360;
    parameter X5 = 440;
    parameter X6 = 520;
    parameter X7 = 600;

    // --- Compute Y range constants ---
    parameter Y_MIN = Y_CENTER - BOX_HALF_SIZE;
    parameter Y_MAX = Y_CENTER + BOX_HALF_SIZE - 1;

    always @(*) begin
        pixel_color = 9'b000000000; // Default: black background

        // Helper wires to identify box edges
        // (no for loops, just manual comparisons)
        if (
            // --- Box 0 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X0 - BOX_HALF_SIZE && draw_x <= X0 + BOX_HALF_SIZE)) ||
            ((draw_x == X0 - BOX_HALF_SIZE || draw_x == X0 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX)) ||

            // --- Box 1 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X1 - BOX_HALF_SIZE && draw_x <= X1 + BOX_HALF_SIZE)) ||
            ((draw_x == X1 - BOX_HALF_SIZE || draw_x == X1 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX)) ||

            // --- Box 2 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X2 - BOX_HALF_SIZE && draw_x <= X2 + BOX_HALF_SIZE)) ||
            ((draw_x == X2 - BOX_HALF_SIZE || draw_x == X2 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX)) ||

            // --- Box 3 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X3 - BOX_HALF_SIZE && draw_x <= X3 + BOX_HALF_SIZE)) ||
            ((draw_x == X3 - BOX_HALF_SIZE || draw_x == X3 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX)) ||

            // --- Box 4 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X4 - BOX_HALF_SIZE && draw_x <= X4 + BOX_HALF_SIZE)) ||
            ((draw_x == X4 - BOX_HALF_SIZE || draw_x == X4 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX)) ||

            // --- Box 5 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X5 - BOX_HALF_SIZE && draw_x <= X5 + BOX_HALF_SIZE)) ||
            ((draw_x == X5 - BOX_HALF_SIZE || draw_x == X5 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX)) ||

            // --- Box 6 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X6 - BOX_HALF_SIZE && draw_x <= X6 + BOX_HALF_SIZE)) ||
            ((draw_x == X6 - BOX_HALF_SIZE || draw_x == X6 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX)) ||

            // --- Box 7 ---
            ((draw_y == Y_MIN || draw_y == Y_MAX) && (draw_x >= X7 - BOX_HALF_SIZE && draw_x <= X7 + BOX_HALF_SIZE)) ||
            ((draw_x == X7 - BOX_HALF_SIZE || draw_x == X7 + BOX_HALF_SIZE) && (draw_y >= Y_MIN && draw_y <= Y_MAX))
        ) begin
            pixel_color = LINE_COLOR;
        end
    end
endmodule
