// customizable FIFO (first in, first out)
// see https://www.chipverify.com/verilog/synchronous-fifo
module fifo #(
	parameter DEPTH = 16, // how many values there are
	parameter WIDTH = 8, // how many bits wide each value is
	parameter ALMOST_EMPTY_THRESHOLD = 3, // how many elements remaining for almost_empty to be high
	parameter ALMOST_FULL_THRESHOLD = 3 // how many empty elements remaining for almost_full to be high
) (
	input clk,
	input rst,

	// data
	input [WIDTH-1 : 0] in,
	output logic [WIDTH-1 : 0] out,

	// control signals
	input rd_en,
	input wr_en,

	// status indicators
	output logic empty,
	output logic almost_empty,
	output logic full,
	output logic almost_full
);

	localparam ADDR_BITS = $clog2(DEPTH); // n bits to represent all values

	logic [WIDTH-1 : 0] memory [DEPTH];
	logic [ADDR_BITS-1 : 0] rd_ptr;
	logic [ADDR_BITS-1 : 0] wr_ptr;
	integer n_elements;

	wire [ADDR_BITS-1 : 0] next_rd_ptr = rd_ptr + 'b1;
	wire [ADDR_BITS-1 : 0] next_wr_ptr = wr_ptr + 'b1;

	always_ff @(posedge clk) begin
		if (rst) begin
			out <= 'b0;
			rd_ptr <= 'b0;
			wr_ptr <= 'b0;
			n_elements <= 'b0;
		end
		else begin
			// handle a read
			if (rd_en && !empty) begin
				out <= memory[rd_ptr];
				rd_ptr <= next_rd_ptr;
				n_elements <= n_elements - 'b1;
			end

			// handle a write
			if (wr_en && !full) begin
				memory[wr_ptr] <= in;
				wr_ptr <= next_wr_ptr;
				n_elements <= n_elements + 'b1;
			end
		end
	end

	// status flags
	assign empty = (rd_ptr == wr_ptr);
	assign almost_empty = (n_elements <= ALMOST_EMPTY_THRESHOLD);
	assign full = (rd_ptr == next_wr_ptr);
	assign almost_full = (n_elements >= DEPTH - ALMOST_FULL_THRESHOLD);

endmodule
