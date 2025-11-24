module instr_mem (
    input  wire        clk,
    input  wire        resetn,

    input  wire        ex_mem_regwrite,//
    input  wire [2:0]  ex_mem_reg_wb_enc,//
    input  wire [31:0] ex_mem_reg_arithmetic_result,//
    input  wire [31:0] ex_mem_reg_operand_val1,
    input  wire [31:0] ex_mem_reg_operand_val2,
    input  wire [3:0]  ex_mem_reg_data_select_hotcode,//
    input  wire [2:0]  ex_mem_reg_memory_access_code,

    output reg  [2:0]  mem_wb_reg_wb_enc,//
    output reg  [31:0] mem_wb_reg_arithmetic_result,//
    output reg         mem_wb_regwrite,//
    output wire [31:0] mem_wb_reg_memory_wb_data,
    output reg  [31:0] mem_wb_reg_operand_val2,//
    output reg  [3:0]  mem_wb_reg_data_select_hotcode,//

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
