module audio_synthesizer_slave(
    input         CLOCK_50,
    input         reset,

    input  [31:0] amplitude_pulse1,
    input  [31:0] period_pulse1,
    input  [1:0]  duty_cycle_pulse1,
    input         enable_pulse1,

    input  [31:0] amplitude_pulse2,
    input  [31:0] period_pulse2,
    input  [1:0]  duty_cycle_pulse2,
    input         enable_pulse2,

    input  [31:0] amplitude_triangle,
    input  [31:0] period_triangle,
    input         enable_triangle,

    input  [31:0] amplitude_noise,
    input  [31:0] period_noise,
    input         enable_noise,

    output [31:0] channel_audio_out
);

wire [31:0] pulse1_channel_audio_out;
wire [31:0] pulse2_channel_audio_out;
wire [31:0] triangle_channel_audio_out;
wire [31:0] noise_channel_audio_out;

// Sum the audio
assign channel_audio_out =
    (enable_pulse1   ? (pulse1_channel_audio_out   >> 2) : 32'd0) +
    (enable_pulse2   ? (pulse2_channel_audio_out   >> 2) : 32'd0) +
    (enable_triangle ? (triangle_channel_audio_out >> 2) : 32'd0) +
    (enable_noise    ? (noise_channel_audio_out    >> 2) : 32'd0);

// Instance: pulse1
pulse_generator pulse1 (
    .amplitude      (amplitude_pulse1),
    .period_cycles  (period_pulse1),
    .duty_cycle     (duty_cycle_pulse1),
    .CLOCK_50       (CLOCK_50),
    .reset          (reset),
    .channel_audio_out (pulse1_channel_audio_out)
);

// Instance: pulse2
pulse_generator pulse2 (
    .amplitude      (amplitude_pulse2),
    .period_cycles  (period_pulse2),
    .duty_cycle     (duty_cycle_pulse2),
    .CLOCK_50       (CLOCK_50),
    .reset          (reset),
    .channel_audio_out (pulse2_channel_audio_out)
);

// Instance: triangle
triangle_generator triangle (
    .amplitude      (amplitude_triangle),
    .period_cycles  (period_triangle),
    .CLOCK_50       (CLOCK_50),
    .reset          (reset),
    .channel_audio_out (triangle_channel_audio_out)
);

// Instance: noise
noise_generator noise (
    .amplitude      (amplitude_noise),
    .period_cycles  (period_noise),
    .CLOCK_50       (CLOCK_50),
    .reset          (reset),
    .channel_audio_out (noise_channel_audio_out)
);

endmodule
