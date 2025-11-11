To use this demo:

This Verilog demonstration code uses the VGA output window in the DESim GUI. It displays on 
the VGA window an image that is read from a memory initialized by a MIF file. After the image 
has been read from the memory and displayed, the Verilog code illuminates LEDR[9].

The color depth of the image is set in vga_demo.v. Three depths are supported: 3-, 6-, and 9-bit
color. The VGA resolution that is selected in the DESim GUI must match the setting in the file 
top.v.  Three resolutions are supported: 640x480, 320x240, and 160x120.
