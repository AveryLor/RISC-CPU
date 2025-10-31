`default_nettype none

/*  This code animates two colored objects that move up/down on the display. The objects 
 *  "bounce" off the top and bottom of the display and reverse directions. To run the demo
 *  first press/release KEY[0] to reset the circuit. Select one object by making SW[9] = 0.
 *  Then, press/release KEY[1] to set the object's color according to switches SW[8:0] 
 *  (9-bit color), or SW[5:0] (6-bit color), or SW[2:0] (3-bit color). Press KEY[2] to increase
 *  the speed of the selected object, or press KEY[3] to decrease the speed. Set SW[9] = 1
 *  to select the other object, then use KEY[1] to KEY[3] to set its color and/or speed.
 *
 *  A background image (MIF) is displayed on the VGA display.
*/

module vga_demo(CLOCK_50, SW, KEY, LEDR, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
	
    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 10;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 9;

    // state codes for FSM that choses which object to draw at a given time
    parameter A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;

	input wire CLOCK_50;	
	input wire [9:0] SW;
	input wire [3:0] KEY;
	output wire [9:0] LEDR;
	output wire [7:0] VGA_R;
	output wire [7:0] VGA_G;
	output wire [7:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire VGA_BLANK_N;
	output wire VGA_SYNC_N;
	output wire VGA_CLK;	

	wire [nX-1:0] O1_x, O2_x;
	wire [nY-1:0] O1_y, O2_y;
	wire [8:0] O1_color, O2_color;
    wire O1_write, O2_write;
	reg [nX-1:0] MUX_x;
	reg [nY-1:0] MUX_y;
	reg [8:0] MUX_color;
    reg MUX_write;
    wire req1, req2;
    reg gnt1, gnt2;
    reg [1:0] y_Q, Y_D;
	
    wire Resetn, faster, slower, set_color;

    assign Resetn = KEY[0];
    sync S1 (~KEY[1], Resetn, CLOCK_50, set_color);
    sync S2 (~KEY[2], Resetn, CLOCK_50, faster);
    sync S3 (~KEY[3], Resetn, CLOCK_50, slower);

    // Agorithm: the FSM below uses an arbitration scheme to draw one object at a time, either
    // object 1 or object 2. Each object makes a request when it wants to be drawn, and then 
    // receives a grant when it is selected for display. The object releases its request when 
    // its drawing cycle is complete. A drawing cycle means that the object is erased from where
    // it was drawn "last time" and has moved to its new location and been drawn again.
    always @ (*)
        case (y_Q)
            A:  if (req1) Y_D = B;          // see if object 1 wants to be drawn
                else if (req2) Y_D = C;     // see if object 2 wants to be drawn
                else Y_D = A;
            B:  if (req1) Y_D = B;          // wait for object 1 drawing cycle
                else Y_D = A;
            C:  if (req2) Y_D = C;          // wait for object 2 drawing cycle
                else Y_D = A;
            default:  Y_D = A;
        endcase

    // FSM outputs to drive the VGA display from either object 1 or object 2
    always @ (*)
    begin
        // default assignments
        gnt1 = 1'b0; gnt2 = 1'b0; MUX_write = 1'b0;
        MUX_x = O1_x; MUX_y = O1_y; MUX_color = O1_color;
        case (y_Q)
            A:  ;
            B:  begin gnt1 = 1'b1; MUX_write = O1_write; 
                      MUX_x = O1_x; MUX_y = O1_y; MUX_color = O1_color; end
            C:  begin gnt2 = 1'b1; MUX_write = O2_write; 
                      MUX_x = O2_x; MUX_y = O2_y; MUX_color = O2_color; end
        endcase
    end

    // FSM state flip-flops
    always @(posedge CLOCK_50)
        if (Resetn == 0)   // wait until ready
            y_Q <= A;
        else
            y_Q <= Y_D;

    // instantiate object 1
    object O1 (Resetn, CLOCK_50, gnt1, !SW[9], set_color, SW[8:0], faster, slower, req1, 
               O1_x, O1_y, O1_color, O1_write);
        defparam O1.nX = nX;
        defparam O1.nY = nY;

    // instantiate object 2
    object O2 (Resetn, CLOCK_50, gnt2, SW[9], set_color, SW[8:0], faster, slower, req2, 
               O2_x, O2_y, O2_color, O2_write);
        defparam O2.nX = nX;
        defparam O2.nY = nY;
        defparam O2.X_INIT = 10'd159;
        defparam O2.Y_INIT = 9'd119;

    // connect to VGA controller
    vga_adapter VGA (
		.resetn(KEY[0]),
		.clock(CLOCK_50),
		.color(MUX_color),
		.x(MUX_x),
		.y(MUX_y),
		.write(MUX_write),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
        // choose background image 
		defparam VGA.BACKGROUND_IMAGE = "./MIF/checkers_640_9.mif";

    assign LEDR[9:0] = 10'b0;

endmodule

// syncronizer, implemented as two FFs in series
module sync(D, Resetn, Clock, Q);
    input wire D;
    input wire Resetn, Clock;
    output reg Q;

    reg Qi; // internal node

    always @(posedge Clock)
        if (Resetn == 0) begin
            Qi <= 1'b0;
            Q <= 1'b0;
        end
        else begin
            Qi <= D;
            Q <= Qi;
        end
endmodule

// n-bit register with sync reset and enable
module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (Resetn == 0)
            Q <= 'b0;
        else if (E)
            Q <= R;
endmodule

// toggle flip-flop with reset
module ToggleFF(T, Resetn, Clock, Q);
    input wire T, Resetn, Clock;
    output reg Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 1'b0;
        else if (T)
            Q <= ~Q;
endmodule

// up/down counter with reset, enable, and load controls
module UpDn_count (R, Clock, Resetn, E, L, UpDn, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Clock, Resetn, E, L, UpDn;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 0;
        else if (L == 1)
            Q <= R;
        else if (E)
            if (UpDn == 1)
                Q <= Q + 1'b1;
            else
                Q <= Q - 1'b1;
endmodule

// counter
module Up_count (Clock, Resetn, Q);
    parameter n = 8;
    input wire Clock, Resetn;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 'b0;
        else 
            Q <= Q + 1'b1;
endmodule

// implements a moving colored object
module object (Resetn, Clock, gnt, sel, set_color, new_color, faster, slower, req,  
               VGA_x, VGA_y, VGA_color, VGA_write);

    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 10;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 9;

    parameter XSCREEN = 640;
    parameter YSCREEN = 480;

    parameter XDIM = XSCREEN>>4, YDIM = 2; // object's width and height

    // default initial location of the object 
    parameter X_INIT = 10'd439;
    parameter Y_INIT = 9'd239;

    parameter KK = 24; // controls animation speed (use 16 for DESim, 5 for ModelSim)
    parameter MM = 8;  // animation speed up/down mask (use 6 for DESim, 2 for ModelSim)

    // state codes
    parameter A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011,
              E = 4'b0100, F = 4'b0101, G = 4'b0110, H = 4'b0111,
              I = 4'b1000, J = 4'b1001, K = 4'b1010, L = 4'b1011;

    input wire Resetn, Clock;
    input wire gnt;  // set to 1 when this object is selected for VGA display
    input wire sel;  // when 1, this object's color and speed can be changed
    input wire set_color;        // new color
    input wire faster, slower;   // used to increase/decrease the object's speed
    input wire [8:0] new_color;  // used when setting the color
    output reg req; // object sets this request to 1 when it wants to be displayed
	output wire [nX-1:0] VGA_x;  // pixel x coordinate output
	output wire [nY-1:0] VGA_y;  // pixel y coordinate ouput
	output wire [8:0] VGA_color; // pixel color output
    output wire VGA_write;       // control output to write a pixel

	wire [nX-1:0] X, XC, X0;    // used to traverse the object's width
	wire [nY-1:0] Y, YC, Y0;    // used to traverse the object's height
	wire [8:0] the_color, color;    // used when setting the color
    wire [KK-1:0] slow;         // used to synchronize the object's speed using a counter
    reg Lx, Ly, Ey, Lxc, Lyc, Exc, Eyc; // load and enable signals for the object's 
                                        // location (x,y) and the counters that traverse 
                                        // the object's pixels (XC, YC)
    wire sync, Ydir;    // sync is for the slow counter, Ydir is the direction of moving
    reg erase, Tdir;    // erase is used to erase the object. TDir is used to set Ydir
    reg [3:0] y_Q, Y_D; // FSM for controlling drawing/erasing of the object
    reg write;          // used to write to a pixel

    // mask logic (speed control)
    reg [2:0] ys_Q, Ys_D;   // FSM to control the object's speed
    reg sll, srl;           // shift the mask left or right
    reg [MM-1:0] mask;      // the mask (see FSM description below)

    assign X0 = X_INIT;
    assign Y0 = Y_INIT;
    parameter ALT = 9'b0;   // erasure color
    
    UpDn_count U2 (X0, Clock, Resetn, 1'b0, Lx, 1'b0, X);    // object's column location
        defparam U2.n = nX;

    UpDn_count U1 (Y0, Clock, Resetn, Ey, Ly, Ydir, Y);      // object's row location
        defparam U1.n = nY;

    // set default color to white (1...11)
    assign the_color = color == 9'b0 ? 9'b111111111 : new_color;
    regn UC (the_color, Resetn, (sel && set_color) | (color == 9'b0), Clock, color); 
        defparam UC.n = 9;

    UpDn_count U3 ({nX{1'd0}}, Clock, Resetn, Exc, Lxc, 1'b1, XC); // object column counter
        defparam U3.n = nX;
    UpDn_count U4 ({nY{1'd0}}, Clock, Resetn, Eyc, Lyc, 1'b1, YC); // object row counter
        defparam U4.n = nY;

    Up_count U6 (Clock, Resetn, slow);  // counter to control the speed of moving
        defparam U6.n = KK;

    // wait for the slow counter to contain all 1's. But use the mask bits to avoid waiting
    // for the most-significant counter bits when desired. This mask mechanism has the effect
    // of increasing/descreasing the speed at which the object moves
    assign sync = ((slow | (mask << KK-MM)) == {KK{1'b1}});

    ToggleFF U7 (Tdir, Resetn, Clock, Ydir);        // used to reverse directions

    assign VGA_x = X + XC;                          // pixel x coordinate
    assign VGA_y = Y + YC;                          // pixel y coordinate
    assign VGA_color = erase == 0 ? color : ALT;    // pixel color to draw/erase
    assign VGA_write = write;                       // pixel write control

    // FSM Algorithm:
    // 1. draw object
    // 2. wait for object's delay time
    // 3. request to draw, wait for grant
    // 4. erase object (maintain request)
    // 5. move object, check for boundary conditions (maintain request)
    // 6. draw object (maintain request)
    // 7. release request, goto 2.

    always @ (*)
        case (y_Q)
            A:  Y_D = B;                        // initialize counters, registers

            B:  if (XC != XDIM-1) Y_D = B;      // initial draw, done once
                else Y_D = C;
            C:  if (YC != YDIM-1) Y_D = B;
                else Y_D = D;

            D:  if (!sync) Y_D = D;             // wait for object's delay time
                else Y_D = E;
            E:  if (!gnt) Y_D = E;              // wait for VGA grant
                else Y_D = F;

            F:  if (XC != XDIM-1) Y_D = F;      // erase object
                else Y_D = G;
            G:  if (YC != YDIM-1) Y_D = F;
                else Y_D = H;

            H:  Y_D = I;                        // move the object
            I:  Y_D = J;

            J:  if (XC != XDIM-1) Y_D = J;      // draw the object
                else Y_D = K;
            K:  if (YC != YDIM-1) Y_D = J;
                else Y_D = L;
            L:  Y_D = D;
            default: Y_D = A;
        endcase

    always @ (*)
    begin
        // default assignments
        Lx = 1'b0; Ly = 1'b0; Lxc = 1'b0; Lyc = 1'b0; Exc = 1'b0; Eyc = 1'b0; 
        erase = 1'b0; write = 1'b0; Ey = 1'b0; Tdir = 1'b0; req = 1'b0;
        case (y_Q)
            A:  begin Lx = 1'b1; Ly = 1'b1; Lxc = 1'b1; Lyc = 1'b1; end // initialization

            B:  begin Exc = 1'b1; write = 1'b1; end   // color a pixel, incr XC
            C:  begin Lxc = 1'b1; Eyc = 1'b1; end     // reload XC, incr YC

            D:  Lyc = 1'b1; // reload YC
            E:  req = 1'b1; // request a drawing cycle

            // erase the object
            F:  begin req = 1'b1; Exc = 1'b1; erase = 1'b1; write = 1'b1; end
            G:  begin req = 1'b1; Lxc = 1'b1; Eyc = 1'b1; end

            H:  begin req = 1'b1; Lyc = 1'b1; Tdir = (Y == 'd0) || (Y == YSCREEN-YDIM); end

            // move the object
            I:  begin req = 1'b1; Ey = 1'b1; end

            // draw the object
            J:  begin req = 1'b1; Exc = 1'b1; write = 1'b1; end
            K:  begin req = 1'b1; Lxc = 1'b1; Eyc = 1'b1; end
            L:  Lyc = 1'b1; // reload YC, and release the request
        endcase
    end

    // FSM FFs 
    always @(posedge Clock)
        if (Resetn == 0)
            y_Q <= A;
        else
            y_Q <= Y_D;

    // specify the mask shift register. Shift in 1's from the MSB to speed up an object's
    // movement, and shift in 0's from the LSB to slow down an object's movement
    always @(posedge Clock) begin
        if (Resetn == 0)
            mask <= 'b0;
        else if (srl) begin
            mask[MM-2:0] <= mask[MM-1:1];
            mask[MM-1] <= 1'b1;
        end
        else if (sll) begin
            mask[MM-1:1] <= mask[MM-2:0];
            mask[0] <= 1'b0;
        end
    end

    // state codes for controlling the mask shift register
    parameter As = 3'b000, Bs = 3'b001, Cs = 3'b010, Ds = 3'b011, Es = 3'b100;

    // FSM for controlling speed of movement
    always @ (*)
        case (ys_Q)
            As: if (sel & faster) Ys_D = Bs;
                else if (sel & slower) Ys_D = Ds;
                else Ys_D = As;
            Bs: Ys_D = Cs;    // one cycle to shift
            Cs: if (sel & faster) Ys_D = Cs; // wait for KEY release
                else Ys_D = As;
            Ds: Ys_D = Es;    // one cycle to shift
            Es: if (sel & slower) Ys_D = Es; // wait for KEY release
                else Ys_D = As;
            default: Ys_D = As;
        endcase
    // FSM outputs
    always @ (*)
    begin
        // default assignments
        sll = 1'b0; srl = 1'b0;
        case (ys_Q)
            As:  ;
            Bs:  srl = 1'b1;    // shift in a 1 from the MSB
            Cs:  ;
            Ds:  sll = 1'b1;    // shift in a 0 from the LSB
            Es:  ;
        endcase
    end

    always @(posedge Clock)
        if (Resetn == 0)
            ys_Q <= As;
        else
            ys_Q <= Ys_D;

endmodule
