// Module for calculating odd parity
module parity #(
	parameter BITS = 8
) (
	input [BITS-1 : 0] value,
	output logic parity
);

	integer i;

	always_comb begin
		parity = 'b0;

		for (i = 0; i < BITS; i = i + 1) begin
			parity ^= value[i];
		end
	end

endmodule
