module instr_mem (
    input  wire        clk,
    input  wire        resetn,

    input  wire [1:0]  ex_mem_regwrite,//
    input  wire [2:0]  ex_mem_reg_wb_enc,//
    input  wire [31:0] ex_mem_reg_arithmetic_result,//
    input  wire [31:0] ex_mem_reg_operand_val1,
    input  wire [31:0] ex_mem_reg_operand_val2,
    input  wire [2:0]  ex_mem_reg_data_select_hotcode,//
    input  wire [4:0]  ex_mem_reg_memory_access_code,

    output reg  [2:0]  mem_wb_reg_wb_enc,//
    output reg  [31:0] mem_wb_reg_arithmetic_result,//
    output reg  [1:0]  mem_wb_regwrite,//
    output wire [31:0] mem_wb_reg_memory_wb_data,
    output reg  [31:0] mem_wb_reg_operand_val2,//
    output reg  [2:0]  mem_wb_reg_data_select_hotcode,//

    input  wire [31:0] mem_instruct,//
    output reg  [31:0] wb_instruct,//
	output wire [255:0] memory_first_32_bytes
);

	// Signals propogating through
	always @(posedge clk or negedge resetn) begin
		if (~resetn) begin
			mem_wb_regwrite <= 0;
			mem_wb_reg_wb_enc <= 0;
			mem_wb_reg_data_select_hotcode <= 0;
			
			mem_wb_reg_arithmetic_result <= 0;
			mem_wb_reg_operand_val2 <= 0;
			
			wb_instruct <= 0;
		end 
		else begin
			mem_wb_regwrite <= ex_mem_regwrite;
			mem_wb_reg_wb_enc <= ex_mem_reg_wb_enc;
			mem_wb_reg_data_select_hotcode <= ex_mem_reg_data_select_hotcode;
			
			mem_wb_reg_arithmetic_result <= ex_mem_reg_arithmetic_result;
			mem_wb_reg_operand_val2 <= ex_mem_reg_operand_val2;
			
			wb_instruct <= mem_instruct;
		end
	end
	
	wire [1:0] r_D;
	reg [1:0] r_Q;
	always @(posedge clk) r_Q <= r_D; 
	memory_io_unit memory_io_unit (
		.data_to_store(ex_mem_reg_operand_val1),
		.memory_address(ex_mem_reg_operand_val2),
		.memory_access_code(ex_mem_reg_memory_access_code),	
		.clock(clk),		
		.prev_r(r_Q),	
		
		.writeback_register_data(mem_wb_reg_memory_wb_data),	
		.r(r_D)				
	);

	wire [1:0] r_D2; 
	reg [1:0] r_Q2;
	always @(posedge clk) r_Q2 <= r_D2; 
	memory_for_vga memory_for_vga (
		.data_to_store(ex_mem_reg_operand_val1),
		.memory_address(ex_mem_reg_operand_val2),
		.memory_access_code(ex_mem_reg_memory_access_code),
		.clock(clk),		
		.prev_r(r_Q2),
		
		.writeback_register_data(),
		.r(r_D2),
		.memory_first_32_bytes(memory_first_32_bytes)
	);
endmodule
	
module memory_io_unit (
	/* Inputs are from the execute/memory pipeline register */
	input [31:0] data_to_store,	// only used when storing: regsiter => memory address
					// bytes may be unused if storing halfword & byte
	input [4:0] memory_access_code, // from the op-code: specifies load/store & data size
	input [31:0] memory_address,	// up to 2^18
	input clock,			// clock is only used for storing
	input [1:0] prev_r,			// used for loading
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
	
module memory_for_vga (
	/* Inputs are from the execute/memory pipeline register */
	input [31:0] data_to_store,
	input [4:0] memory_access_code, 
	input [31:0] memory_address,
	input clock,			
	input [1:0] prev_r,	
	/* Outputs are sent to memory/writeback pipeline register, for memory instructions */
	output [31:0] writeback_register_data,	// Unused, don't connnect to anything
	output [1:0] r,
	output [255:0] memory_first_32_bytes // Array of first 32 bytes in memory
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

	/* NEW FOR VGA */

	// --- instantiate 4 byte-wide BRAMs (synchronous) ---
	wire [63:0] mem_4k_3;
	wire [63:0] mem_4k_2;
	wire [63:0] mem_4k_1;
	wire [63:0] mem_4k_0;
	
	assign memory_first_32_bytes = {
		mem_4k_0[7:0],   mem_4k_1[7:0],   mem_4k_2[7:0],   mem_4k_3[7:0],
		mem_4k_0[15:8],  mem_4k_1[15:8],  mem_4k_2[15:8],  mem_4k_3[15:8],
		mem_4k_0[23:16], mem_4k_1[23:16], mem_4k_2[23:16], mem_4k_3[23:16],
		mem_4k_0[31:24], mem_4k_1[31:24], mem_4k_2[31:24], mem_4k_3[31:24],
		mem_4k_0[39:32], mem_4k_1[39:32], mem_4k_2[39:32], mem_4k_3[39:32],
		mem_4k_0[47:40], mem_4k_1[47:40], mem_4k_2[47:40], mem_4k_3[47:40],
		mem_4k_0[55:48], mem_4k_1[55:48], mem_4k_2[55:48], mem_4k_3[55:48],
		mem_4k_0[63:56], mem_4k_1[63:56], mem_4k_2[63:56], mem_4k_3[63:56]
	};
	
    bram_8_bytes bram0 (
        .clk(~clock),
        .we(B_write_enable[0]),
        .addr(B_address[0]),
        .din(B_data_to_write[0]),
        .dout(B_data_to_read[0]),
		.memory_array(mem_4k_3)
    );

    bram_8_bytes bram1 (
        .clk(~clock),
        .we(B_write_enable[1]),
        .addr(B_address[1]),
        .din(B_data_to_write[1]),
        .dout(B_data_to_read[1]),
		.memory_array(mem_4k_2)
    );

    bram_8_bytes bram2 (
        .clk(~clock),
        .we(B_write_enable[2]),
        .addr(B_address[2]),
        .din(B_data_to_write[2]),
        .dout(B_data_to_read[2]),
		.memory_array(mem_4k_1)
    );

    bram_8_bytes bram3 (
        .clk(~clock),
        .we(B_write_enable[3]),
        .addr(B_address[3]),
        .din(B_data_to_write[3]),
        .dout(B_data_to_read[3]),
		.memory_array(mem_4k_0)
    );
	
	

endmodule

// simple_sync_bram.v
// Generic single-port synchronous BRAM model for simulation

module bram_8_bytes (
    input  wire        clk,
    input  wire        we,
    input  wire [15:0] addr,
    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    output wire [63:0] memory_array  
);

    // memory array (8 bytes)
    reg [7:0] mem [7:0];

    always @(posedge clk) begin
        if (we && (addr < 16'd8))
            mem[addr] <= din;
        dout <= mem[addr];
    end

    assign memory_array[7:0]    = mem[0];
    assign memory_array[15:8]   = mem[1];
    assign memory_array[23:16]  = mem[2];
    assign memory_array[31:24]  = mem[3];
    assign memory_array[39:32]  = mem[4];
    assign memory_array[47:40]  = mem[5];
    assign memory_array[55:48]  = mem[6];
    assign memory_array[63:56]  = mem[7];

endmodule
