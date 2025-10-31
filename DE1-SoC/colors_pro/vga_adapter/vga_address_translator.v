/* This module converts a user specified coordinates into a memory address.
 * The output of the module depends on the resolution set by the user.
 */
module vga_address_translator(x, y, mem_address);

    parameter nX = 9, nY = 8, Mn = 17;  // default bit widths
    
	input wire [nX-1:0] x; 
	input wire [nY-1:0] y;	
	output wire [Mn-1:0] mem_address;
	
	/* The basic formula is address = y*WIDTH + x;
	 * For 320x240 resolution we can write 320 as (256 + 64). Memory address becomes
	 * (y*256) + (y*64) + x;
	 * This simplifies multiplication a simple shift and add operation.
	 * A leading 0 bit is added to each operand to ensure that they are treated as unsigned
	 * inputs. By default the use a '+' operator will generate a signed adder.
	 * Similarly, for 160x120 resolution we write 160 as 128+32.
     * For 640 we use 512 + 128
	 */

    assign mem_address = {1'b0, y, {nY{1'b0}}} + {1'b0, y, {nY-2{1'b0}}} + {1'b0, x};
    
endmodule
