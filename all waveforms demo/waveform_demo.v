
module waveform_demo (
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

// Internal Registers

reg [18:0] delay_cnt;
wire [18:0] delay;

wire [31:0] c0, c1;

assign left_channel_audio_out	= c0 + c1;
assign right_channel_audio_out	= c0 + c1;
assign write_audio_out			= audio_out_allowed;
 
 // Instantiate waveform_generator module
 waveform_generator #(
.AMPLITUDE(32'h3FFFFFFF)
) waveform_generator_c0 (
	  .sample_request(1),
	  .period_cycles({9'b0,SW[9:0],13'b0}),
	  .CLOCK_50(CLOCK_50),
	  .reset(~KEY[0]),
	  .channel_audio_out(c0)
);

// Instantiate waveform_generator module
 waveform_generator #(
.AMPLITUDE(32'h3FFFFFFF)
) waveform_generator_c1 (
	  .sample_request(1),
	  .period_cycles(0),
	  .CLOCK_50(CLOCK_50),
	  .reset(~KEY[0]),
	  .channel_audio_out(c1)
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

module waveform_generator #(
	parameter [31:0] AMPLITUDE
) (
	input sample_request,
	input [31:0] period_cycles,
	input CLOCK_50,
	input reset,
	output reg [31:0] channel_audio_out
);
	reg [31:0] count_cycles;
	
	// Determine where we are along the waveform
	always@(posedge CLOCK_50) begin
		if (reset)
			count_cycles <= 0;
		else if (sample_request == 0) count_cycles <= count_cycles; // still waiting to sample this sample
		else begin // the current sample has been sampled, prepare the next sample
			if (count_cycles < period_cycles - 1) count_cycles <= count_cycles + 1;
			else count_cycles <= 0; // we reached the end of the period
		end // if sample_request
	end // always

	/* SQUARE WAVE *
	always@(posedge CLOCK_50) begin
		if (period_cycles == 0) channel_audio_out <= 0;
		else if (count_cycles < (period_cycles >> 2))
			channel_audio_out <= AMPLITUDE;
		else channel_audio_out <= -AMPLITUDE;
	end
	/**/
	
	
	/* SAWTOOTH WAVE *
	always@(posedge CLOCK_50) begin
		if (period_cycles == 0) channel_audio_out <= 0;
		else if (count_cycles < period_cycles - 1)
			channel_audio_out <= channel_audio_out + (2 * AMPLITUDE / period_cycles);
		else channel_audio_out <= -AMPLITUDE;
	end
	/**/
	
	/* TRIANGLE WAVE *
	wire [31:0] delta_amplitude; assign delta_amplitude = 4 * AMPLITUDE / period_cycles;
	always@(posedge CLOCK_50) begin
		if (period_cycles == 0) channel_audio_out <= 0;
		else if (count_cycles < period_cycles >> 1)
			channel_audio_out <= channel_audio_out + delta_amplitude;
		else if (count_cycles < period_cycles - 1)
			channel_audio_out <= channel_audio_out - delta_amplitude;
		else channel_audio_out <= -AMPLITUDE;
	end
	/**/
	
	/* NOISE */
	wire [31:0] random_channel_audio_out;
	always@(posedge CLOCK_50) begin
		if (period_cycles == 0) channel_audio_out <= AMPLITUDE;
		else if (count_cycles < period_cycles - 1)
			channel_audio_out <= channel_audio_out;
		else channel_audio_out <= random_channel_audio_out;
	end
	/**/
	rng rng3(.in(channel_audio_out[31:24]), .out(random_channel_audio_out[31:24]));
	rng rng2(.in(channel_audio_out[23:16]), .out(random_channel_audio_out[23:16]));
	rng rng1(.in(channel_audio_out[15: 8]), .out(random_channel_audio_out[15: 8]));
	rng rng0(.in(channel_audio_out[ 7: 0]), .out(random_channel_audio_out[ 7: 0]));
	
endmodule
	

module rng(
	input [7:0] in,
	output [7:0] out
);

assign out[7] = ~(in[7] ^ in[6]);
assign out[6] = in[1];
assign out[5] = in[3] ^ in[0];
assign out[4] = in[2];
assign out[3] = in[4];
assign out[2] = in[0];
assign out[1] = in[5] ^ in[4];
assign out[0] = in[6];

endmodule
