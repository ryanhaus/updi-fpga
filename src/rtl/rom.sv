// Read-only memory from a .mem file
module rom #(
	parameter FILE_NAME = "",
	parameter SIZE = 1,
	parameter DATA_BITS = 8,
	parameter ADDR_BITS = $clog2(SIZE)
) (
	input clk,

	input [ADDR_BITS-1 : 0] addr,
	output logic [DATA_BITS-1 : 0] out
);

	// data for ROM
	logic [DATA_BITS-1 : 0] data [SIZE];
	initial $readmemh(FILE_NAME, data);

	// handle reading
	always_ff @(posedge clk) begin
		out <= data[addr];
	end

endmodule
