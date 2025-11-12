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
	      
	$display("bram 4k + 3 @ addr 0: %h", dut.bram0.mem[0]);
	$display("bram 4k + 2 @ addr 0: %h", dut.bram1.mem[0]);
	$display("bram 4k + 1 @ addr 0: %h", dut.bram2.mem[0]);
	$display("bram 4k + 0 @ addr 0: %h", dut.bram3.mem[0]);
	tb_memory_address = 32'd0;
        tb_data_to_store = 32'hF0F1F2F3;
        tb_memory_access_code = 5'b1_1111;

	$display(" ");
	@(negedge clk); $display("clock 0! We just stored F0F1F2F3 in memory.");   
	$display("bram 4k + 3 @ addr 0: %h", dut.bram0.mem[0]);
	$display("bram 4k + 2 @ addr 0: %h", dut.bram1.mem[0]);
	$display("bram 4k + 1 @ addr 0: %h", dut.bram2.mem[0]);
	$display("bram 4k + 0 @ addr 0: %h", dut.bram3.mem[0]);   
	tb_memory_address = 32'd4;
        tb_data_to_store = 32'hA0A1A2A3;
        tb_memory_access_code = 5'b1_1111;   

	$display(" ");
	@(negedge clk); $display("clock 1! We just stored A0A1A2A3 after that.");
	$display("dout:");
	$display("bram 4k + 3 dout: %h", dut.bram0.dout);
	$display("bram 4k + 2 dout: %h", dut.bram1.dout);
	$display("bram 4k + 1 dout: %h", dut.bram2.dout);
	$display("bram 4k + 0 dout: %h", dut.bram3.dout);
	$display("we:");
	$display("bram 4k + 3 we: %b", dut.B_write_enable[3]);
	$display("bram 4k + 2 we: %b", dut.B_write_enable[2]);
	$display("bram 4k + 1 we: %b", dut.B_write_enable[1]);
	$display("bram 4k + 0 we: %b", dut.B_write_enable[0]);
	$display("address:");
	$display("bram 4k + 3 addr: %d", dut.B_address[3]);
	$display("bram 4k + 2 addr: %d", dut.B_address[2]);
	$display("bram 4k + 1 addr: %d", dut.B_address[1]);
	$display("bram 4k + 0 addr: %d", dut.B_address[0]);
	tb_memory_address = 32'd0;
        tb_data_to_store = 32'hEEEEEEEE;
	tb_memory_access_code = 5'b0_1111;  

	$display(" ");
	@(negedge clk); $display("clock 2! We just read the first word we stored, but it's not ready to writeback yet.");
	$display("writeback @ addr %d with byte_enable %b: %h (expected: xxxxxxxx)", tb_memory_address, tb_memory_access_code[3:0], tb_writeback_register_data);
	$display("dout:");
	$display("bram 4k + 3 dout: %h", dut.bram0.dout);
	$display("bram 4k + 2 dout: %h", dut.bram1.dout);
	$display("bram 4k + 1 dout: %h", dut.bram2.dout);
	$display("bram 4k + 0 dout: %h", dut.bram3.dout);
	$display("we:");
	$display("bram 4k + 3 we: %b", dut.B_write_enable[3]);
	$display("bram 4k + 2 we: %b", dut.B_write_enable[2]);
	$display("bram 4k + 1 we: %b", dut.B_write_enable[1]);
	$display("bram 4k + 0 we: %b", dut.B_write_enable[0]);
	$display("address:");
	$display("bram 4k + 3 addr: %d", dut.B_address[3]);
	$display("bram 4k + 2 addr: %d", dut.B_address[2]);
	$display("bram 4k + 1 addr: %d", dut.B_address[1]);
	$display("bram 4k + 0 addr: %d", dut.B_address[0]);
	tb_memory_address = 32'd0;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  

	$display(" ");
	@(negedge clk); $display("clock 3! We finished the writeback, and also started reading the next word.");
	$display("writeback @ addr %d with byte_enable %b: %h (expected: f0f1f2f3)", tb_memory_address, tb_memory_access_code[3:0], tb_writeback_register_data);
	$display("dout:");
	$display("bram 4k + 3 dout: %h", dut.bram0.dout);
	$display("bram 4k + 2 dout: %h", dut.bram1.dout);
	$display("bram 4k + 1 dout: %h", dut.bram2.dout);
	$display("bram 4k + 0 dout: %h", dut.bram3.dout);
	$display("we:");
	$display("bram 4k + 3 we: %b", dut.B_write_enable[3]);
	$display("bram 4k + 2 we: %b", dut.B_write_enable[2]);
	$display("bram 4k + 1 we: %b", dut.B_write_enable[1]);
	$display("bram 4k + 0 we: %b", dut.B_write_enable[0]);
	$display("address:");
	$display("bram 4k + 3 addr: %d", dut.B_address[3]);
	$display("bram 4k + 2 addr: %d", dut.B_address[2]);
	$display("bram 4k + 1 addr: %d", dut.B_address[1]);
	$display("bram 4k + 0 addr: %d", dut.B_address[0]);
	tb_memory_address = 32'd4;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  

	$display(" ");
	@(negedge clk); $display("clock 4! We finished the writeback, and did a memory no-op");
	$display("writeback @ addr %d with byte_enable %b: %h (expected: a0a1a2a3)", tb_memory_address, tb_memory_access_code[3:0], tb_writeback_register_data);
	$display("dout:");
	$display("bram 4k + 3 dout: %h", dut.bram0.dout);
	$display("bram 4k + 2 dout: %h", dut.bram1.dout);
	$display("bram 4k + 1 dout: %h", dut.bram2.dout);
	$display("bram 4k + 0 dout: %h", dut.bram3.dout);
	$display("we:");
	$display("bram 4k + 3 we: %b", dut.B_write_enable[3]);
	$display("bram 4k + 2 we: %b", dut.B_write_enable[2]);
	$display("bram 4k + 1 we: %b", dut.B_write_enable[1]);
	$display("bram 4k + 0 we: %b", dut.B_write_enable[0]);
	$display("address:");
	$display("bram 4k + 3 addr: %d", dut.B_address[3]);
	$display("bram 4k + 2 addr: %d", dut.B_address[2]);
	$display("bram 4k + 1 addr: %d", dut.B_address[1]);
	$display("bram 4k + 0 addr: %d", dut.B_address[0]);
    end
endmodule