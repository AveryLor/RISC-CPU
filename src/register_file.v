
module register_file (CLOCK_50, reset_n, write_enable, RA1, RA2, WA, RD1, RD2);
    input CLOCK_50; 
    input reset_n; // Async reset for the register files
    input write_enable;
    input [2:0] RA1; 
    input [2:0] RA2; 
    input [2:0] WA; // Write address, each register is defined by 3 bits
    input [31:0] WD; // Data that needs to be changed
    output [31:0] RD1; 
    output [31:0] RD2; 

    // Declaration of the register bank: 8 registers, each 32 bits wide.
    reg [31:0] registers [7:0];

    initial begin
        registers[0] = 0;
        registers[1] = 32'hAAAA0001;
        registers[2] = 32'hAAAA0002;
        registers[3] = 32'hAAAA0003;
        registers[4] = 32'hAAAA0004;
        registers[5] = 32'hAAAA0005;
        registers[6] = 32'hAAAA0006;
        registers[7] = 32'hAAAA0007;
    end
    // This block handles writing data into the registers on the positive clock edge
    // always @(posedge CLK) begin
    //     if (!RST_N) begin // Reset all 8 registers to zero asynchronously
    //         integer i;
    //         for (i = 0; i < 8; i = i + 1) begin
    //             registers[i] <= 32'h00000000;
    //         end
    //     end else if (WE) begin // Only write if Write Enable is active (WE=1)
    //         if (WA != 3'b000) begin // AND the destination register is not R0 (WA != 3'b000)
    //             registers[WA] <= WD; // Feed in the correct address to change
    //         end
    //         // R0 is not written to, as it must always read 0.
    //     end
    // end

    // If the Read Address 1 (RA1) is 0 (R0), output 0. Otherwise, output the content
    assign RD1 = (RA1 == 3'b000) ? 32'h00000000 : registers[RA1];

    // Read Port 2: RD2
    assign RD2 = (RA2 == 3'b000) ? 32'h00000000 : registers[RA2];

endmodule