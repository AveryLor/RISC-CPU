`timescale 1ns/1ps

module one_char_counter_tb;
    reg clock, resetn;
    wire [5:0] counter;
    wire finishedCharacter;

    one_char_counter dut (
        .resetn(resetn),
        .clock(clock),
        .counter(counter),
        .finishedCharacter(finishedCharacter)
    );

    initial begin
        $display("=== one_char_counter Test ===");
        clock = 0;
        resetn = 0;
        #20 resetn = 1;

        // Run for a few hundred cycles to see multiple pulses
        #2000 $finish;
    end

    always #10 clock = ~clock;  // 50 MHz → 20 ns period

    always @(posedge clock)
        if (finishedCharacter)
            $display("[%0t] FinishedCharacter pulse, counter=%0d", $time, counter);

endmodule
