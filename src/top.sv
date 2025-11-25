module top(CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
	// Logical inputs
	input [9:0] SW;   	
	input CLOCK_50;	
	input [2:0] KEY; 
	// Logical outputs
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;
	output [9:0] LEDR; // LEDR used to display register values (first 4 bits of R1 and R2).
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	
	
	// wires for vga
	wire [31:0] registers [7:0];
	wire [31:0] if_instruction; 
	wire [31:0] id_instruction; 
	wire [31:0] ex_instruction; 
	wire [31:0] mem_instruction; 
	wire [31:0] wb_instruction; 
	wire [14:0] pc_for_vga; 
	wire [31:0] IR; 
	
	wire [255:0] memory_first_32_bytes;
	wire [31:0] ram [7:0];
	assign ram[0] = memory_first_32_bytes[255:224];
	assign ram[1] = memory_first_32_bytes[223:192];
	assign ram[2] = memory_first_32_bytes[191:160];
	assign ram[3] = memory_first_32_bytes[159:128];
	assign ram[4] = memory_first_32_bytes[127:96];
	assign ram[5] = memory_first_32_bytes[95:64];
	assign ram[6] = memory_first_32_bytes[63:32];
	assign ram[7] = memory_first_32_bytes[31:0];
	wire wb_valid_pulse; 
	

	control_unit cu (
		.SW(SW), 
		.LEDR(LEDR), 
		.KEY(KEY), 
		.HEX0(HEX0), 
		.HEX1(HEX1), 
		.HEX2(HEX2), 
		.HEX3(HEX3), 
		.HEX4(HEX4), 
		.HEX5(HEX5), 
		.register_file(registers),
		.if_instruction(if_instruction),
		.id_instruction(id_instruction),
		.ex_instruction(ex_instruction),
		.mem_instruction(mem_instruction),
		.wb_instruction(wb_instruction),
		.pc_for_vga(pc_for_vga),
		.IR(IR),
		.memory_first_32_bytes(memory_first_32_bytes),
		.wb_valid_pulse(wb_valid_pulse)
		
	); 
	
	vga_display vd (
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK),
    .register_file(registers),
    .if_instruction(if_instruction),
	 .id_instruction(id_instruction),
	 .ex_instruction(ex_instruction),
	 .mem_instruction(mem_instruction),
	 .wb_instruction(wb_instruction),
	 .pc_for_vga(pc_for_vga),
	 .IR(IR),
    .ram(ram), 
	 .wb_valid_pulse(wb_valid_pulse)
);
	

endmodule
