// vga_demo.v - Refactored drawing logic module
// This module takes VGA coordinates and register values, and determines the pixel color.

module vga_demo(
    input [9:0] draw_x,     // Horizontal coordinate
    input [8:0] draw_y,     // Vertical coordinate
    
    // Register file data inputs
    input [3:0] R0, R1, R2, R3, R4, R5, R6, R7,
    
    // Outputs to the top module
    output [23:0] VGA_COLOR, // 24-bit color (8R, 8G, 8B)
    output plot              // Plot enable (high if within visible screen area)
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
    
    defparam VGA.BACKGROUND_IMAGE = "./MIF/bmp_640_9.mif" ;
    
    // Generate Register Labels (digit 0 through 7)
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_label_gen
            seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
            LABEL_INST (
                .x_in(draw_x),
                .y_in(draw_y),
                .x_origin(X_LABEL + TEXT_X_OFFSET), 
                .y_origin(Y_BASE + i * BOX_HEIGHT + TEXT_Y_OFFSET),    
                .digit(i), // Display the digit i (for Ri)
                .draw_pixel(p_Label[i])
            );
        end
    endgenerate

    // Generate Register Values (R0 through R7)
    // Using a concatenation trick to easily index the 4-bit registers
    wire [31:0] all_regs = {R7, R6, R5, R4, R3, R2, R1, R0};
    
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_value_gen
            seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
            VALUE_INST (
                .x_in(draw_x),
                .y_in(draw_y),
                .x_origin(X_VALUE + TEXT_X_OFFSET),
                .y_origin(Y_BASE + i * BOX_HEIGHT + TEXT_Y_OFFSET),
                .digit(all_regs[i*4 +: 4]), // Get the 4-bit value for register Ri
                .draw_pixel(p_Value[i])
            );
        end
    endgenerate

    // --- Pixel Color Generation ---
    always @(*) begin
        pixel_color_9bit = BACK_COLOR; // Default to black
        
        // --- 1. Draw the Grid ---
        if (
            // Check vertical range (for R0 to R7)
            (draw_y >= Y_START && draw_y < Y_START + 8 * BOX_HEIGHT) &&
            
            // Check horizontal range (for Label and Value columns combined)
            (draw_x >= X_LABEL && draw_x < X_VALUE + BOX_WIDTH)
        ) begin
            
            // Check for horizontal dividers (Top, bottom of R0-R7)
            if ( (draw_y == Y_START) || ((draw_y - Y_START) % BOX_HEIGHT == BOX_HEIGHT - 1) ) begin
                pixel_color_9bit = LINE_COLOR;
            end
            
            // Check for vertical dividers (Left, center, right)
            if ( (draw_x == X_LABEL) || (draw_x == X_VALUE - 1) || (draw_x == X_VALUE + BOX_WIDTH - 1) ) begin
                 pixel_color_9bit = LINE_COLOR;
            end
        end

        // --- 2. Draw the Register Data (overwrites grid lines) ---
        
        // Draw the Register Labels (e.g., '0' for R0, '1' for R1, etc.)
        if (|p_Label) begin
            pixel_color_9bit = LABEL_COLOR;
        end
        
        // Draw the Register Values (e.g., 4-bit R0 value, R1 value, etc.)
        if (|p_Value) begin
            pixel_color_9bit = DATA_COLOR;
        end
        
    end
    
    // --- Plot Enable and 24-bit Color Assignment ---
    
    // Plot is high when we are in the visible grid area
    assign plot = (draw_y >= Y_START && draw_y < Y_START + 8 * BOX_HEIGHT) &&
                  (draw_x >= X_LABEL && draw_x < X_VALUE + BOX_WIDTH);
                  
    // Convert 9-bit (3:3:3) internal color to 24-bit (8:8:8) output
    assign VGA_COLOR = {
        {pixel_color_9bit[8:6], pixel_color_9bit[8:6], pixel_color_9bit[8]}, // Red (8 bits)
        {pixel_color_9bit[5:3], pixel_color_9bit[5:3], pixel_color_9bit[5]}, // Green (8 bits)
        {pixel_color_9bit[2:0], pixel_color_9bit[2:0], pixel_color_9bit[2]}  // Blue (8 bits)
    };

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