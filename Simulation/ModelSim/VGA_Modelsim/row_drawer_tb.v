`timescale 1ns/1ps

module row_drawer_tb;
    reg clock, resetn, finishedCharacter;
    wire [2:0] row_idx;
    wire [1:0] col_idx;

    char_index_fsm dut (
        .clock(clock),
        .resetn(resetn),
        .finishedCharacter(finishedCharacter),
        .col_idx(col_idx),
        .row_idx(row_idx)
    );

    initial begin
        $display("=== char_index_fsm Test ===");
        clock = 0;
        resetn = 0;
        finishedCharacter = 0;
        #25 resetn = 1;

        repeat (40) begin
            @(posedge clock);
            finishedCharacter = 1; // emulate character completion
            @(posedge clock);
            finishedCharacter = 0;
        end

        #50 $finish;
    end

    always #10 clock = ~clock;

    always @(posedge clock)
        $display("[%0t] row_idx=%0d col_idx=%0d", $time, row_idx, col_idx);
endmodule
