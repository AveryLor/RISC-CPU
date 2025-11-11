To use this demo:

This demo uses the VGA output display in the DESim GUI. It first displays a background 
image (MIF) on the VGA output, which is read from the video memory. The code then animates 
two colored objects that move up/down on the display. The objects "bounce" off the top and 
bottom of the display and reverse directions. To run the code first press/release KEY[0] 
to reset the circuit. Select one object by making SW[9] = 0.  Then, press/release KEY[1] 
to set the object's color according to switches SW[8:0] (9-bit color), or SW[5:0] 
(6-bit color), or SW[2:0] (3-bit color). Press KEY[2] to increase the speed of the selected
object, or press KEY[3] to decrease the speed. Set SW[9] = 1 to select the other object, 
and then set its color and/or speed.

The VGA resolution can be set to 640x480, 320x240, or 160x120. The color depth can be set 
to 3-, 6-, or 9-bit color. Set these parameters in top.v.


