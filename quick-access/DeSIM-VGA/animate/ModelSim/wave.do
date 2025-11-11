onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label KEY -radix binary /testbench/KEY
add wave -noupdate -label SW -radix binary /testbench/SW
add wave -noupdate -label VGA_X -radix hexadecimal /testbench/VGA_X
add wave -noupdate -label VGA_Y -radix hexadecimal /testbench/VGA_Y
add wave -noupdate -label VGA_COLOR -radix hexadecimal /testbench/VGA_COLOR
add wave -noupdate -label plot -radix binary /testbench/plot
add wave -noupdate -divider vga_demo
add wave -noupdate -label req1 -radix hexadecimal /testbench/U1/req1
add wave -noupdate -label req2 -radix hexadecimal /testbench/U1/req2
add wave -noupdate -label gnt1 -radix hexadecimal /testbench/U1/gnt1
add wave -noupdate -label gnt2 -radix hexadecimal /testbench/U1/gnt2
add wave -noupdate -label MUX_write -radix binary /testbench/U1/MUX_write
add wave -noupdate -label MUX_x -radix hexadecimal /testbench/U1/MUX_x
add wave -noupdate -label MUX_y -radix hexadecimal /testbench/U1/MUX_y
add wave -noupdate -label MUX_color -radix hexadecimal /testbench/U1/MUX_color
add wave -noupdate -divider object
add wave -noupdate -label Clock -radix binary /testbench/U1/O1/Clock
add wave -noupdate -label Resetn -radix binary /testbench/U1/O1/Resetn
add wave -noupdate -label x -radix hexadecimal /testbench/U1/O1/X
add wave -noupdate -label y -radix hexadecimal /testbench/U1/O1/Y
add wave -noupdate -label xC -radix hexadecimal /testbench/U1/O1/XC
add wave -noupdate -label yC -radix hexadecimal /testbench/U1/O1/YC
add wave -noupdate -label FSM -radix hexadecimal /testbench/U1/O1/y_Q
add wave -noupdate -label req -radix hexadecimal /testbench/U1/O1/req
add wave -noupdate -label gnt -radix hexadecimal /testbench/U1/O1/gnt
add wave -noupdate -label slow -radix hexadecimal /testbench/U1/O1/slow
add wave -noupdate -label sync -radix binary /testbench/U1/O1/sync
add wave -noupdate -label FSMfs -radix hexadecimal /testbench/U1/O1/ys_Q
add wave -noupdate -label faster -radix binary /testbench/U1/O1/faster
add wave -noupdate -label slower -radix binary /testbench/U1/O1/slower
add wave -noupdate -label mask -radix hexadecimal /testbench/U1/O1/mask
add wave -noupdate -divider vga_adapter
add wave -noupdate -label VGA_X -radix hexadecimal /testbench/U1/VGA/VGA_X
add wave -noupdate -label VGA_Y -radix hexadecimal /testbench/U1/VGA/VGA_Y
add wave -noupdate -label VGA_COLOR -radix hexadecimal /testbench/U1/VGA/VGA_COLOR
add wave -noupdate -label write -radix binary /testbench/U1/VGA/write
add wave -noupdate -label plot -radix binary /testbench/U1/VGA/plot
add wave -noupdate -label color -radix binary /testbench/U1/VGA/color
add wave -noupdate -label x -radix hexadecimal /testbench/U1/VGA/x
add wave -noupdate -label y -radix hexadecimal /testbench/U1/VGA/y
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {120 ns}
