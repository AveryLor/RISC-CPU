module audio_synthesizer_master(
    input  [2:0]  audio_opcode,
    input  [1:0]  channel_select,
    input  [31:0] audio_data_to_write,
    input         clock,
    input         reset,

    output reg [31:0] amplitude_pulse1,
    output reg [31:0] period_pulse1,
    output reg [1:0]  duty_cycle_pulse1,
    output reg        enable_pulse1,

    output reg [31:0] amplitude_pulse2,
    output reg [31:0] period_pulse2,
    output reg [1:0]  duty_cycle_pulse2,
    output reg        enable_pulse2,

    output reg [31:0] amplitude_triangle,
    output reg [31:0] period_triangle,
    output reg        enable_triangle,

    output reg [31:0] amplitude_noise,
    output reg [31:0] period_noise,
    output reg        enable_noise
);

// ============================================================================
// AUDIO OPCODE + CHANNEL SELECT CONTROL TABLE
// ============================================================================
//
// audio_opcode[2:0] | Meaning
// ------------------+---------------------------------------------------------
//    3'b000         | No-Op  (ignore audio_data_to_write)
//    3'b001         | Disable channel (enable_x <= 0)
//    3'b010         | Enable channel  (enable_x <= 1)
//    3'b011         | Write Period      (period_x <= audio_data_to_write)
//    3'b100         | Write Amplitude   (amplitude_x <= audio_data_to_write)
//
// Duty Cycle Control (Pulse channels only)
//    3'b101         | Set duty cycle = 50%
//    3'b110         | Set duty cycle = 25%
//    3'b111         | Set duty cycle = 12.5%
//
// ---------------------------------------------------------------------------
//
// channel_select[1:0] | Channel Selected
// --------------------+------------------------------------------------------
//      2'b00          | Pulse Channel 1
//      2'b01          | Pulse Channel 2
//      2'b10          | Triangle Wave Channel  (duty-cycle ignored)
//      2'b11          | Noise Channel         (duty-cycle ignored)
//
// ============================================================================
//
// Notes:
// • Duty-cycle commands only affect pulse channels (00 and 01).
// • For triangle or noise channels, duty-cycle commands do nothing.
// ============================================================================

always @(posedge clock or posedge reset) begin
    if (reset) begin
        amplitude_pulse1      <= 32'd0;
        period_pulse1         <= 32'd0;
        duty_cycle_pulse1     <= 2'd0;
        enable_pulse1         <= 1'b0;

        amplitude_pulse2      <= 32'd0;
        period_pulse2         <= 32'd0;
        duty_cycle_pulse2     <= 2'd0;
        enable_pulse2         <= 1'b0;

        amplitude_triangle    <= 32'd0;
        period_triangle       <= 32'd0;
        enable_triangle       <= 1'b0;

        amplitude_noise       <= 32'd0;
        period_noise          <= 32'd0;
        enable_noise          <= 1'b0;
    end else begin
        case (audio_opcode)
            3'b001: begin // disable
                case (channel_select)
                    2'b00: enable_pulse1   <= 1'b0;
                    2'b01: enable_pulse2   <= 1'b0;
                    2'b10: enable_triangle <= 1'b0;
                    2'b11: enable_noise    <= 1'b0;
                endcase
            end

            3'b010: begin // enable
                case (channel_select)
                    2'b00: enable_pulse1   <= 1'b1;
                    2'b01: enable_pulse2   <= 1'b1;
                    2'b10: enable_triangle <= 1'b1;
                    2'b11: enable_noise    <= 1'b1;
                endcase
            end

            3'b011: begin // period
                case (channel_select)
                    2'b00: period_pulse1   <= audio_data_to_write;
                    2'b01: period_pulse2   <= audio_data_to_write;
                    2'b10: period_triangle <= audio_data_to_write;
                    2'b11: period_noise    <= audio_data_to_write;
                endcase
            end

            3'b100: begin // amplitude
                case (channel_select)
                    2'b00: amplitude_pulse1   <= audio_data_to_write;
                    2'b01: amplitude_pulse2   <= audio_data_to_write;
                    2'b10: amplitude_triangle <= audio_data_to_write;
                    2'b11: amplitude_noise    <= audio_data_to_write;
                endcase
            end

            // Duty-cycle explicit opcodes:
            3'b101: begin // set duty = 50%
                case (channel_select)
                    2'b00: duty_cycle_pulse1 <= 2'b01; // 50%
                    2'b01: duty_cycle_pulse2 <= 2'b01; // 50%
                    default: ; // triangle/noise ignored
                endcase
            end

            3'b110: begin // set duty = 25%
                case (channel_select)
                    2'b00: duty_cycle_pulse1 <= 2'b10; // 25%
                    2'b01: duty_cycle_pulse2 <= 2'b10; // 25%
                    default: ;
                endcase
            end

            3'b111: begin // set duty = 12.5%
                case (channel_select)
                    2'b00: duty_cycle_pulse1 <= 2'b11; // 12.5%
                    2'b01: duty_cycle_pulse2 <= 2'b11; // 12.5%
                    default: ;
                endcase
            end

            3'b000: begin
                // No-op
            end

            default: begin
                // never reached
            end
        endcase
    end
end

endmodule
