// one-shot pulse generator
module one_shot #(
	parameter HOLD_CLOCKS = 100
) (
	input clk,
	input rst,

	input in,
	output logic out
);

	integer counter;

	always_ff @(posedge clk) begin
		if (rst) begin
			counter <= 'b0;
		end
		else begin
			if (in == 'b1) begin
				counter <= HOLD_CLOCKS;
			end
			else if (counter != 'b0) begin
				counter <= counter - 'b1;
			end
		end
	end

	always_comb begin
		out = (counter != 'b0);
	end

endmodule
