// vga_demo.v - Refactored drawing logic module
// This module takes VGA coordinates and register values, and determines the pixel color.

module vga_demo(
    input [9:0] draw_x,     // Horizontal coordinate
    input [8:0] draw_y,     // Vertical coordinate
    
    // Register file data inputs
    input [3:0] R0, R1, R2, R3, R4, R5, R6, R7,
    
    // Outputs to the top module
    output [23:0] VGA_COLOR, // 24-bit color (8R, 8G, 8B)
    output plot,              // Plot enable (high if within visible screen area)
    input [0:0] KEY
);

    // Drawing parameters
    parameter nX = 10;
    parameter nY = 9; 

    // Define color scheme (9-bit internally: 3R, 3G, 3B)
    parameter LINE_COLOR = 9'b111111111; // Bright white line
    parameter DATA_COLOR = 9'b111000000; // Data values are bright red
    parameter LABEL_COLOR = 9'b000111000; // Label values are bright green
    parameter BACK_COLOR = 9'b000000000; // Black background 
    
    reg [8:0] pixel_color_9bit; // The final pixel color output (9-bit internal) 

    // Box and positioning parameters 
    parameter BOX_WIDTH = 64; 
    parameter BOX_HEIGHT = 38; 
    parameter X_START = 40; 
    parameter Y_START = 40; 
    parameter SPACING = 72; // Horizontal spacing between box centers
    
    // Text rendering parameters
    parameter CHAR_PIXEL_WIDTH = 5; 
    parameter CHAR_PIXEL_HEIGHT = 7; 
    parameter TEXT_X_OFFSET = 10; 
    parameter TEXT_Y_OFFSET = 10;
    
    // Y coordinates for the 8 registers (R0-R7)
    parameter Y_BASE = Y_START; 
    
    // X coordinates for the Register Label (Rx) and Data (Value)
    parameter X_LABEL = X_START; 
    parameter X_VALUE = X_START + BOX_WIDTH; // X_VALUE is now the start of the data box

    // Output from the character generator (8 registers = 8 bits for label, 8 bits for value)
    wire [7:0] p_Label; 
    wire [7:0] p_Value; 

    wire [8:0] color;        // used as placeholder.
    wire [nX-1:0] X;         // used as placeholder
    wire [nY-1:0] Y;         // used as placeholder
    wire write;              // used as placeholder
    
    assign color = 0;
    assign X = 0;
    assign Y = 0;
    assign write = 0;

    
    defparam VGA_ADAPT.BACKGROUND_IMAGE = "./mif/0_bmp_640_9.mif" ;
    // instantiate the VGA adapter
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(color),
        .x(X),
        .y(Y),
        .write(write),
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

module seven_segment_char_gen (
    input [9:0] x_in, y_in, // Current VGA coordinates (must match draw_x/y width)
    input [9:0] x_origin, y_origin, // Top-left corner of where the character starts
    input [3:0] digit,              // The 4-bit hex digit to display (0-15)
    output reg draw_pixel            // Output: 1 if the pixel should be drawn, 0 otherwise
);

    parameter CHAR_W = 5; // Width of a segment (x range)
    parameter CHAR_H = 7; // Height of a segment (y range)
    parameter THICKNESS = 1; // Segment thickness

    // Local coordinates (relative to the character's origin)
    wire [9:0] x_local = x_in - x_origin;
    wire [9:0] y_local = y_in - y_origin;

    // Check if the pixel is within the character's boundary (CHAR_W x CHAR_H)
    wire in_char_bounds = (x_local < CHAR_W) && (y_local < CHAR_H);

    // Segment coordinates (simplified 7-segment layout)
    // Horizontal segments are 3 pixels wide (centered)
    // Vertical segments are 5 pixels high (centered)

    // Segment A (Top horizontal)
    wire seg_A = (y_local < THICKNESS) && (x_local >= 1) && (x_local <= 3); 
    // Segment B (Top right vertical)
    wire seg_B = (x_local >= CHAR_W - THICKNESS) && (y_local >= 1) && (y_local <= 3); 
    // Segment C (Bottom right vertical)
    wire seg_C = (x_local >= CHAR_W - THICKNESS) && (y_local >= 4) && (y_local <= 6); 
    // Segment D (Bottom horizontal)
    wire seg_D = (y_local >= CHAR_H - THICKNESS) && (x_local >= 1) && (x_local <= 3); 
    // Segment E (Bottom left vertical)
    wire seg_E = (x_local < THICKNESS) && (y_local >= 4) && (y_local <= 6); 
    // Segment F (Top left vertical)
    wire seg_F = (x_local < THICKNESS) && (y_local >= 1) && (y_local <= 3); 
    // Segment G (Middle horizontal)
    wire seg_G = (y_local >= 3 && y_local < 4) && (x_local >= 1) && (x_local <= 3); 

    // Look-up table to determine which segments should be lit for the given digit
    reg [6:0] segments_on; // [A, B, C, D, E, F, G]

    // 7-segment decoding logic for Hex digits (0-F)
    always @(*) begin
        case (digit)
            4'h0: segments_on = 7'b1111110; // 0
            4'h1: segments_on = 7'b0110000; // 1
            4'h2: segments_on = 7'b1101101; // 2
            4'h3: segments_on = 7'b1111001; // 3
            4'h4: segments_on = 7'b0110011; // 4
            4'h5: segments_on = 7'b1011011; // 5
            4'h6: segments_on = 7'b1011111; // 6
            4'h7: segments_on = 7'b1110000; // 7
            4'h8: segments_on = 7'b1111111; // 8
            4'h9: segments_on = 7'b1111011; // 9
            4'hA: segments_on = 7'b1110111; // A
            4'hB: segments_on = 7'b0011111; // B (lower case)
            4'hC: segments_on = 7'b1001110; // C
            4'hD: segments_on = 7'b0111101; // D (lower case)
            4'hE: segments_on = 7'b1001111; // E
            4'hF: segments_on = 7'b1000111; // F
            default: segments_on = 7'b0000000; // Blank for anything else
        endcase
    end

    // Determine the final draw_pixel output
    always @(*) begin
        draw_pixel = 1'b0; // Default to not drawing
        if (in_char_bounds) begin
            if (
                (segments_on[6] & seg_A) |
                (segments_on[5] & seg_B) |
                (segments_on[4] & seg_C) |
                (segments_on[3] & seg_D) |
                (segments_on[2] & seg_E) |
                (segments_on[1] & seg_F) |
                (segments_on[0] & seg_G)
            ) begin
                draw_pixel = 1'b1;
            end
        end
    end

endmodule