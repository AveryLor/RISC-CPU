
module audio_cpu (
	// Inputs
	CLOCK_50,
	KEY,
	SW,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK,
	LEDR,
	HEX5, HEX4, HEX3, HEX2, HEX1, HEX0
);


input				CLOCK_50;
input		[3:0]	KEY;
input		[9:0]	SW;

input				AUD_ADCDAT;

inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

output				AUD_XCK;
output				AUD_DACDAT;
output				FPGA_I2C_SCLK;
output	[9:0] LEDR;
output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

wire				audio_out_allowed;
wire				write_audio_out;
wire [31:0] channel_audio_out;

wire reset;
wire [2:0] audio_opcode;
wire [1:0] channel_select;
wire [31:0] audio_data_to_write;

wire manual_clock;
assign manual_clock = ~KEY[1];
assign reset = ~KEY[0];

// Internal Registers
assign write_audio_out			= audio_out_allowed;

// Wires for connecting the master and slave modules
wire [31:0] amplitude_pulse1, period_pulse1, amplitude_pulse2, period_pulse2;
wire [1:0]  duty_cycle_pulse1, duty_cycle_pulse2;
wire        enable_pulse1, enable_pulse2;
wire [31:0] amplitude_triangle, period_triangle;
wire        enable_triangle;
wire [31:0] amplitude_noise, period_noise;
wire        enable_noise;
/*
assign LEDR[9] = enable_pulse1;
assign LEDR[8] = enable_pulse2;
assign LEDR[7] = enable_triangle;
assign LEDR[6] = enable_noise;
*/
assign LEDR[0] = enable_pulse1;
assign LEDR[9:6] = pc[3:0];
assign LEDR[5:3] = audio_opcode;
assign LEDR[2:1] = channel_select;

hex_display_24bit hex_display_24bit(
    audio_data_to_write[31:8],
    HEX5, HEX4, HEX3, HEX2, HEX1, HEX0
);

reg [31:0] count;
reg [15:0] pc;
reg clock_pulse;


always@(posedge clock_pulse) begin
	if (reset) pc <= 0;
	else pc <= pc + 1;
end


wire [31:0] instruction;

//instr fetch
instr_rom instr_rom(
	.address(pc),
	.clock(clock_pulse),
	.data(0),
	.wren(0),
	.q(instruction)
);



//instr decode
instr_decode instr_decode (
    .clock(clock_pulse),
    .reset(reset),
    .stall(0),
    .if_id_reg(instruction),
    .register_select_1(),
    .register_select_2(),
    .selected_register_value_1(0),
    .selected_register_value_2(0),
    .alu_opcode(),
    .memory_access_code(),
    .audio_opcode(audio_opcode),
    .operand_value1(audio_data_to_write),
    .operand_value2(),
    .register_writeback_enable(),
    .writeback_register_encoding(),
    .writeback_data_select_hotcode(),
    .audio_channel_select(channel_select),
    .id_ex_instruction()
);



// Instantiate the audio_synthesizer_master module
audio_synthesizer_master master (
  .audio_opcode(audio_opcode),
  .channel_select(channel_select),
  .audio_data_to_write(audio_data_to_write),
  .clock(clock_pulse),
  .reset(reset),
  .amplitude_pulse1(amplitude_pulse1),
  .period_pulse1(period_pulse1),
  .duty_cycle_pulse1(duty_cycle_pulse1),
  .enable_pulse1(enable_pulse1),
  .amplitude_pulse2(amplitude_pulse2),
  .period_pulse2(period_pulse2),
  .duty_cycle_pulse2(duty_cycle_pulse2),
  .enable_pulse2(enable_pulse2),
  .amplitude_triangle(amplitude_triangle),
  .period_triangle(period_triangle),
  .enable_triangle(enable_triangle),
  .amplitude_noise(amplitude_noise),
  .period_noise(period_noise),
  .enable_noise(enable_noise)
);

// Instantiate the audio_synthesizer_slave module
audio_synthesizer_slave slave (
  .CLOCK_50(CLOCK_50),
  .reset(reset),
  .amplitude_pulse1(amplitude_pulse1),
  .period_pulse1(period_pulse1),
  .duty_cycle_pulse1(duty_cycle_pulse1),
  .enable_pulse1(enable_pulse1),
  .amplitude_pulse2(amplitude_pulse2),
  .period_pulse2(period_pulse2),
  .duty_cycle_pulse2(duty_cycle_pulse2),
  .enable_pulse2(enable_pulse2),
  .amplitude_triangle(amplitude_triangle),
  .period_triangle(period_triangle),
  .enable_triangle(enable_triangle),
  .amplitude_noise(amplitude_noise),
  .period_noise(period_noise),
  .enable_noise(enable_noise),
  .channel_audio_out(channel_audio_out)
);

clk_div_100ms_simple my_clock_generator (
    .CLOCK_50(CLOCK_50),
    .clk_out_100ms(clock_pulse)
);

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				(0),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(channel_audio_out),
	.right_channel_audio_out	(channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(0)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[0])
);

endmodule

module hex_display_24bit(
    input wire [23:0] value_in,
    output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0
);

    // Instantiate the 7-segment decoder module for each of the 6 hex digits
    // The digits are ordered from most significant (HEX5) to least significant (HEX0).
    hex_to_seven_seg_decoder decoder5 (
        .hex_in(value_in[23:20]),
        .seg_out(HEX5)
    );

    hex_to_seven_seg_decoder decoder4 (
        .hex_in(value_in[19:16]),
        .seg_out(HEX4)
    );

    hex_to_seven_seg_decoder decoder3 (
        .hex_in(value_in[15:12]),
        .seg_out(HEX3)
    );

    hex_to_seven_seg_decoder decoder2 (
        .hex_in(value_in[11:8]),
        .seg_out(HEX2)
    );

    hex_to_seven_seg_decoder decoder1 (
        .hex_in(value_in[7:4]),
        .seg_out(HEX1)
    );

    hex_to_seven_seg_decoder decoder0 (
        .hex_in(value_in[3:0]),
        .seg_out(HEX0)
    );

endmodule

module hex_to_seven_seg_decoder(
    input wire [3:0] hex_in,
    output reg [6:0] seg_out
);

    reg [6:0] temp;
    assign seg_out = temp;   // connect internal signal to output

    always @ (*) begin
        if (hex_in == 4'h0)
            temp = 7'b1000000;  // 0
        else if (hex_in == 4'h1)
            temp = 7'b1111001;  // 1
        else if (hex_in == 4'h2)
            temp = 7'b0100100;  // 2
        else if (hex_in == 4'h3)
            temp = 7'b0110000;  // 3
        else if (hex_in == 4'h4)
            temp = 7'b0011001;  // 4
        else if (hex_in == 4'h5)
            temp = 7'b0010010;  // 5
        else if (hex_in == 4'h6)
            temp = 7'b0000010;  // 6
        else if (hex_in == 4'h7)
            temp = 7'b1111000;  // 7
        else if (hex_in == 4'h8)
            temp = 7'b0000000;  // 8
        else if (hex_in == 4'h9)
            temp = 7'b0010000;  // 9
        else if (hex_in == 4'hA)
            temp = 7'b0001000;  // A
        else if (hex_in == 4'hB)
            temp = 7'b0000011;  // b
        else if (hex_in == 4'hC)
            temp = 7'b1000110;  // C
        else if (hex_in == 4'hD)
            temp = 7'b0100001;  // d
        else if (hex_in == 4'hE)
            temp = 7'b0000110;  // E
        else if (hex_in == 4'hF)
            temp = 7'b0001110;  // F
        else
            temp = 7'b1111111;  // display off (invalid input)
    end
endmodule
