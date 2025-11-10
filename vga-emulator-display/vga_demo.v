 /*
 * This code automatically draws 8 fixed-size, fixed-color boxes on the VGA display.
 * User controls (SW, KEY) and status outputs (LEDR, HEX) have been removed or simplified.
 * The boxes will appear static due to continuous repainting.
*/
module vga_demo_auto(CLOCK_50, VGA_R, VGA_G, VGA_B,
                     VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
    
    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 10;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 9;

    input CLOCK_50;    
    
    // Unused Inputs (Removed: SW, KEY)
    // Unused Outputs (Removed: LEDR, HEX2, HEX1, HEX0)
    
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;    
    
    // --- Fixed Box Parameters ---
    parameter BOX_SIZE = 32; // Example fixed size (32x32 pixels)
    parameter BOX_HALF_SIZE = BOX_SIZE / 2;
    parameter Y_CENTER = 240; // Fixed center Y for all boxes
    
    // Fixed color (e.g., bright green - 001110000)
    parameter BOX_COLOR = 9'b001110000; 

    // Box center X coordinates (Total 8 boxes)
    // These positions are used to determine if the current VGA pixel (draw_x, draw_y) 
    // falls within a box's area.
    reg [nX-1:0] box_x [0:7];
    initial begin
        box_x[0]=40; box_x[1]=120; box_x[2]=200; box_x[3]=280;
        box_x[4]=360; box_x[5]=440; box_x[6]=520; box_x[7]=600;
    end
    
    // --- VGA Adapter Wires ---
    // These wires will hold the current pixel coordinates output by the VGA adapter.
    wire [nX-1:0] draw_x;
    wire [nY-1:0] draw_y;
    
    // The current color to be displayed at (draw_x, draw_y)
    reg [8:0] pixel_color; 
    
    // --- Core Box Drawing Logic ---
    
    // Use the VGA adapter to get the current drawing coordinates (draw_x, draw_y)
    // and VGA timing signals. We are not actively writing pixels like the FSM version,
    // but rather coloring the VGA display output based on its current position.
    vga_adapter VGA_OUT (
        .resetn(1'b1), // Always asserted (no reset)
        .clock(CLOCK_50),
        .color(pixel_color), // Color is now dynamically assigned by our logic
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
    
    // The vga_adapter is assumed to be an existing component that outputs 
    // the current x/y coordinates of the scan beam (draw_x, draw_y)
    // and handles the VGA timing. Since we don't have its source, we need to 
    // assume it outputs these coordinates for external use or define a stub. 
    // Given the previous code, we'll assume a version that provides x and y.
    
    // *** NOTE: The standard DE1-SoC vga_adapter usually outputs x and y internally. ***
    // *** We must modify the module instance to get the current scan coordinates. ***
    //
    // Since we removed the FSM and coordinate counters (XC, YC, X, Y), we must
    // use a simplified adapter or external counters to generate (draw_x, draw_y).
    // For this example, we assume the VGA_OUT instance has been modified/replaced 
    // by one that provides `draw_x` and `draw_y` as outputs from the adapter.
    // In many real-world examples, you would use separate VGA timing module 
    // to generate `draw_x` and `draw_y` and the timing signals.
    
    // --- Box Detection and Coloring Logic ---
    
    // This logic runs continuously, checking the current scan position (draw_x, draw_y)
    // against the location of the 8 fixed boxes.
    always @(*) begin
        // Default: Background is black (000000000)
        pixel_color = 9'b000000000;
        
        // Loop through all 8 boxes
        for (int i = 0; i < 8; i = i + 1) begin
            // Calculate the boundaries of the current box (i)
            
            // X-bounds: [box_x[i] - HALF_SIZE] to [box_x[i] + HALF_SIZE - 1]
            if (draw_x >= box_x[i] - BOX_HALF_SIZE && 
                draw_x < box_x[i] + BOX_HALF_SIZE) begin
                
                // Y-bounds: [Y_CENTER - HALF_SIZE] to [Y_CENTER + HALF_SIZE - 1]
                if (draw_y >= Y_CENTER - BOX_HALF_SIZE && 
                    draw_y < Y_CENTER + BOX_HALF_SIZE) begin
                    
                    // The current pixel (draw_x, draw_y) is inside box 'i'
                    pixel_color = BOX_COLOR;
                    // Once a box is hit, we can break the loop (since all boxes have the same color)
                    // If we wanted different colors, we would assign the color here and let the loop continue
                end
            end
        end
    end
    
endmodule 

// --- Supporting Modules (No longer needed: regn, Up_count, hex7seg) ---

// NOTE: Since the full vga_adapter code is not provided and its behavior 
// changed significantly (from accepting a write command to needing to output 
// the current screen coordinates), the actual implementation of the VGA_OUT 
// module will vary. The core logic above *assumes* the vga_adapter provides 
// current scan coordinates `draw_x` and `draw_y` as outputs for the external
// logic to determine the `color`.
// If the vga_adapter is a standard provided component, a separate **VGA Timing Generator** // module would be used to create `draw_x`, `draw_y`, and all timing signals,
// and the VGA_OUT module would simply become a final register stage.

// For simplicity and adherence to the previous structure, let's include the
// common **VGA Timing Generator** component to generate the coordinates.

/*
// Simplified VGA Timing Generator to replace the need for the adapter to output x/y
// This module would replace the vga_adapter call and connect directly to the VGA pins.

module vga_timing_gen(
    input clock, resetn,
    output [9:0] H_Count, // Horizontal (X)
    output [9:0] V_Count, // Vertical (Y)
    output H_Sync, V_Sync, Blank_n, Sync_n, VGA_CLK
);
    // ... Internal counters and timing logic to generate H_Count, V_Count, etc. ...
    // H_Count would be our draw_x, V_Count would be our draw_y
endmodule
*/
