# clean up any previous run
vdel -all
vlib work

# compile DUT and testbench
vlog reg_file.v
vlog reg_file_tb.v

# load simulation
vsim work.reg_file_tb

# add all signals to waveform
add wave *

# run for a safe amount of time
run 500ns
