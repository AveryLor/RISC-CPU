// simple_sync_bram.v
// Generic single-port synchronous BRAM model for simulation

module simple_sync_bram #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8
)(
    input wire                  clk,
    input wire                  we,   // write enable
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout // when in dout... LOL
);

    // memory array
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;    // synchronous write
        dout <= mem[addr];        // synchronous read
    end

endmodule
