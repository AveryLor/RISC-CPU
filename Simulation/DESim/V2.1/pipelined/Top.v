module Top(SW, KEY, LEDR, HEX0, HEX1);
  input wire [9:0] SW;
  input wire [3:0] KEY;
  output wire [9:0] LEDR;
  output wire [6:0] HEX0;
  output wire [6:0] HEX1;

  control_unit CU (SW, LEDR, KEY[2:0], HEX0, HEX1);
endmodule
