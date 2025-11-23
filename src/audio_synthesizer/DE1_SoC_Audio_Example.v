
module DE1_SoC_Audio_Example (
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
	LEDR
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

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;
wire [31:0] channel_audio_out;

wire clock;
wire reset;
wire [2:0] audio_opcode;
wire [1:0] channel_select;
wire [31:0] audio_data_to_write;


assign clock = ~KEY[1];
assign reset = ~KEY[0];
assign audio_opcode = SW[4:2];
assign channel_select = SW[1:0];
assign audio_data_to_write = (audio_opcode == 3'b011) ? {12'b0, SW[9:5], 15'b0} : 32'h3FFFFFFF;

// Internal Registers
assign left_channel_audio_out	= channel_audio_out;
assign right_channel_audio_out	= channel_audio_out;
assign write_audio_out			= audio_out_allowed;

// Wires for connecting the master and slave modules
wire [31:0] amplitude_pulse1, period_pulse1, amplitude_pulse2, period_pulse2;
wire [1:0]  duty_cycle_pulse1, duty_cycle_pulse2;
wire        enable_pulse1, enable_pulse2;
wire [31:0] amplitude_triangle, period_triangle;
wire        enable_triangle;
wire [31:0] amplitude_noise, period_noise;
wire        enable_noise;

assign LEDR[9] = enable_pulse1;
assign LEDR[8] = enable_pulse2;
assign LEDR[7] = enable_triangle;
assign LEDR[6] = enable_noise;

assign LEDR[4:2] = 3'b111;


// Instantiate the audio_synthesizer_master module
audio_synthesizer_master master (
  .audio_opcode(audio_opcode),
  .channel_select(channel_select),
  .audio_data_to_write(audio_data_to_write),
  .clock(clock),
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



Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
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