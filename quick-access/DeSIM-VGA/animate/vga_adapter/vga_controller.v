/* DESim VGA controller. This code reads the contents of the video memory and
*  draws this background image onto the VGA output. When done, the VGA_SYNC
*  output is set to 1. */

module vga_controller(vga_clock, resetn, pixel_color, memory_address, 
    VGA_X, VGA_Y, VGA_COLOR, VGA_SYNC, plot);
    
	parameter COLOR_DEPTH = 3;          // color depth for the video memory
    parameter nX = 8, nY = 7, Mn = 15;  // default bit widths
    parameter COLS = 160, ROWS = 120;   // default COLS x ROWS memory

    /*****************************************************************************/
    /* Declare inputs and outputs.                                               */
    /*****************************************************************************/
    input wire vga_clock, resetn;
    input wire [COLOR_DEPTH-1:0] pixel_color;
    output wire [Mn-1:0] memory_address;
    output wire [nX-1:0] VGA_X;
    output wire [nY-1:0] VGA_Y;
    output wire [23:0] VGA_COLOR;
    output reg VGA_SYNC;
    output reg plot;
    
    /*****************************************************************************/
    /* Local Signals.                                                            */
    /*****************************************************************************/
    reg [9:0] xCounter, yCounter;
    wire xCounter_clear;
    wire yCounter_clear;
    
    reg [nX-1:0] x; 
    reg [nY-1:0] y;    
    reg Enxy;

    reg [1:0] Y_D, y_Q;
    parameter A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;
    
    /*****************************************************************************/
    /* Controller implementation.                                                */
    /*****************************************************************************/
    
    /* A counter to scan through the rows */
    always @(posedge vga_clock or negedge resetn)
    begin
        if (!resetn)
            xCounter <= 10'd0;
        else if (xCounter_clear)
            xCounter <= 10'd0;
        else if (Enxy)
            xCounter <= xCounter + 1'b1;
    end
    assign xCounter_clear = (xCounter == (COLS-1));

    /* A counter to scan over the columns */
    always @(posedge vga_clock or negedge resetn)
    begin
        if (!resetn)
            yCounter <= 10'd0;
        else if (xCounter_clear && yCounter_clear)
            yCounter <= 10'd0;
        else if (xCounter_clear)    //Increment when x counter resets
            yCounter <= yCounter + 1'b1;
    end
    assign yCounter_clear = (yCounter == (ROWS-1)); 
    
    /* Change the (x,y) coordinate into a memory address. */
    vga_address_translator controller_translator(
        .x(xCounter[nX-1:0]), .y(yCounter[nY-1:0]), .mem_address(memory_address) );
        defparam controller_translator.nX = nX;
        defparam controller_translator.nY = nY;
        defparam controller_translator.Mn = Mn;

    always @ (posedge vga_clock) // sync with the pixel_color from memory
    begin
      if (!resetn)
      begin
          x <= 0;
          y <= 0;
      end
      begin
          x <= xCounter;
          y <= yCounter;
      end
    end

    assign VGA_X = x;
    assign VGA_Y = y;
    // convert COLOR_DEPTH to 24-bit color
    vga_convert UC (pixel_color, VGA_COLOR);
        defparam UC.COLOR_DEPTH = COLOR_DEPTH;
    
    // FSM state for the the plot signals
    always @ (*)
        case (y_Q)
            A:  Y_D = B;
            B:  Y_D = C;
            C:  if (yCounter_clear && xCounter_clear) Y_D = D; // draw background
                else Y_D = C;   // done background
            default:  Y_D = D;
        endcase
    // FSM outputs
    always @ (*)
    begin
        // default assignments
        Enxy = 1'b0; plot = 1'b0; VGA_SYNC = 1'b0;
        case (y_Q)
            A:  ;
            B:  Enxy = 1'b1;
            C:  begin Enxy = 1'b1; plot = 1'b1; end
            D:  begin Enxy = 1'b0; plot = 1'b1; VGA_SYNC = 1'b1; end
        endcase
    end

    always @(posedge vga_clock)
        if (!resetn)
            y_Q <= 1'b0;
        else
            y_Q <= Y_D;

endmodule
