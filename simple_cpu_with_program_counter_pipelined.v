module simple_cpu_with_program_counter_pipelined(program, registers, clock, reset)
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

	/* Pipelining:
	On each clock cycle we:
		1. run the instruction that we "decoded" in register_select and operation 
		2. "decode" the next instruction to be run into register_select and operation
		3. increase program counter by 1

	At the clock cycle on a reset:
		We only do step 2: "decode" the next instruction (program counter is always 0 here)

	Note: the order of the steps does not matter; that is the point of pipelining
		(each step is simultaeous and occurs independently of other steps)
	*/

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
		begin // if not reset
			
			// 1. run instruction
			if (register_select != 2'b11)
			begin
				case (operation)
					1'b1: registers[register_select] <= registers[register_select] + 1;
					1'b0: registers[register_select] <= 32'd0;
				endcase
			end // if not a no-op

		end // else (not reset)

		// 2. "decode" the next instruction, regardless of whether reset is false or not.
		register_select <= program[program_counter][2:1] - 1;
		operation <= program[program_counter][0];

		// 3.
		program_counter <= program_counter + 1;
	end
endmodule


