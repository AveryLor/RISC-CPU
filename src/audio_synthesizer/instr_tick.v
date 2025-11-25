module clk_div_100ms_simple (
    input wire CLOCK_50,    // 50 MHz input clock
    output reg clk_out_100ms // 10 Hz output clock
);

    // Counter limit for a 50% duty cycle toggle point: 2,499,999
    reg [24:0] counter = 0; 
							 
    always @(posedge CLOCK_50) begin
        if (counter == 10000000 / 8) begin
            counter <= 0;         
            clk_out_100ms <= ~clk_out_100ms; 
        end else begin
            counter <= counter + 1; 
        end
    end

endmodule