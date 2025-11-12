module tb_bram_addresser;
    reg         clk;
    reg  [31:0] tb_data_to_store;
    reg  [4:0]  tb_memory_access_code;
    reg  [31:0] tb_memory_address;
    wire [31:0] tb_writeback_register_data;
	

    // instantiate DUT (wrapper that includes BRAMs)
    bram_addresser_with_brams dut (
        .data_to_store(tb_data_to_store),
        .memory_access_code(tb_memory_access_code),
        .memory_address(tb_memory_address),
        .CLOCK_50(clk),
        .writeback_register_data(tb_writeback_register_data)
    );

    // clock generation: 20ns period (50MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        // VCD for viewing in ModelSim
        $dumpfile("bram_addresser_tb.vcd");
        $dumpvars(0, tb_bram_addresser);
		
		
        /* test vector format
        @(negedge clk);
	tb_memory_address = 32'd;
        tb_data_to_store = 32'h;
        tb_memory_access_code = 5'b0_0000;         // [4:1] byte_enable, [0] store not load
	if (tb_memory_access_code[0] == 1'b0)
	$display("writeback @ addr %d with byte_enable %b: %h (expected: )", tb_memory_address, tb_memory_access_code[4:1] tb_writeback_register_data);
	*/

	@(negedge clk);
	tb_memory_address = 32'd0;
        tb_data_to_store = 32'hF0F1F2F3;
        tb_memory_access_code = 5'b1_1111;         // [3:0] byte_enable, [4] store not load
		
	@(negedge clk);
	tb_memory_address = 32'd4;
        tb_data_to_store = 32'hA0A1A2A3;
        tb_memory_access_code = 5'b1_1111;         // [3:0] byte_enable, [4] store not load

	@(negedge clk);
	tb_memory_address = 32'd0;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;         // [3:0] byte_enable, [4] store not load
	$display("bram 4k + 0 @ addr 0: %h", dut.bram0.mem[0]);
	$display("bram 4k + 1 @ addr 0: %h", dut.bram1.mem[0]);
	$display("bram 4k + 2 @ addr 0: %h", dut.bram2.mem[0]);
	$display("bram 4k + 3 @ addr 0: %h", dut.bram3.mem[0]);
	
	$display("bram 4k + 0 dout: %h", dut.bram0.dout);
	$display("bram 4k + 1 dout: %h", dut.bram1.dout);
	$display("bram 4k + 2 dout: %h", dut.bram2.dout);
	$display("bram 4k + 3 dout: %h", dut.bram3.dout);

	@(negedge clk);
	// write to memory happens on next clock cycle... (is this bad?)
	$display("writeback @ addr %d with byte_enable %b: %h (expected: )", tb_memory_address, tb_memory_access_code[3:0], tb_writeback_register_data);
	$display("bram 4k + 0 dout: %h", dut.bram0.dout);
	$display("bram 4k + 1 dout: %h", dut.bram1.dout);
	$display("bram 4k + 2 dout: %h", dut.bram2.dout);
	$display("bram 4k + 3 dout: %h", dut.bram3.dout);

	tb_memory_address = 32'd4;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;         // [3:0] byte_enable, [4] store not load
	$display("writeback @ addr %d with byte_enable %b: %h (expected: )", tb_memory_address, tb_memory_access_code[3:0], tb_writeback_register_data);
		
		
    end
endmodule