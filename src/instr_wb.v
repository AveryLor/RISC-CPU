module instr_wb(
	input clock,
	input reset,

	input [31:0] mem_wb_full_instruction,		// For VGA
	input [1:0] register_writeback_enable,
	input [2:0] writeback_register_encoding,	// From decode stage
	
	input [31:0] memory_writeback_data,			// From memory stage
	input [31:0] arithmetic_writeback_data,		// From execute stage
	input [31:0] move_writeback_data, 			// From decode stage (operand_value_2)
	input [2:0] writeback_data_select_hotcode,

	/* Signals to register file for writeback */
	output reg [1:0] reg_file_write_enable,
	output reg [2:0] reg_file_register_encoding,
	output reg [31:0] reg_file_writeback_data,
	
	output reg[31:0] wb_full_instruction		// For VGA
);

parameter [2:0] is_arithmetic = 3'b100,
				is_memory     = 3'b010,
				is_move       = 3'b001;


always@(posedge clock, posedge reset) begin
	if (reset) reg_file_write_enable <= 0; else begin
		case (writeback_data_select_hotcode)
			is_arithmetic: 	reg_file_writeback_data <= arithmetic_writeback_data;
			is_memory:		reg_file_writeback_data <= memory_writeback_data;
			is_move:		reg_file_writeback_data <= move_writeback_data;
			default:		reg_file_writeback_data <= 0; // unused
		endcase
		reg_file_write_enable <= register_writeback_enable;
		reg_file_register_encoding <= writeback_register_encoding;
		
		wb_full_instruction <= mem_wb_full_instruction; // for VGA
	end 
end


endmodule
