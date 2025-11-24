module instr_wb(
	input clk,
	input resetn,

	input [31:0] wb_instruct,		// For VGA
	input [1:0] mem_wb_regwrite,
	input [2:0] mem_wb_reg_wb_enc,	// From decode stage
	
	input [31:0] mem_wb_reg_memory_wb_data,			// From memory stage
	input [31:0] mem_wb_reg_arithmetic_result,		// From execute stage
	input [31:0] mem_wb_reg_operand_val2, 			// From decode stage (operand_value_2)
	input [2:0] mem_wb_reg_data_select_hotcode,

	/* Signals to register file for writeback */
	output reg [1:0] reg_file_write_enable,
	output reg [2:0] reg_file_register_encoding,
	output reg [31:0] reg_file_writeback_data,
	
	output reg [31:0] completed_instruction		// For VGA
);

parameter [2:0] is_arithmetic = 3'b100,
				is_memory     = 3'b010,
				is_move       = 3'b001;


always@(posedge clk, negedge resetn) begin
	if (resetn) reg_file_write_enable <= 0; else begin
		case (mem_wb_reg_data_select_hotcode)
			is_arithmetic: 	reg_file_writeback_data <= mem_wb_reg_arithmetic_result;
			is_memory:		reg_file_writeback_data <= mem_wb_reg_memory_wb_data;
			is_move:		reg_file_writeback_data <= mem_wb_reg_operand_val2;
			default:		reg_file_writeback_data <= 0; // unused
		endcase
		reg_file_write_enable <= mem_wb_regwrite;
		reg_file_register_encoding <= mem_wb_reg_wb_enc;
		
		completed_instruction <= wb_instruct; // for VGA
	end 
end
endmodule
