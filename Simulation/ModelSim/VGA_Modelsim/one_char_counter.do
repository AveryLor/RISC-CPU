# quit simulator if running
quit -sim

# create the default "work" library
vlib work

# compile all Verilog files in current directory
vlog *.v

# start simulator with required libraries
vsim work.one_char_counter_tb -Lf 220model_ver -Lf altera_mf_ver -Lf verilog

# add all signals from testbench to waveform
add wave /one_char_counter_tb/*


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label Clk -radix binary /testbench/Clk
add wave -noupdate -label R -radix binary /testbench/R
add wave -noupdate -label S -radix binary /testbench/S
add wave -noupdate -divider Outputs
add wave -noupdate -label Q /testbench/U1/Qa
add wave -noupdate -label Qb /testbench/U1/Qb
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 38
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
WaveRestoreZoom {0 ps} {80 ns}

run 400 ns