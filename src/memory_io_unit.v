module memory_io_unit (
	/* Inputs are from the execute/memory pipeline register */
	input [31:0] data_to_store,	// only used when storing: regsiter => memory address
					// bytes may be unused if storing halfword & byte
	input [4:0] memory_access_code, // from the op-code: specifies load/store & data size
	input [31:0] memory_address,	// up to 2^18
	input clock,			// clock is only used for storing
	input prev_r,			// used for loading
	/* Output is sent DIRECTLY to writeback module, as a wire */
	output [31:0] writeback_register_data,	// only used when loading: memory address => register
	output [1:0] r
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

	// bram3 => addresses 4k + 0,
	// bram2 => addresses 4k + 1,
	// bram1 => addresses 4k + 2,
	// bram0 => addresses 4k + 3, k is an integer
	
	// Given a memory address, we need to find the right addresses in the BRAM
	// remainder from memory address divided by 4
	assign r = memory_address[1:0];
	assign B_address[3] = (r < 2'd1) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[2] = (r < 2'd2) ? (memory_address[17:2]) : (memory_address[17:2] + 1); 
	assign B_address[1] = (r < 2'd3) ? (memory_address[17:2]) : (memory_address[17:2] + 1);
	assign B_address[0] = (memory_address[17:2]); // r < 4 always


	// The tricky part: which BRAM corresponds to each byte of the data to write?
	// The assignments rotate based on the remainder
	assign B_data_to_write[3] =
	(r == 2'd0) ? data_to_store[31:24] :
	(r == 2'd1) ? data_to_store[ 7: 0] :
	(r == 2'd2) ? data_to_store[15: 8] :
	/*r == 2'd3*/ data_to_store[23:16];

	assign B_data_to_write[2] =
	(r == 2'd0) ? data_to_store[23:16] :
	(r == 2'd1) ? data_to_store[31:24] :
	(r == 2'd2) ? data_to_store[ 7: 0] :
	/*r == 2'd3*/ data_to_store[15: 8];

	assign B_data_to_write[1] =
	(r == 2'd0) ? data_to_store[15: 8] :
	(r == 2'd1) ? data_to_store[23:16] :
	(r == 2'd2) ? data_to_store[31:24] :
	/*r == 2'd3*/ data_to_store[ 7: 0];

	assign B_data_to_write[0] =
	(r == 2'd0) ? data_to_store[ 7: 0] :
	(r == 2'd1) ? data_to_store[15: 8] :
	(r == 2'd2) ? data_to_store[23:16] :
	/*r == 2'd3*/ data_to_store[31:24];

	// Similarly, the write enable will also rotate, and is only enabled if we are storing
	assign B_write_enable[3] = store & (
	(r == 2'd0) ? byte_enable[3] :
	(r == 2'd1) ? byte_enable[0] :
	(r == 2'd2) ? byte_enable[1] :
	/*r == 2'd3*/ byte_enable[2]
	);

	assign B_write_enable[2] = store & (
	(r == 2'd0) ? byte_enable[2] :
	(r == 2'd1) ? byte_enable[3] :
	(r == 2'd2) ? byte_enable[0] :
	/*r == 2'd3*/ byte_enable[1]
	);

	assign B_write_enable[1] = store & (
	(r == 2'd0) ? byte_enable[1] :
	(r == 2'd1) ? byte_enable[2] :
	(r == 2'd2) ? byte_enable[3] :
	/*r == 2'd3*/ byte_enable[0]
	);

	assign B_write_enable[0] = store & (
	(r == 2'd0) ? byte_enable[0] :
	(r == 2'd1) ? byte_enable[1] :
	(r == 2'd2) ? byte_enable[2] :
	/*r == 2'd3*/ byte_enable[3]
	);

	// The order of consecutive bytes we want to read from the BRAM also rotates
	assign writeback_register_data[31:24] =
    	(prev_r == 2'd0) ? B_data_to_read[3] :
	(prev_r == 2'd1) ? B_data_to_read[0] :
	(prev_r == 2'd2) ? B_data_to_read[1] :
	/*prev_r == 2'd3*/ B_data_to_read[2];
	
	assign writeback_register_data[23:16] =
	(prev_r == 2'd0) ? B_data_to_read[2] :
	(prev_r == 2'd1) ? B_data_to_read[3] :
	(prev_r == 2'd2) ? B_data_to_read[0] :
	/*prev_r == 2'd3*/ B_data_to_read[1];
	
	assign writeback_register_data[15:8] =
	(prev_r == 2'd0) ? B_data_to_read[1] :
	(prev_r == 2'd1) ? B_data_to_read[2] :
	(prev_r == 2'd2) ? B_data_to_read[3] :
	/*prev_r == 2'd3*/ B_data_to_read[0];
	
	assign writeback_register_data[7:0] =
    	(prev_r == 2'd0) ? B_data_to_read[0] :
    	(prev_r == 2'd1) ? B_data_to_read[1] :
    	(prev_r == 2'd2) ? B_data_to_read[2] :
	/*prev_r == 2'd3*/ B_data_to_read[3];

	/* TO-DO: MAKE MODULES TO ACCESS B-RAMs */
	

	// --- instantiate 4 byte-wide BRAMs (synchronous) ---

    bram0 bram0 (
        .clock(clock),
        .wren(B_write_enable[0]),
        .address(B_address[0]),
        .data(B_data_to_write[0]),
        .q(B_data_to_read[0])
    );

    bram1 bram1 (
        .clock(clock),
        .wren(B_write_enable[1]),
        .address(B_address[1]),
        .data(B_data_to_write[1]),
        .q(B_data_to_read[1])
    );
    
	 bram2 bram2 (
        .clock(clock),
        .wren(B_write_enable[2]),
        .address(B_address[2]),
        .data(B_data_to_write[2]),
        .q(B_data_to_read[2])
    );
    
	 bram3 bram3 (
        .clock(clock),
        .wren(B_write_enable[3]),
        .address(B_address[3]),
        .data(B_data_to_write[3]),
        .q(B_data_to_read[3])
    );


endmodule
