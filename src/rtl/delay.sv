// waits a certain number of clock cycles after a start pulse to output a done
// pulse
module delay #(
	parameter N_CLKS = 100
) (
	input clk,
	input rst,

	input start,
	output logic active,
	output logic done
);

	localparam COUNTER_BITS = $clog2(N_CLKS);
	logic [COUNTER_BITS-1 : 0] counter;

	always_ff @(posedge clk) begin
		if (rst) begin
			counter <= 'b0;
			active <= 'b0;
		end
		else begin
			if (start) begin
				active <= 'b1;
			end

			if (active) begin
				if (counter == N_CLKS-1) begin
					active <= 'b0;
					counter <= 'b0;
				end
				else begin
					counter <= counter + 'b1;
				end
			end
		end
	end

	always_comb begin
		done = 'b0;

		if (active) begin
			if (counter == N_CLKS-1) begin
				done = 'b1;
			end
		end
	end

endmodule
