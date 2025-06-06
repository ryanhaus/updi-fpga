// Divides an incoming clock signal by a given amount. Output is 1 for one
// clock cycle every N clock cycles
module clock_divider #(
	parameter DIV = 10, // how many clock cycles between each pulse
	parameter SHIFT = DIV-1 // how many clock cycles it takes for the first pulse
) (
	input clk_in,
	input rst,
	output logic clk_out
);

	generate
		if (DIV == 1) begin
			// always valid
			assign clk_out = 'b1;
		end
		else begin
			// valid every DIV clock cycles
			localparam COUNTER_BITS = $clog2(DIV);

			logic [COUNTER_BITS-1 : 0] counter;

			always_ff @(posedge clk_in) begin
				if (rst) begin
					counter <= 'b0;
					clk_out <= 'b0;
				end
				else begin
					clk_out <= (counter == SHIFT[COUNTER_BITS-1 : 0]);

					if (counter == DIV - 1) begin
						counter <= 'b0;
					end
					else begin
						counter <= counter + 'b1;
					end
				end
			end
		end
	endgenerate

endmodule
