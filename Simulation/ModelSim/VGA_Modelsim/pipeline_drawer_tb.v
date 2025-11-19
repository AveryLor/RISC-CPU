`timescale 1ns/1ps

module tb_pipeline_drawer;

    // Clock + Reset
    reg clock;
    reg resetn;

    // Inputs
    reg [31:0] IF_PC_VALUE;
    reg [31:0] ID_VAL_A;
    reg [31:0] EX_ALU_RESULT;
    reg [31:32] MEM_DATA_OUT;   // (typo in your module? making as 31:0)
    reg [31:0] WB_DATA_IN;

    // Outputs
    wire [9:0] pipeline_x;
    wire [8:0] pipeline_y;
    wire [8:0] pipeline_color;
    wire pipeline_done;

    // Clock gen
    initial begin
        clock = 0;
        forever #10 clock = ~clock;   // 50 MHz = 20ns period
    end

    // DUT
    pipeline_drawer DUT (
        .clock(clock),
        .resetn(resetn),

        .IF_PC_VALUE(IF_PC_VALUE),
        .ID_VAL_A(ID_VAL_A),
        .EX_ALU_RESULT(EX_ALU_RESULT),
        .MEM_DATA_OUT(MEM_DATA_OUT),
        .WB_DATA_IN(WB_DATA_IN),

        .pipeline_x(pipeline_x),
        .pipeline_y(pipeline_y),
        .pipeline_color(pipeline_color),
        .pipeline_done(pipeline_done)
    );

    // Test Procedure
    initial begin
        // Waveform dump for Modelsim
        $dumpfile("pipeline_drawer_tb.vcd");
        $dumpvars(0, tb_pipeline_drawer);

        // Initial inputs
        resetn = 0;
        IF_PC_VALUE    = 32'h0000_1000;
        ID_VAL_A       = 32'hABCD_1234;
        EX_ALU_RESULT  = 32'hDEAD_BEEF;
        MEM_DATA_OUT   = 32'hFACE_CAFE;
        WB_DATA_IN     = 32'h00FF_AA55;

        // Apply reset for a bit
        #100;
        resetn = 1;

        $display("Simulation started...");

        // Monitor important signals
        $monitor("t=%0t  X=%d  Y=%d  COLOR=%h  DONE=%b", 
                  $time, pipeline_x, pipeline_y, pipeline_color, pipeline_done);

        // Auto-stop when drawing finishes
        wait(pipeline_done == 1);
        $display("pipeline_done asserted, ending simulation.");
        #100;

        $finish;
    end

endmodule
