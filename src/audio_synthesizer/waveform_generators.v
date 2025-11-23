/* PULSE */
module pulse_generator(
	input [31:0] amplitude,
	input [31:0] period_cycles,
	input [1:0] duty_cycle, // 1, 2, or 3 => 50%, 25%, 12.5%
	input CLOCK_50,
	input reset,
	output reg [31:0] channel_audio_out
);
reg [31:0] count_cycles;

// Determine where we are along the waveform
always@(posedge CLOCK_50) begin
	if (reset)
		count_cycles <= 0;
	else begin
		if (count_cycles < period_cycles - 1) count_cycles <= count_cycles + 1;
		else count_cycles <= 0;
	end
end

always@(posedge CLOCK_50) begin
	if (period_cycles == 0 | reset) channel_audio_out <= 0;
	else if (count_cycles < (period_cycles >> duty_cycle))
		channel_audio_out <= amplitude;
	else channel_audio_out <= -amplitude;
end

endmodule





/* TRIANGLE */
module triangle_generator(
	input [31:0] amplitude,
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
	else begin
		if (count_cycles < period_cycles - 1) count_cycles <= count_cycles + 1;
		else count_cycles <= 0;
	end
end

wire [31:0] delta_amplitude; assign delta_amplitude = 4 * amplitude / period_cycles;
always@(posedge CLOCK_50) begin
	if (period_cycles == 0 | reset) channel_audio_out <= 0;
	else if (count_cycles < period_cycles >> 1)
		channel_audio_out <= channel_audio_out + delta_amplitude;
	else if (count_cycles < period_cycles - 1)
		channel_audio_out <= channel_audio_out - delta_amplitude;
	else channel_audio_out <= -amplitude;
end

endmodule

module sawtooth_generator(
	input [31:0] amplitude,
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
	else begin
		if (count_cycles < period_cycles - 1) count_cycles <= count_cycles + 1;
		else count_cycles <= 0;
	end
end

wire [31:0] delta_amplitude; assign delta_amplitude = 2 * amplitude / period_cycles;
always@(posedge CLOCK_50) begin
	if (period_cycles == 0 | reset) channel_audio_out <= 0;
	else if (count_cycles < period_cycles - 1)
		channel_audio_out <= channel_audio_out + delta_amplitude;
	else channel_audio_out <= -amplitude;
end

endmodule

module noise_generator(
	input [31:0] amplitude,
	input [31:0] period_cycles,
	input CLOCK_50,
	input reset,
	output reg [31:0] channel_audio_out
);
reg [31:0] count_cycles;

// Determine where we are along the waveform
always@(posedge CLOCK_50) begin
	if (reset | period_cycles == 0)
		count_cycles <= 0;
	else begin
		if (count_cycles < period_cycles - 1) count_cycles <= count_cycles + 1;
		else count_cycles <= 0;
	end
end

wire [31:0] random_channel_audio_out;
always@(posedge CLOCK_50) begin
	if (period_cycles == 0) channel_audio_out <= amplitude;
	else if (count_cycles < period_cycles - 1)
		channel_audio_out <= channel_audio_out;
	else channel_audio_out <= random_channel_audio_out;
end

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