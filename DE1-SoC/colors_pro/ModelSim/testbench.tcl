# stop any simulation that is currently running
quit -sim

# copy any files in the MIF folder
if {[file exists MIF]} {
	file delete -force -- MIF
    file copy ../MIF .
} else {
    file copy ../MIF .
}

# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog ../vga_demo.v ../vga_adapter/*.v
# compile the Verilog code of the testbench
vlog *.v
# start the Simulator, including some libraries that may be needed
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 800 ns
