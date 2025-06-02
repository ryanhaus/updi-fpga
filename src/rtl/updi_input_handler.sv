// possible states for updi_input_handler
typedef enum {
	UPDI_IN_HDLR_IDLE,
	UPDI_IN_HDLR_ACK,
	UPDI_IN_HDLR_NORMAL
} updi_input_handler_state;

// Handles receiving input. In ACK mode, a single value of 0x40 is expected to
// be received and the ack_received and ack_error flags will be updated. In
// normal mode, a certain number of received values are forwarded to another
// FIFO.
module updi_input_handler #(
	parameter BITS_N = 6 // number of bits for the 'n_bytes' parameter, which determines number of bytes read
) (
	input clk,
	input rst,

	// ACK mode control signals
	input wait_ack,
	output logic ack_received,
	output logic ack_error,

	// normal mode control signals
	input [BITS_N-1 : 0] n_bytes,
	input start,
	output logic ready,

	// input FIFO interface (should be opposite clocked)
	input [7:0] in_fifo_data,
	input in_fifo_empty,
	output logic in_fifo_rd_en,
	
	// output FIFO interface (should be opposite clocked)
	output logic [7:0] out_fifo_data,
	input out_fifo_full,
	output logic out_fifo_wr_en
);

	updi_input_handler_state state;
	logic [BITS_N-1 : 0] counter;
	logic fifo_in_valid; // was in_fifo_rd_en high on the last clock cycle?

	always_ff @(posedge clk) begin
		in_fifo_rd_en = 'b0;
		out_fifo_wr_en = 'b0;
		ack_received = 'b0;
		ack_error = 'b0;

		if (rst) begin
			state = UPDI_IN_HDLR_IDLE;
			ready = 'b0;	
		end
		else begin
			case (state)
				UPDI_IN_HDLR_IDLE: begin
					// wait for start or wait_ack
					ready = 'b1;

					if (start) begin
						counter = n_bytes;
						ready = 'b0;
						in_fifo_rd_en = 'b1;
						state = UPDI_IN_HDLR_NORMAL;
					end

					if (wait_ack) begin
						ready = 'b0;
						state = UPDI_IN_HDLR_ACK;
					end
				end

				UPDI_IN_HDLR_ACK: begin
					// wait for ack, if it hasn't been read already
					if (!in_fifo_empty && !fifo_in_valid) begin
						in_fifo_rd_en = 'b1;
					end

					// read ACK
					if (fifo_in_valid) begin
						if (in_fifo_data == 'h40) begin
							ack_received = 'b1;
						end
						else begin
							ack_error = 'b1;
						end

						ready = 'b1;
						state = UPDI_IN_HDLR_IDLE;
					end
				end

				UPDI_IN_HDLR_NORMAL: begin
					// read bytes & redirect to output FIFO
					if (!in_fifo_empty && !out_fifo_full) begin
						in_fifo_rd_en = 'b1;
					end

					if (!out_fifo_full) begin
						if (fifo_in_valid) begin
							out_fifo_data = in_fifo_data;
							out_fifo_wr_en = 'b1;

							// figure out when done
							// counter was set to n bytes to read before start
							counter = counter - 'b1;
							if (counter == 'b0) begin
								in_fifo_rd_en = 'b0;
								ready = 'b1;
								state = UPDI_IN_HDLR_IDLE;
							end
						end
					end
				end
			endcase

			fifo_in_valid = in_fifo_rd_en;
		end
	end

endmodule
