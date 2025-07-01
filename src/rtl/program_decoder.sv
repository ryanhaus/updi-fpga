// All the states for the decoder
typedef enum {
	PROG_DECODER_IDLE,
	PROG_DECODER_READ_LENGTH,
	PROG_DECODER_READ_ADDRESS,
	PROG_DECODER_READ_TYPE,
	PROG_DECODER_READ_DATA
} program_decoder_state;

// Program decoder module. Programs are stored similar to Intel hex files but
// with certain metadata stripped away. See src/util/program_convert.py
/* verilator lint_off WIDTHEXPAND */
module program_decoder #(
	parameter PROGRAM_SIZE = 16, // size of program in bytes
	parameter PROG_ADDR_BITS = $clog2(PROGRAM_SIZE), // bits needed for program address
	parameter DATA_BLOCK_MAX_SIZE = 64, // max number of data bytes per block
	parameter DATA_BLOCK_ADDR_BITS = $clog2(DATA_BLOCK_MAX_SIZE) // bits for data in block
) (
	input clk,
	input rst,

	// program interface, assumes sync 8-bit ROM
	output logic [PROG_ADDR_BITS-1 : 0] prog_addr,
	input [7:0] prog_data,

	// control signals
	input start,
	output logic ready,
	output logic done,

	// outputs
	output logic [7:0] block_length,
	output logic [15:0] block_address,
	output logic [7:0] block_type,
	output logic [7:0] block_data [DATA_BLOCK_MAX_SIZE]
);

	// program decoder state machine
	program_decoder_state state;
	logic [7:0] counter;

	always_ff @(posedge clk) begin
		if (rst) begin
			state <= PROG_DECODER_IDLE;
			counter <= 'b0;

			ready <= 'b0;
			done <= 'b0;
			prog_addr <= 'b0;
		end
		else begin
			case (state)
				PROG_DECODER_IDLE: begin
					// wait idle until start signal
					ready <= 'b1;
					done <= 'b0;
					counter <= 'b0;

					if (start) begin
						ready <= 'b0;
						state <= PROG_DECODER_READ_LENGTH;
					end
				end

				PROG_DECODER_READ_LENGTH: begin
					// current value in ROM represents the block length
					block_length <= prog_data;

					// increase addr, next state
					prog_addr <= prog_addr + 'b1;
					state <= PROG_DECODER_READ_ADDRESS;
				end

				PROG_DECODER_READ_ADDRESS: begin
					// address is a 2-byte value, MSB first
					if (counter == 'b0) begin
						// first cycle, read in MSB
						block_address[15:8] <= prog_data;
						prog_addr <= prog_addr + 'b1;
						counter <= counter + 'b1;
					end
					else begin
						// second cycle, read in LSB & continue to next state
						block_address[7:0] <= prog_data;
						prog_addr <= prog_addr + 'b1;
						counter <= 'b0;
						state <= PROG_DECODER_READ_TYPE;
					end
				end

				PROG_DECODER_READ_TYPE: begin
					// current value in ROM represents the block type
					block_type <= prog_data;
					prog_addr <= prog_addr + 'b1;
					state <= PROG_DECODER_READ_DATA;
				end

				PROG_DECODER_READ_DATA: begin
					// read block_length bytes from ROM
					if (counter < block_length) begin
						// keep reading until done
						block_data[counter[DATA_BLOCK_ADDR_BITS-1 : 0]] <= prog_data;
						prog_addr <= prog_addr + 'b1;
						counter <= counter + 'b1;
					end
					else begin
						// once block_length bytes have been read, block is
						// finished
						ready <= 'b1;
						done <= 'b1;
						state <= PROG_DECODER_IDLE;
					end
				end
			endcase
		end
	end

endmodule
/* lint_on */
