// Handles doing a 'double break' to reset
// the UPDI interface.
module updi_double_break #(
	parameter PULSE_CLK = 100000 // pulse length in clks
) (
	input clk,
	input rst,

	// control signals
	input start,
	output logic busy,
	output logic done,

	// output
	output logic pulse
);

	localparam COUNTER_BITS = $clog2(PULSE_CLK);

	logic [COUNTER_BITS-1 : 0] counter; // counts from 0 to PULSE_CLK
	logic [1:0] pulse_n; // counts from 0 to 3

	always_ff @(posedge clk) begin
		if (rst) begin
			counter <= 'b0;
			pulse_n <= 'b0;
			busy <= 'b0;
			done <= 'b0;
		end
		else begin
			done <= 'b0;

			if (busy) begin
				if (counter == 'b0) begin
					// counter done, move to next pulse
					counter <= PULSE_CLK - 1;

					// if done reset, otherwise keep counting pulses
					if (pulse_n == 'd3) begin
						pulse_n <= 'b0;
						busy <= 'b0;
						done <= 'b1;
					end
					else begin
						pulse_n <= pulse_n + 'b1;
					end
				end
				else begin
					counter <= counter - 'b1;
				end

			end
			else if (start) begin
				busy <= 'b1;
				counter <= PULSE_CLK-1;
				pulse_n <= 'b0;
			end
		end
	end

	always_comb begin
		pulse = busy
			? (pulse_n & 'b1) == 'b1
			: 'b1;
	end

endmodule
