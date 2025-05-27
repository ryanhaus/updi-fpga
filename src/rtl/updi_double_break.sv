// Handles doing a 'double break' to reset
// the UPDI interface. A double break is a
// long 1 pulse, followed by a long 0 pulse,
// followed by another long 1 pulse.
module updi_double_break #(
	parameter PULSE_CLK = 100000 // pulse length in clks
) (
	input clk,
	input rst,

	// control signals
	input start,
	output logic busy,

	// output
	output logic pulse
);

	localparam COUNTER_BITS = $clog2(PULSE_CLK);

	logic [COUNTER_BITS-1 : 0] counter; // counts from 0 to PULSE_CLK
	logic [1:0] pulse_n; // counts from 0 to 2

	always_ff @(posedge clk) begin
		if (rst) begin
			counter = 'b0;
			pulse_n = 'b0;
			busy = 'b0;
			pulse = 'b0;
		end
		else begin
			pulse = 'b0;

			if (busy) begin
				counter = counter + 'b1;

				if (counter == PULSE_CLK) begin
					// counter done, move to next pulse
					counter = 'b0;
					pulse_n = pulse_n + 'b1;

					if (pulse_n == 'd3) begin
						// pulses done
						pulse_n = 'b0;
						busy = 'b0;
					end
				end

				pulse = (pulse_n & 'b1) == 'b1;
			end
			else if (start) begin
				busy = 'b1;
				counter = 'b1;
				pulse_n = 'b0;
			end
		end
	end

endmodule
