/*
 * This code automatically draws 8 fixed-size, fixed-color boxes on the VGA display.
 * The logic manually checks all 8 box boundaries without using a 'for' loop.
 * User controls (SW, KEY) and status outputs (LEDR, HEX) have been removed.
*/
module vga_demo_auto_manual(CLOCK_50, VGA_R, VGA_G, VGA_B,
                            VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
    
    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 10;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 9;

    input CLOCK_50;    
    
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;    
    
    // --- Fixed Box Parameters ---
    parameter BOX_SIZE = 32; // Fixed size (e.g., 32x32 pixels)
    parameter BOX_HALF_SIZE = BOX_SIZE / 2;
    parameter Y_CENTER = 240; // Fixed center Y for all boxes
    
    // Fixed color (e.g., bright green - 001110000, 9-bit color)
    parameter BOX_COLOR = 9'b001110000; 

    // Box center X coordinates (Total 8 boxes)
    parameter X0 = 40;
    parameter X1 = 120;
    parameter X2 = 200;
    parameter X3 = 280;
    parameter X4 = 360;
    parameter X5 = 440;
    parameter X6 = 520;
    parameter X7 = 600;
    
    // --- VGA Adapter Wires ---
    // These wires will hold the current pixel coordinates output by the VGA adapter.
    wire [nX-1:0] draw_x;
    wire [nY-1:0] draw_y;
    
    // The current color to be displayed at (draw_x, draw_y)
    reg [8:0] pixel_color; 
    
    // --- VGA Adapter Instance ---
    // The vga_adapter is assumed to be an existing component that outputs 
    // the current x/y coordinates of the scan beam (draw_x, draw_y) and handles timing.
    vga_adapter VGA_OUT (
        .resetn(1'b1), // No reset
        .clock(CLOCK_50),
        .color(pixel_color), // Color is dynamically assigned by our logic
        .x(draw_x), // VGA adapter determines the pixel to draw
        .y(draw_y),
        .write(1'b1), // Always write (continuously update the screen)
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    
    // --- Box Detection and Coloring Logic (Manual Check) ---
    
    // Calculate Y boundaries, which are constant for all boxes
    parameter Y_MIN = Y_CENTER - BOX_HALF_SIZE;
    parameter Y_MAX = Y_CENTER + BOX_HALF_SIZE - 1;

    // Check if the current pixel falls within the vertical range of the boxes
    wire y_in_range = (draw_y >= Y_MIN) && (draw_y <= Y_MAX);

    // This logic runs continuously, checking the current scan position (draw_x, draw_y)
    // against the location of the 8 fixed boxes.
    always @(*) begin
        // Default: Background is black (000000000)
        pixel_color = 9'b000000000;
        
        // Only check X boundaries if the pixel is in the correct vertical range
        if (y_in_range) begin
            
            // Box 0
            if (draw_x >= X0 - BOX_HALF_SIZE && draw_x < X0 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            // Box 1
            else if (draw_x >= X1 - BOX_HALF_SIZE && draw_x < X1 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            // Box 2
            else if (draw_x >= X2 - BOX_HALF_SIZE && draw_x < X2 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            // Box 3
            else if (draw_x >= X3 - BOX_HALF_SIZE && draw_x < X3 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            // Box 4
            else if (draw_x >= X4 - BOX_HALF_SIZE && draw_x < X4 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            // Box 5
            else if (draw_x >= X5 - BOX_HALF_SIZE && draw_x < X5 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            // Box 6
            else if (draw_x >= X6 - BOX_HALF_SIZE && draw_x < X6 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            // Box 7
            else if (draw_x >= X7 - BOX_HALF_SIZE && draw_x < X7 + BOX_HALF_SIZE) begin
                pixel_color = BOX_COLOR;
            end
            
        end
    end
    
endmodule
