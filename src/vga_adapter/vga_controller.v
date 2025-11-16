/* This module implements the VGA controller. It assumes a 25MHz clock is supplied as input.
 * General approach:
 * Go through each line of the screen and read the color each pixel on that line should have from
 * the Video memory. To do that for each (x,y) pixel on the screen convert (x,y) coordinate to
 * a memory_address at which the pixel color is stored in Video memory. Once the pixel color is
 * read from video memory its brightness is first increased before it is forwarded to the VGA DAC.
 */
module vga_controller(vga_clock, resetn, pixel_color, memory_address, 
		VGA_R, VGA_G, VGA_B,
		VGA_HS, VGA_VS, VGA_BLANK_N,
		VGA_SYNC_N, VGA_CLK);
	
    // The VGA resolution, which can be set to "640x480", "320x240", and "160x120"
    parameter RESOLUTION = "160x120";
	parameter COLOR_DEPTH = 3;          // color depth for the video memory
    parameter nX = 8, nY = 7, Mn = 15;  // default bit widths
    parameter COLS = 160, ROWS = 120;   // default COLS x ROWS memory
    // See video adaptor for descriptions of the above parameters
    
	// Timing parameters:
	/* The VGA specification requires that a few more rows and columns are drawn
	 * than are actually present on the screen. This is necessary to generate the vertical
     * and horizontal syncronization signals.  */
	parameter C_VERT_NUM_PIXELS  = 11'd480;
	parameter C_VERT_SYNC_START  = 11'd493;
	parameter C_VERT_SYNC_END    = 11'd494; //(C_VERT_SYNC_START + 2 - 1); 
	parameter C_VERT_TOTAL_COUNT = 11'd525;

	parameter C_HORZ_NUM_PIXELS  = 11'd640;
	parameter C_HORZ_SYNC_START  = 11'd659;
	parameter C_HORZ_SYNC_END    = 11'd754; //(C_HORZ_SYNC_START + 96 - 1); 
	parameter C_HORZ_TOTAL_COUNT = 11'd800;	
		
	/*****************************************************************************/
	/* Declare inputs and outputs.                                               */
	/*****************************************************************************/
	
	input wire vga_clock, resetn;
	input wire [COLOR_DEPTH-1:0] pixel_color;
	output wire [Mn-1:0] memory_address;
	output reg [7:0] VGA_R;
	output reg [7:0] VGA_G;
	output reg [7:0] VGA_B;
	output reg VGA_HS;
	output reg VGA_VS;
	output reg VGA_BLANK_N;
	output wire VGA_SYNC_N, VGA_CLK;
	
	/*****************************************************************************/
	/* Local Signals.                                                            */
	/*****************************************************************************/
	
	reg VGA_HS1;
	reg VGA_VS1;
	reg VGA_BLANK1; 
	reg [9:0] xCounter, yCounter;
	wire xCounter_clear;
	wire yCounter_clear;
	wire vcc;
	
	reg [nX-1:0] x; 
	reg [nY-1:0] y;	
	/* Inputs to the converter. */
	
	/*****************************************************************************/
	/* Controller implementation.                                                */
	/*****************************************************************************/

	assign vcc =1'b1;
	
	/* A counter to scan through a horizontal line. */
	always @(posedge vga_clock or negedge resetn)
	begin
		if (!resetn)
			xCounter <= 10'd0;
		else if (xCounter_clear)
			xCounter <= 10'd0;
		else
		begin
			xCounter <= xCounter + 1'b1;
		end
	end
	assign xCounter_clear = (xCounter == (C_HORZ_TOTAL_COUNT-1));

	/* A counter to scan vertically, indicating the row currently being drawn. */
	always @(posedge vga_clock or negedge resetn)
	begin
		if (!resetn)
			yCounter <= 10'd0;
		else if (xCounter_clear && yCounter_clear)
			yCounter <= 10'd0;
		else if (xCounter_clear)		//Increment when x counter resets
			yCounter <= yCounter + 1'b1;
	end
	assign yCounter_clear = (yCounter == (C_VERT_TOTAL_COUNT-1)); 
	
	/* Convert the xCounter/yCounter location from screen pixels (640x480) to our
	 * local dots (320x240 or 160x120). Here we effectively divide x/y coordinate by 2 or 4,
	 * depending on the resolution. */
	always @(*)
	begin
        x = xCounter[9:(RESOLUTION == "640x480") ? 0 : ((RESOLUTION == "320x240") ? 1 : 2)];
        y = yCounter[8:(RESOLUTION == "640x480") ? 0 : ((RESOLUTION == "320x240") ? 1 : 2)];
	end
	
	/* Change the (x,y) coordinate into a memory address. */
	vga_address_translator controller_translator(
					.x(x), .y(y), .mem_address(memory_address) );
		defparam controller_translator.nX = nX;
		defparam controller_translator.nY = nY;
		defparam controller_translator.Mn = Mn;


	/* Generate the vertical and horizontal synchronization pulses. */
	always @(posedge vga_clock)
	begin
		//- Sync Generator (ACTIVE LOW)
		VGA_HS1 <= ~((xCounter >= C_HORZ_SYNC_START) && (xCounter <= C_HORZ_SYNC_END));
		VGA_VS1 <= ~((yCounter >= C_VERT_SYNC_START) && (yCounter <= C_VERT_SYNC_END));
		
		//- Current X and Y is valid pixel range
		VGA_BLANK1 <= ((xCounter < C_HORZ_NUM_PIXELS) && (yCounter < C_VERT_NUM_PIXELS));	
	
		//- Add 1 cycle delay
		VGA_HS <= VGA_HS1;
		VGA_VS <= VGA_VS1;
		VGA_BLANK_N <= VGA_BLANK1;	
	end
	
	/* VGA sync should be 1 at all times. */
	assign VGA_SYNC_N = vcc;
	
	/* Generate the VGA clock signal. */
	assign VGA_CLK = vga_clock;
	
	parameter BITS_PER_RGB = COLOR_DEPTH / 3;
    // Number of bits for each R, G, B component
    
	/* Brighten the color output. */
	// The color input is first processed to brighten the image.  To brighten the image, the
    // bits of each component are replicated through the 8 DAC color bits. For example,
	// if BITS_PER_RGB is 2 and the red component is set to R = 2'b10, then the VGA_R output 
    // to the DAC will be set to 8'b10101010.
	
	integer index;
	integer sub_index;
	
	wire on_screen;
	
	assign on_screen = (({1'b0, xCounter} >= 0) & ({1'b0, xCounter} < C_HORZ_NUM_PIXELS+2) &
                       ({1'b0, yCounter} < C_VERT_NUM_PIXELS));
	
	always @(pixel_color or on_screen)
	begin		
		VGA_R <= 'b0;
		VGA_G <= 'b0;
		VGA_B <= 'b0;
			for (index = 8-BITS_PER_RGB; index >= 0; index = index - BITS_PER_RGB)
			begin
				for (sub_index = BITS_PER_RGB - 1; sub_index >= 0; sub_index = sub_index - 1)
				begin
					VGA_R[sub_index+index] <= on_screen & pixel_color[sub_index + BITS_PER_RGB*2];
					VGA_G[sub_index+index] <= on_screen & pixel_color[sub_index + BITS_PER_RGB];
					VGA_B[sub_index+index] <= on_screen & pixel_color[sub_index];
				end
			end	
	end

endmodule
