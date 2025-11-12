`timescale 1ns/1ps

module char_bitmap_tb;
    reg [7:0] digit;
    wire [63:0] pixelLine;

    char_bitmap dut (
        .digit(digit),
        .pixelLine(pixelLine)
    );

    integer i;

    task show_pixels;
        input [63:0] p;
        integer r, c;
        begin
            $display("Character %0d bitmap:", digit);
            for (r = 7; r >= 0; r = r - 1) begin
                for (c = 7; c >= 0; c = c - 1)
                    $write(p[8*r + c] ? "#" : ".");
                $write("\n");
            end
            $write("\n");
        end
    endtask

    initial begin
        $display("=== char_bitmap Test ===");
        digit = 8'd0; #5 show_pixels(pixelLine);
        digit = 8'd10; #5 show_pixels(pixelLine);
        digit = 8'd52; #5 show_pixels(pixelLine);
        $finish;
    end
endmodule
