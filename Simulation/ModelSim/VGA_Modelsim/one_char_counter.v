// Module that counts the amount of time it takes to draw one character out
module one_char_counter(resetn, clock, counter, finishedCharacter);
	input resetn, clock; 
	reg [5:0] counter; 
	output reg finishedCharacter; 
	
	always @ (posedge clock) begin
		if (!resetn) begin
			counter <= 0; 
			finishedCharacter <= 0; 
		end else begin
			if (counter == 6'd63) begin
				counter <= 0
				finishedCharacter <= 0;
			end
			counter <= counter + 1;
			finishedCharacter <= 1; // Done 
		end
	end
endmodule
