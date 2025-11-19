# Clean old libraries
vdel -all
vlib work

# Compile DUT and testbench
vlog hdu.v
vlog hdu_tb.v

# Load simulation (note: module name is HDU_tb)
vsim work.HDU_tb

# Add all signals to the waveform
add wave *

# Run enough time for all cases to execute
run 200ns
