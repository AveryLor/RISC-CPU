module pipeline_drawer(clock, resetn, IF_PC_VALUE, ID_VAL_A, EX_ALU_RESULT, MEM_DATA_OUT, WB_DATA_IN, pipeline_x, pipeline_y, pipeline_color, pipeline_done); 
	input clock;  
    input resetn; 
    
    // Data from control unit (example registers)
    input [31:0] IF_PC_VALUE; 
    input [31:0] ID_VAL_A; 
    input [31:0] EX_ALU_RESULT;
    input [31:0] MEM_DATA_OUT;
    input [31:0] WB_DATA_IN;
    
    // VGA output coordinates and color
    output wire [9:0] pipeline_x;    // 10-bit X coordinate
    output wire [8:0] pipeline_y;    // 9-bit Y coordinate
    output wire [8:0] pipeline_color; // 9-bit color output
    output wire pipeline_done; // Set high when all drawing is complete

	// Drawing parameters
	localparam NUM_STAGES = 5;
    localparam LABEL_WIDTH = 5; // e.g., "IF://"
    localparam DATA_WIDTH = 8;  // 8 hex digits (32 bits)
    localparam CHARS_PER_LINE = LABEL_WIDTH + DATA_WIDTH; // 13
    localparam MAX_CHARS = NUM_STAGES * CHARS_PER_LINE; // 65
    
    localparam START_X = 300;
    localparam START_Y = 25;
    localparam CHAR_SPACING = 9; // 8 pixels + 1 spacing
    localparam LINE_HEIGHT = 10; // 8 pixels + 2 spacing
    
    localparam LABEL_COLOR = 9'b111000000; // Bright Red
    localparam DATA_COLOR  = 9'b000111000; // Bright Green
    localparam BACKGROUND_COLOR = 9'b000000000; // Black
	
    // Wires from Character Logic ---
    wire char_drawer_done;
    wire [5:0] char_idx; // Needs to be wide enough for MAX_CHARS (55)
    wire [2:0] pixel_x;
    wire [2:0] pixel_y;
    
    // Drawing State Variables
    wire [2:0] stage_index; // Current stage being drawn (0 to 4)
    wire [3:0] char_line_idx; // Current char position within the 11-char line (0 to 10)
    wire [31:0] current_value; // The 32-bit value being displayed
    
    // Stage Index and Character Position
    assign stage_index = char_idx / CHARS_PER_LINE; // 0-IF, 1-ID, 2-EX, 3-MEM, 4-WB
    assign char_line_idx = char_idx % CHARS_PER_LINE; // 0-2 for label, 3-10 for data

    // Instantiate drawing logic 
    char_drawer_logic cdl_inst (
        .clock(clock), 
        .resetn(resetn), 
        .char_count(MAX_CHARS), 
        .done(char_drawer_done), 
        .char_idx(char_idx), 
        .pixel_x(pixel_x), 
        .pixel_y(pixel_y)
    );

	// Connect done signal
    assign pipeline_done = char_drawer_done;

    // Select the 32-bit value corresponding to the current drawing stage
    always @(*) begin
        case (stage_index)
            3'd0: current_value = IF_PC_VALUE;
            3'd1: current_value = ID_VAL_A;
            3'd2: current_value = EX_ALU_RESULT;
            3'd3: current_value = MEM_DATA_OUT;
            3'd4: current_value = WB_DATA_IN;
            default: current_value = 32'hDEADBEEF; // Error/Default
        endcase
    end
    
    // Stage names: IF, ID, EX, MEM, WB
    wire [7:0] stage_labels[0:4][0:4]; // [Stage][Char]
	// 5 stages, 4 characters each, 8 
    
    // Stage 0: IF
    assign stage_labels[0][0] = 8'd18; // 'I'
    assign stage_labels[0][1] = 8'd15; // 'F'
	assign stage_labels[0][2] = 8'd36; // ':'
    assign stage_labels[0][3] = 8'd37; // ' '
	assign stage_labels[0][4] = 8'd37; // ' '
    // Stage 1: ID
    assign stage_labels[1][0] = 8'd18; // 'I'
    assign stage_labels[1][1] = 8'd13; // 'D'
	assign stage_labels[1][2] = 8'd36; // ':'
    assign stage_labels[1][3] = 8'd37; // ' '
	assign stage_labels[0][4] = 8'd37; // ' '
    
	// Stage 2: EX
    assign stage_labels[2][0] = 8'd14; // 'E'
    assign stage_labels[2][1] = 8'd33; // 'X'
    assign stage_labels[2][2] = 8'd36; // ':'
	assign stage_labels[2][3] = 8'd37; // ' '
	assign stage_labels[2][4] = 8'd37; // ' '

    // Stage 3: MEM
    assign stage_labels[3][0] = 8'd22; // 'M'
    assign stage_labels[3][1] = 8'd14; // 'E'
    assign stage_labels[3][2] = 8'd22; // 'M'
	assign stage_labels[3][3] = 8'd36; // ':'
	assign stage_labels[3][4] = 8'd37; // ' '
    
	// Stage 4: WB
    assign stage_labels[4][0] = 8'd32; // 'W'
    assign stage_labels[4][1] = 8'd11; // 'B'
	assign stage_labels[4][3] = 8'd36; // ':'
    assign stage_labels[4][2] = 8'd37; // ' '
	assign stage_labels[4][4] = 8'd37; // ' '

    // --- Character ROM Input Selection ---
    wire [7:0] char_ascii; // ASCII code of the character to draw
    
    // Determine the character based on whether we are drawing the label (0-2) or the data (3-10)
    always @(*) begin
        if (char_line_idx < LABEL_WIDTH) begin
            // Drawing the Label (Static)
            char_ascii = stage_labels[stage_index][char_line_idx];
        end else begin
            // Drawing the Data (Dynamic Hex)
            char_ascii = current_value[(DATA_WIDTH - 1 - (char_line_idx - LABEL_WIDTH)) * 4 +: 4]; // Extract 4 bits
        end
    end
    
    // --- Instantiate the Character ROM ---
    wire [63:0] pixelLine;
    character bmp_inst (
        .digit(char_ascii),
        .pixelLine(pixelLine)
    );

    // X/Y Calculation
    assign pipeline_x = 300 + (char_line_idx * 9) + pixel_x; 
    assign pipeline_y = 25 + (stage_index * 15) + pixel_y; 

    // Pixel decoding and Color Assignment
    wire [7:0] current_row = pixelLine[(pixel_y * 8) +: 8]; 
    wire pixel_on = current_row[7 - pixel_x];
    
    assign pipeline_color = pixel_on ? 9'b111111111 : 3'b000;

endmodule


module char_drawer_logic(clock, resetn, char_count, done, char_idx, done, pixel_x, pixel_y); 
	input clock; 
    input resetn; 
    input [4:0] char_count; // Max number of characters to draw (e.g., 16)
    output reg done;        // Set high when all characters are drawn
    output reg [4:0] char_idx; // Current character index (0 to CHAR_COUNT-1)
    output reg [2:0] pixel_x;  // Current pixel column (0 to 7)
    output reg [2:0] pixel_y;   // Current pixel row (0 to 7)

	// Draws out the title 
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            pixel_x <= 0;
            pixel_y <= 0;
            char_idx <= 0;
            done <= 1'b0;
        end else begin
            // Clear done signal at the start of a cycle
            done <= 1'b0;
            
            if (char_idx == char_count) begin
                // If we've drawn all characters, set done and reset
                done <= 1'b1;
                pixel_x <= 0;
                pixel_y <= 0;
                char_idx <= 0;
            end else begin
                // Iterate through X pixels (0 -> 7)
                if (pixel_x == 7) begin 
                    pixel_x <= 0;
                    // Iterate through Y pixels (0 -> 7)
                    if (pixel_y == 7) begin
                        pixel_y <= 0;
                        // Iterate through characters (0 -> CHAR_COUNT-1)
                        char_idx <= char_idx + 1;
                    end else begin
                        pixel_y <= pixel_y + 1; 
                    end
                end else begin
                    pixel_x <= pixel_x + 1; 
                end
            end
        end
    end
endmodule
