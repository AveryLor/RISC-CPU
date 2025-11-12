/* THIS FILE IS FOR TESTING */

module bram_addresser_with_brams (
	/* Inputs are from the execute/memory pipeline register */
	input [31:0] data_to_store,	// only used when storing: regsiter => memory address
					// bytes may be unused if storing halfword & byte
	input [4:0] memory_access_code, // from the op-code: specifies load/store & data size
	input [31:0] memory_address,	// up to 2^18
	input CLOCK_50,			// clock is only used for storing
	
	/* Outputs are sent to memory/writeback pipeline register, for memory instructions */
	output [31:0] writeback_register_data	// only used when loading: memory address => register
);
	
	wire store; // 1: storing in memory, 0: loading from memory
	assign store = memory_access_code[4];
	wire [3:0] byte_enable; // determines which 4 bytes will be written or stored
	assign byte_enable = memory_access_code[3:0];

	// Each B-RAM uses a 16 bit address and loads/stores bytes
	wire [15:0] B_address [3:0];	// 4 addresses for loading/storing up to 4 bytes
	wire [7:0] B_data_to_write [3:0];
	wire [7:0] B_data_to_read [3:0];
	wire [3:0] B_write_enable;
	
	// Given a memory address, we need to find the right addresses in the BRAM
	wire [1:0] r; // remainder from memory address divided by 4
	assign r = memory_address[1:0];
	assign B_address[3] = (memory_address[17:2]); // r < 4 always
	assign B_address[2] = (r < 2'd3) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[1] = (r < 2'd2) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[0] = (r < 2'd1) ? (memory_address[17:2]) : (memory_address[17:2] + 1);

	// The tricky part: which BRAM corresponds to each byte of the data to write?
	// The assignments rotate based on the remainder
	assign B_data_to_write[3] =
	(r == 2'd0) ? data_to_store[31:24] :
	(r == 2'd1) ? data_to_store[23:16] :
	(r == 2'd2) ? data_to_store[15: 8] :
	/*r == 2'd3*/ data_to_store[ 7: 0];

	assign B_data_to_write[2] =
	(r == 2'd0) ? data_to_store[23:16] :
	(r == 2'd1) ? data_to_store[15: 8] :
	(r == 2'd2) ? data_to_store[ 7: 0] :
	/*r == 2'd3*/ data_to_store[31:24];

	assign B_data_to_write[1] =
	(r == 2'd0) ? data_to_store[15: 8] :
	(r == 2'd1) ? data_to_store[ 7: 0] :
	(r == 2'd2) ? data_to_store[31:24] :
	/*r == 2'd3*/ data_to_store[23:16];

	assign B_data_to_write[0] =
	(r == 2'd0) ? data_to_store[ 7: 0] :
	(r == 2'd1) ? data_to_store[31:24] :
	(r == 2'd2) ? data_to_store[23:16] :
	/*r == 2'd3*/ data_to_store[15: 8];

	// Similarly, the write enable will also rotate, and is only enabled if we are storing
	assign B_write_enable[3] = store & (
	(r == 2'd0) ? byte_enable[3] :
	(r == 2'd1) ? byte_enable[2] :
	(r == 2'd2) ? byte_enable[1] :
	/*r == 2'd3*/ byte_enable[0]
	);

	assign B_write_enable[2] = store & (
	(r == 2'd0) ? byte_enable[2] :
	(r == 2'd1) ? byte_enable[1] :
	(r == 2'd2) ? byte_enable[0] :
	/*r == 2'd3*/ byte_enable[3]
	);

	assign B_write_enable[1] = store & (
	(r == 2'd0) ? byte_enable[1] :
	(r == 2'd1) ? byte_enable[0] :
	(r == 2'd2) ? byte_enable[3] :
	/*r == 2'd3*/ byte_enable[2]
	);

	assign B_write_enable[0] = store & (
	(r == 2'd0) ? byte_enable[0] :
	(r == 2'd1) ? byte_enable[3] :
	(r == 2'd2) ? byte_enable[2] :
	/*r == 2'd3*/ byte_enable[1]
	);

	// The order of consecutive bytes we want to read from the BRAM also rotates
	assign writeback_register_data[31:24] =
    	(r == 2'd0) ? B_data_to_read[3] :
	(r == 2'd1) ? B_data_to_read[0] :
	(r == 2'd2) ? B_data_to_read[1] :
	/*r == 2'd3*/ B_data_to_read[2];
	
	assign writeback_register_data[23:16] =
	(r == 2'd0) ? B_data_to_read[2] :
	(r == 2'd1) ? B_data_to_read[3] :
	(r == 2'd2) ? B_data_to_read[0] :
	/*r == 2'd3*/ B_data_to_read[1];
	
	assign writeback_register_data[15:8] =
	(r == 2'd0) ? B_data_to_read[1] :
	(r == 2'd1) ? B_data_to_read[2] :
	(r == 2'd2) ? B_data_to_read[3] :
	/*r == 2'd3*/ B_data_to_read[0];
	
	assign writeback_register_data[7:0] =
    	(r == 2'd0) ? B_data_to_read[0] :
    	(r == 2'd1) ? B_data_to_read[1] :
    	(r == 2'd2) ? B_data_to_read[2] :
	/*r == 2'd3*/ B_data_to_read[3];

	/* TO-DO: MAKE MODULES TO ACCESS B-RAMs */
	
	/* START OF GENERATED CODE */
	// --- instantiate 4 byte-wide BRAMs (synchronous) ---

    simple_sync_bram #(.ADDR_WIDTH(16), .DATA_WIDTH(8)) bram0 (
        .clk(~CLOCK_50),
        .we(B_write_enable[0]),
        .addr(B_address[0]),
        .din(B_data_to_write[0]),
        .dout(B_data_to_read[0])
    );

    simple_sync_bram #(.ADDR_WIDTH(16), .DATA_WIDTH(8)) bram1 (
        .clk(~CLOCK_50),
        .we(B_write_enable[1]),
        .addr(B_address[1]),
        .din(B_data_to_write[1]),
        .dout(B_data_to_read[1])
    );

    simple_sync_bram #(.ADDR_WIDTH(16), .DATA_WIDTH(8)) bram2 (
        .clk(~CLOCK_50),
        .we(B_write_enable[2]),
        .addr(B_address[2]),
        .din(B_data_to_write[2]),
        .dout(B_data_to_read[2])
    );

    simple_sync_bram #(.ADDR_WIDTH(16), .DATA_WIDTH(8)) bram3 (
        .clk(~CLOCK_50),
        .we(B_write_enable[3]),
        .addr(B_address[3]),
        .din(B_data_to_write[3]),
        .dout(B_data_to_read[3])
    );
	/* END OF GENERATED CODE */

endmodule