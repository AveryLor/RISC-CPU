// This module displays the values of 8 registres (assuming 4-bit data)
// onto the VGA screen, using existing box structures 
// The values are displayed as 7 segment style hexadecimal digits
module vga_demo(CLOCK_50, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
    // Required signals for the VGA to work properly 
    input CLOCK_50; 
    output [7:0] VGA_R; 
    output [7:0] VGA_G; 
    output [7:0] VGA_B; 
    output VGA_HS; 
    output VGA_VS; 
    output VGA_BLANK_N; 
    output VGA_SYNC_N; 
    output VGA_CLK; 

    // External reg file inputs
    input [3:0] R1; 
    input [3:0] R2; 
    input [3:0] R3; 
    // input [3:0] R4; Not yet used
    // input [3:0] R5; 
    // input [3:0] R6; 
    // input [3:0] R7; 
    // input [3:0] R8; 

    // Drawing parameters
    parameter nX = 10;
    parameter nY = 9; 

    // Define color scheme 
    parameter LINE_COLOR = 9'b111111111; // Bright white line
    parameter DATA_COLOR = 9'b111000000; // Data values are in red
    parameter BLACK_COLOR = 9'b000000000; // Black background 

    // VGA drawing coordaintes 
    wire [nX-1:0] draw_x; 
    wire [nY-1:0] draw_y; 
    reg [8:0] pixel_color; // The final pixel color output 

    // Box and positioning parameters 
    parameter BOX_WIDTH = 64; 
    parameter BOX_HEIGT = 38; 
    parameter X_START = 40; 
    parameter Y_START = 40; 
    parameter SPACING = 72; // Horizontal spacing between box centers
    parameter CHAR_PIXEL_WIDTH = 5; // Width of one character segment
    
    // Y coordinates for the 8 registers (R0-R7)
    parameter Y_BASE = Y_START; // Starting Y coordinate for R0
    parameter Y_R0 = Y_BASE + 0 * BOX_HEIGHT;
    parameter Y_R1 = Y_BASE + 1 * BOX_HEIGHT;
    parameter Y_R2 = Y_BASE + 2 * BOX_HEIGHT;
    parameter Y_R3 = Y_BASE + 3 * BOX_HEIGHT;
    parameter Y_R4 = Y_BASE + 4 * BOX_HEIGHT;
    parameter Y_R5 = Y_BASE + 5 * BOX_HEIGHT;
    parameter Y_R6 = Y_BASE + 6 * BOX_HEIGHT;
    parameter Y_R7 = Y_BASE + 7 * BOX_HEIGHT;

    // X coordinates for the Register Label (Rx) and Data (Value)
    parameter X_LABEL = X_START; // X position for 'R0', 'R1', etc.
    parameter X_VALUE = X_START + SPACING; // X position for the value

    // Output from the character generator: 1 if the pixel should be drawn for the character
    // We need one draw_pixel wire for the LABEL (e.g., '0' for R0)
    wire [7:0] p_Label; 
    // We need one draw_pixel wire for the VALUE (e.g., R0 value)
    wire [7:0] p_Value; 
    
    // --- Instance Array for Register Values (Single Digit) ---
    // R0 Label (digit '0') and Value (R0)    
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R0_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 0*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd0),            // Display the digit 0 (for R0)
        .draw_pixel(p_Label[0])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R0_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 0*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R0),            // Use the 4-bit value of R0
        .draw_pixel(p_Value[0])
    );
    
    // R1 Label (digit '1') and Value (R1)
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R1_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 1*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd1),
        .draw_pixel(p_Label[1])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R1_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 1*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R1),
        .draw_pixel(p_Value[1])
    );
    
    // R2 Label (digit '2') and Value (R2)
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R2_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 2*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd2),
        .draw_pixel(p_Label[2])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R2_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 2*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R2),
        .draw_pixel(p_Value[2])
    );

    // R3 Label (digit '3') and Value (R3)
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R3_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 3*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd3),
        .draw_pixel(p_Label[3])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R3_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 3*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R3),
        .draw_pixel(p_Value[3])
    );
    
    // R4 Label (digit '4') and Value (R4)
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R4_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 4*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd4),
        .draw_pixel(p_Label[4])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R4_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 4*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R4),
        .draw_pixel(p_Value[4])
    );
    
    // R5 Label (digit '5') and Value (R5)
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R5_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 5*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd5),
        .draw_pixel(p_Label[5])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R5_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 5*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R5),
        .draw_pixel(p_Value[5])
    );
    
    // R6 Label (digit '6') and Value (R6)
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R6_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 6*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd6),
        .draw_pixel(p_Label[6])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R6_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 6*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R6),
        .draw_pixel(p_Value[6])
    );
    
    // R7 Label (digit '7') and Value (R7)
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT)) 
    R7_LABEL_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_LABEL + TEXT_X_OFFSET), 
        .y_origin(Y_START + 7*BOX_HEIGHT + TEXT_Y_OFFSET),    
        .digit(4'd7),
        .draw_pixel(p_Label[7])
    );
    seven_segment_char_gen #(.CHAR_W(CHAR_PIXEL_WIDTH), .CHAR_H(CHAR_PIXEL_HEIGHT))
    R7_VALUE_INST (
        .x_in(draw_x),
        .y_in(draw_y),
        .x_origin(X_VALUE + TEXT_X_OFFSET),
        .y_origin(Y_START + 7*BOX_HEIGHT + TEXT_Y_OFFSET),
        .digit(R7),
        .draw_pixel(p_Value[7])
    );


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
    
    // --- Pixel Color Generation ---
    always @(*) begin
        pixel_color = BACK_COLOR; // Default to black
        
        // --- 1. Draw the Grid ---
        if (
            // Check vertical range (for R0 to R7)
            (draw_y >= Y_START && draw_y < Y_START + 8 * BOX_HEIGHT) &&
            
            // Check horizontal range (for Label and Value columns combined)
            (draw_x >= X_LABEL && draw_x < X_VALUE + BOX_WIDTH)
        ) begin
            
            // Check for horizontal dividers (Top edge of R0, and bottom edge of R0-R7)
            // (draw_y == Y_START) is the top border
            // ((draw_y - Y_START) % BOX_HEIGHT == BOX_HEIGHT - 1) is the bottom border of each row
            if ( (draw_y == Y_START) || ((draw_y - Y_START) % BOX_HEIGHT == BOX_HEIGHT - 1) ) begin
                // Draw horizontal line
                pixel_color = LINE_COLOR;
            end
            
            // Check for vertical dividers (Left edge of R0 and Right edge of Label/Value columns)
            // draw_x == X_LABEL is the left border
            // draw_x == X_LABEL + BOX_WIDTH - 1 is the center line
            // draw_x == X_VALUE + BOX_WIDTH - 1 is the right border
            if ( (draw_x == X_LABEL) || (draw_x == X_LABEL + BOX_WIDTH - 1) || (draw_x == X_VALUE + BOX_WIDTH - 1) ) begin
                 // Draw vertical line
                pixel_color = LINE_COLOR;
            end
        end

        // --- 2. Draw the Register Data (overwrites grid lines if necessary) ---
        
        // Draw the Register Labels (e.g., '0' for R0, '1' for R1, etc.)
        if (|p_Label) begin
            pixel_color = LABEL_COLOR;
        end
        
        // Draw the Register Values (e.g., 4-bit R0 value, R1 value, etc.)
        if (|p_Value) begin
            pixel_color = DATA_COLOR;
        end
        
    end
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
    wire [6:0] segments_on; // [A, B, C, D, E, F, G]

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