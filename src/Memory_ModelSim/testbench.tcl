quit -sim
vlog simple_sync_bram.v
vlog bram_addresser_with_brams.v
vlog tb_bram_addresser.v
vsim -c tb_bram_addresser
run 100 ns