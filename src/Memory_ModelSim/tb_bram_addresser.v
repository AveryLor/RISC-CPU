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
	$display(" ");
	$display("--- TEST 1: SUCCESSIVE ALIGNED WORD WRITES/READS ---");
	$display(" ");     
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
	tb_memory_address = 32'd4;
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

	$display(" ");
	$display("--- TEST 2: SEMI-ALIGNED HALFWORD AND BYTE WRITES ---");
	$display(" "); 

	tb_memory_address = 32'd10;
        tb_data_to_store = 32'hD4D5EEEE;
        tb_memory_access_code = 5'b1_1100;  
	
	@(negedge clk); $display("clock 5! Wrote halfword D4D5 @ address 10");

	tb_memory_address = 32'd8;
        tb_data_to_store = 32'hD0D1EEEE;
        tb_memory_access_code = 5'b1_1100;  
	$display(" ");
	@(negedge clk); $display("clock 6! Wrote halfword D0D1 @ address 8");

	tb_memory_address = 32'd15;
        tb_data_to_store = 32'hC6EEEEEE;
        tb_memory_access_code = 5'b1_1000;  
	$display(" ");
	@(negedge clk); $display("clock 7! Wrote byte C6 @ address 15");

	tb_memory_address = 32'd14;
        tb_data_to_store = 32'hC4EEEEEE;
        tb_memory_access_code = 5'b1_1000;  
	$display(" ");
	@(negedge clk); $display("clock 8! Wrote byte C4 @ address 14");

	tb_memory_address = 32'd13;
        tb_data_to_store = 32'hC2EEEEEE;
        tb_memory_access_code = 5'b1_1000;  
	$display(" ");
	@(negedge clk); $display("clock 9! Wrote byte C2 @ address 13");

	tb_memory_address = 32'd12;
        tb_data_to_store = 32'hC0EEEEEE;
        tb_memory_access_code = 5'b1_1000;  
	$display(" ");
	@(negedge clk); $display("clock 10! Wrote byte C0 @ address 12");

	tb_memory_address = 32'd8;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  
	$display(" ");
	@(negedge clk); $display("clock 11! Started read @ address 8.");

	tb_memory_address = 32'd12;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  
	$display(" ");
	@(negedge clk); $display("clock 12! Finished previous read, and started read @ address 12");
	$display("writeback: %h (expected: d0d1d4d5)", tb_writeback_register_data);

	tb_memory_address = 32'd12;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_0000;  
	$display(" ");
	@(negedge clk); $display("clock 13! Finished previous read, and did a memory no-op");
	$display("writeback: %h (expected: c0c2c4c6)", tb_writeback_register_data);

	$display(" ");
	$display("--- TEST 3: MISALIGNED WORD AND MISALIGNED HALFWORD WRITES ---");
	$display(" "); 

	tb_memory_address = 32'd18;
        tb_data_to_store = 32'hf0f1f2f3;
        tb_memory_access_code = 5'b1_1111;  
	$display(" ");
	@(negedge clk); $display("clock! Stored f0f1f2f3 @ 18");
	
	tb_memory_address = 32'd16;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  
	$display(" ");
	@(negedge clk); $display("clock! Started read @ 16");


	tb_memory_address = 32'd20;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  
	$display(" ");
	@(negedge clk); $display("clock! Finished read @ 16. Started read @ 20.");

	$display("writeback: %h (expected: xxxxf0f1)", tb_writeback_register_data);

	tb_memory_address = 32'd22;
        tb_data_to_store = 32'hd0d1EEEE;
        tb_memory_access_code = 5'b1_1100;  
	$display(" ");
	@(negedge clk); $display("clock! Finished read @ 20. Stored d0d1 @ 22");

	$display("writeback: %h (expected: f2f3xxxx)", tb_writeback_register_data);
/*
	tb_memory_address = 32'd25;
        tb_data_to_store = 32'hf0f1f2f3;
        tb_memory_access_code = 5'b1_1111;  
	$display(" ");
	@(negedge clk); $display("clock! Stored a0a1a2a3 @ 25");

	tb_memory_address = 32'd29;
        tb_data_to_store = 32'hd4d5EEEE;
        tb_memory_access_code = 5'b1_1100;  
	$display(" ");
	@(negedge clk); $display("clock! Stored d4d5 @ 29");

	tb_memory_address = 32'd24;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  
	$display(" ");
	@(negedge clk); $display("clock! Started read @ 24");

	tb_memory_address = 32'd28;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_1111;  
	$display(" ");
	@(negedge clk); $display("clock! Finished read @ 24. @ 24 Started read @ 28");
	$display("writeback: %h (expected: xxa0a1a2)", tb_writeback_register_data);

	tb_memory_address = 32'd28;
        tb_data_to_store = 32'hEEEEEEEE;
        tb_memory_access_code = 5'b0_0000;  
	$display(" ");
	@(negedge clk); $display("clock! Finished read @ 28. memory no-op");
	$display("writeback: %h (expected: a3d4d5xx)", tb_writeback_register_data);
*/

    end
endmodule