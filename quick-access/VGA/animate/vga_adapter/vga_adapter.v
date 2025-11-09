/* VGA Adapter
 * ----------------
 *
 * This is an implementation of a VGA Adapter. The adapter uses VGA mode signalling to initiate
 * a 640x480 resolution mode on a computer monitor, with a refresh rate of approximately 60Hz.
 *
 * This implementation of the VGA adapter can display images of varying color depth at a 
 * resolution of 640x480 pixels. You can also select a resolution of 320x240 or 160x120. For 
 * these resolutions the adapter draws each "pixel" as a 2x2, or 4x4, block, respectively, on 
 * the 640x480 display. 
 *
 * The number of bits of on-chip memory used by the adapter for the video memory is given by:
 *
 *     memory bits = COLS x ROWS x COLOR_DEPTH
 *
 *     Examples for DE1-SoC with COLOR_DEPTH = 3, 6, 9 (total colors = 8, 64, 512): 
 *       640 x 480: x 3 = 921,600 bits, x 6 = 1,843,200 bit, x 9 = 2,764,800 bits
 *       320 x 240: x 3 = 230,400 bits, x 6 = 460,800 bits,  x 9 = 691,200 bits 
 *       160 x 120: x 3 = 57,600 bits,  x 6 = 115,200 bits,  x 9 = 172,800 bits
 *
 * The VGA resolution is set in the file resolution.v. The color-depth of the video memory is
 * set by the parameter COLOR_DEPTH.
 *
 * The video memory can be loaded with an image from a memory initialization file (MIF) during
 * FPGA programming. The MIF is specified by using the parameter BACKGROUND_IMAGE.
 *
 * To use this module connect the vga_adapter to your circuit. Your circuit should produce a 
 * value for inputs color, x, y and write. When write is high, at the next positive edge of the 
 * input clock the vga_adapter will change the contents of the video memory for the pixel at 
 * location (x,y). At the next redraw * cycle the VGA controller will update the external video
 * monitor. Since the monitor has no memory, the VGA controller copies the contents of the 
 * video memory to the screen once every 60th of a second, which keeps the image stable.
 *
 * Make sure to include the required VGA signal pin assignments for the DE1-SoC board. Connect
 * the clock input to 50 MHz CLOCK_50 pin.
 *
 * During compilation with Quartus Prime you may receive a number of warning messages related
 * to a phase-locked loop (PLL), and a message about VGA_SYNC_N being stuck at Vcc. You can 
 * safely ignore these warnings. 
 */

module vga_adapter( resetn, clock, color, x, y, write,
                    VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
 
    // The VGA resolution, which can be set to "640x480", "320x240", and "160x120"
    parameter RESOLUTION = "640x480";
    /* The number of bits used to represent a pixel. An equal number of bits is allocated for 
     * the red (R), green (G) and blue (B) components. Thus, for COLOR_DEPTH = 3, there is one bit
     * for each of the R, G, B components, and eight different colors can be displayed. */
    parameter COLOR_DEPTH = 9;  // default
    
    // Number of VGA pixel X coordinate (column) and Y coordinate (row) bits
    parameter nX = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);
    parameter nY = (RESOLUTION == "640x480") ? 9 : ((RESOLUTION == "320x240") ? 8 : 7);

    // Number of address bits on the video memory
    parameter Mn = (RESOLUTION == "640x480") ? 19 : ((RESOLUTION == "320x240") ? 17 : 15);

    // Number of columns and rows in the video memory
    parameter COLS = (RESOLUTION == "640x480") ? 640 : ((RESOLUTION == "320x240") ? 320 : 160);
    parameter ROWS = (RESOLUTION == "640x480") ? 480 : ((RESOLUTION == "320x240") ? 240 : 120);

    parameter BACKGROUND_IMAGE = "./rainbow_640_9.mif";
    /* The initial screen displayed when the circuit is first programmed onto the DE1-SoC board 
     * can be defined using a MIF file. The file contains the initial color for each pixel on the
     * screen and is placed in the video memory when the FPGA is programmed. Note that resetting
     * the VGA Adapter does NOT cause the video memory to be reloaded from the MIF file. */

    // Declare inputs and outputs
    input wire resetn;
    input wire clock;
    
    input wire [COLOR_DEPTH-1:0] color;
    
    /* Specify the number of bits required to represent an (X,Y) coordinate */
    input wire [nX-1:0] x; 
    input wire [nY-1:0] y;
    
    /* When write is 1, then at the next positive edge of the clock the pixel at (x,y) will be
     * set to the value of the color input. */
    input wire write;
    
    // These outputs drive the VGA display
    output wire [7:0] VGA_R; // red output
    output wire [7:0] VGA_G; // green output
    output wire [7:0] VGA_B; // blue output
    output wire VGA_HS;      // horizontal sync
    output wire VGA_VS;      // vertical sync
    output wire VGA_BLANK_N; // used by video DAC to blank the display
    output wire VGA_SYNC_N;  // video DAC signal that is not used for VGA applications
    output wire VGA_CLK;     // video DAC clock signals

    /*****************************************************************************/
    /* Declare local signals here.                                               */
    /*****************************************************************************/
    
    // This signal is 1 if the specified coordinates are in a valid range for a given resolution
    wire valid_address;
    
    /* This signal that allows the Video Memory contents to be changed. It depends on the screen
     * resolution, the values of X and Y inputs, as well as the write signal. */
    wire writeEn;
    
    // Pixel color read by the VGA controller
    wire [COLOR_DEPTH-1:0] to_ctrl_color;
    
    /* This bus specifies the address in memory corresponding to pixel location (X,Y). It is used
     * along with the write signal to write colors into pixels. */
    wire [Mn-1:0] user_to_video_memory_addr;
    
    wire [Mn-1:0] controller_to_video_memory_addr;
    /* Specifies the address in memory corresponding to pixel location (X,Y). It is used by the
     * VGA controller to read the pixel colors from memory that are sent to the VGA outputs. */
    
    wire clock_25;
    /* 25MHz clock VGA clock generated by dividing the input clock frequency by 2. */
    
    wire vcc, gnd;
    
    /*****************************************************************************/
    /* Instances of modules for the VGA adapter.                                 */
    /*****************************************************************************/    

    assign vcc = 1'b1;
    assign gnd = 1'b0;
    
    vga_address_translator user_input_translator (.x(x), .y(y), 
                                                  .mem_address(user_to_video_memory_addr));
        defparam user_input_translator.nX = nX;
        defparam user_input_translator.nY = nY;
        defparam user_input_translator.Mn = Mn;
        // Convert X, Y coordinates into a memory address

    assign valid_address = ({1'b0, x} >= 0) & ({1'b0, x} < COLS) & ({1'b0, y} >= 0) &
                           ({1'b0, y} < ROWS);
    assign writeEn = write & valid_address;
    // write the user's pixel if the (x,y) coordinates supplied are in a valid range
    
    // Create the dual-port video memory
    altsyncram VideoMemory (
        .wren_a (writeEn),      // write enable for port a
        .wren_b (gnd),          // write enable for port b
        .clock0 (clock),        // write clock
        .clock1 (clock_25),     // VGA (read) clock
        .clocken0 (vcc),        // write enable clock
        .clocken1 (vcc),        // read enable clock                
        .address_a (user_to_video_memory_addr),
        .address_b (controller_to_video_memory_addr),
        .data_a (color),        // data in from user
        .q_b (to_ctrl_color)    // data out to controller
    );
    defparam
        VideoMemory.width_a = (COLOR_DEPTH),
        VideoMemory.width_b = (COLOR_DEPTH),
        VideoMemory.intended_device_family = "Cyclone V",
        VideoMemory.operation_mode = "DUAL_PORT",
        VideoMemory.widthad_a = (Mn),
        VideoMemory.numwords_a = (COLS * ROWS),
        VideoMemory.widthad_b = (Mn),
        VideoMemory.numwords_b = (COLS * ROWS),
        VideoMemory.outdata_reg_b = "CLOCK1",
        VideoMemory.address_reg_b = "CLOCK1",
        VideoMemory.clock_enable_input_a = "BYPASS",
        VideoMemory.clock_enable_input_b = "BYPASS",
        VideoMemory.clock_enable_output_b = "BYPASS",
        VideoMemory.power_up_uninitialized = "FALSE",
        VideoMemory.init_file = BACKGROUND_IMAGE;
        
    /* This module generates a VGA clock with half the frequency of the input clock. For the 
     * VGA adapter to operate correctly the clock signal 'clock' must be a 50MHz clock. The 
     * derived clock, which will then operate at 25MHz, sets the VGA monitor into the 
     * 640 x 480 @60Hz display mode (also known as "VGA mode"). */
    vga_pll mypll(clock, clock_25);
    
    vga_controller controller(
            .vga_clock(clock_25),            // VGA clock
            .resetn(resetn),
            .pixel_color(to_ctrl_color),     // pixel color, read from video memory
            .memory_address(controller_to_video_memory_addr), // address sent to video memory
            .VGA_R(VGA_R),                   // VGA Red component
            .VGA_G(VGA_G),                   // VGA Green component
            .VGA_B(VGA_B),                   // VGA Blue component
            .VGA_HS(VGA_HS),                 // VGA horizontal sync
            .VGA_VS(VGA_VS),                 // VGA vertical sync
            .VGA_BLANK_N(VGA_BLANK_N),       // VGA DAC blanking signal
            .VGA_SYNC_N(VGA_SYNC_N),         // Not used for VGA mode
            .VGA_CLK(VGA_CLK)                // VGA clock output
        );
        defparam controller.RESOLUTION  = RESOLUTION ;
        defparam controller.COLOR_DEPTH  = COLOR_DEPTH ;
        defparam controller.nX = nX;
        defparam controller.nY = nY;
        defparam controller.Mn = Mn;
        defparam controller.ROWS = ROWS;
        defparam controller.COLS = COLS;

endmodule
    
