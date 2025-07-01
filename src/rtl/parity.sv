// Module for calculating parity
module parity #(
	parameter BITS = 8,
	parameter PARITY = "even" // "none", "even", or "odd"
) (
	input [BITS-1 : 0] value,
	output logic out
);

	integer i;

	always_comb begin
		out = 'b0;

		if (PARITY != "none") begin
			for (i = 0; i < BITS; i = i + 1) begin
				out ^= value[i];
			end

			if (PARITY == "odd") begin
				out = ~out;
			end
		end
	end

endmodule
