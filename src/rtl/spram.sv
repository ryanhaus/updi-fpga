typedef enum {
	SPRAM_IDLE,
	SPRAM_READ,
	SPRAM_WRITE
} spram_mode;

// Single-port random-access memory
module spram #(
	parameter SIZE = 1,
	parameter DATA_BITS = 8,
	parameter ADDR_BITS = $clog2(SIZE),
	parameter DELETE_ON_RESET = 0
) (
	input clk,
	input rst,

	input spram_mode mode,

	input [ADDR_BITS-1 : 0] rd_addr,
	input [ADDR_BITS-1 : 0] wr_addr,

	input [DATA_BITS-1 : 0] data_wr,
	output logic [DATA_BITS-1 : 0] data_rd
);

	logic [DATA_BITS-1 : 0] mem [SIZE];

	integer i;

	always @(posedge clk) begin
		if (rst && DELETE_ON_RESET) begin
			for (i = 0; i < SIZE; i = i + 1)
				mem[i] <= 'b0;
		end
		else begin
			case (mode)
				SPRAM_IDLE: begin end

				SPRAM_READ: begin
					data_rd <= mem[rd_addr];
				end

				SPRAM_WRITE: begin
					mem[wr_addr] <= data_wr;
				end
			endcase
		end
	end

endmodule
