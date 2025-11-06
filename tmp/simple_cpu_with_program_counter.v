module simple_cpu_with_program_counter(program, registers, clock, reset)
	input [2:0] program [15:0]; // 3bit opcodes, 16 instructions total
	/*
	the register is selected by the first two bits (01, 10, 11)
	where 00 indicates a no-op

	the operation is indicated by the last bit, where
		0 resets the selected register to 0, and
		1 increments the selected register by 1
	*/
	input clock;
	input reset;
	output reg [31:0] registers [2:0]; // 32bit registers, 3 registers total

	reg [3:0] program_counter;

	// for "decoding" instructions
	reg [1:0] register_select;
	reg operation;


	always@(posedge clock)
	begin
		if (reset)
		begin
			program_counter <= 4'd0;
			registers[0] <= 32'd0;
			registers[1] <= 32'd0;
			registers[2] <= 32'd0;
		end // if reset
		else
		begin
			// run instruction at program counter
			if (program[program_counter][2:1] != 2'b00)
			begin
				
				register_select = program[program_counter][2:1] - 1;
				operation = program[program_counter][0];

				case (operation)
					1'b1: registers[register_select] <= registers[register_select] + 1;
					1'b0: registers[register_select] <= 32'd0;
				endcase
			end // if not a no-op
			else
			begin
				register_select = 2'b00;
				operation = 1'b0;
			end // else no-op

			program_counter <= program_counter + 1;
		end // else (not reset)
	end
endmodule


