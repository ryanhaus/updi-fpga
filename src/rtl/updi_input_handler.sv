// possible states for updi_input_handler
typedef enum {
	UPDI_IN_HDLR_IDLE,
	UPDI_IN_HDLR_READ_ACK,
	UPDI_IN_HDLR_CHECK_ACK,
	UPDI_IN_HDLR_FIFO_READ,
	UPDI_IN_HDLR_FIFO_WRITE,
	UPDI_IN_HDLR_DONE
} updi_input_handler_state;

// Handles receiving input. In ACK mode, a single value of 0x40 is expected to
// be received and the ack_received and ack_error flags will be updated. In
// normal mode, a certain number of received values are forwarded to another
// FIFO.
module updi_input_handler #(
	parameter BITS_N = 6, // number of bits for the 'n_bytes' parameter, which determines number of bytes read
	parameter TIMEOUT_CLKS = 1000 // number of clocks without a response to constitute a timeout
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
	output logic done, // high for 1 clock signal
	output logic timeout,

	// input FIFO interface (should be opposite clocked)
	input [7:0] in_fifo_data,
	input in_fifo_empty,
	output logic in_fifo_rd_en,
	
	// output FIFO interface (should be opposite clocked)
	output logic [7:0] out_fifo_data,
	input out_fifo_full,
	output logic out_fifo_wr_en
);

	// delay module for detecting timeouts
	logic timeout_rst, timeout_start, timeout_done;

	delay #(.N_CLKS(TIMEOUT_CLKS)) timeout_delay_inst (
		.clk(clk),
		.rst(rst | timeout_rst),
		.start(timeout_start),
		.done(timeout_done)
	);

	// state machine
	updi_input_handler_state state;
	logic [BITS_N-1 : 0] counter;
	assign out_fifo_data = in_fifo_data;

	always_ff @(posedge clk) begin
		if (rst) begin
			state <= UPDI_IN_HDLR_IDLE;
		end
		else begin
			case (state)
				UPDI_IN_HDLR_IDLE: begin
					// wait for start or wait_ack
					if (start) begin
						counter <= n_bytes;
						state <= UPDI_IN_HDLR_FIFO_READ;
					end
					else if (wait_ack) begin
						state <= UPDI_IN_HDLR_READ_ACK;
					end
				end

				UPDI_IN_HDLR_READ_ACK: begin
					if (timeout_done) begin
						state <= UPDI_IN_HDLR_IDLE;
					end

					if (!in_fifo_empty) begin
						state <= UPDI_IN_HDLR_CHECK_ACK;
					end
				end

				UPDI_IN_HDLR_CHECK_ACK: begin
					state <= UPDI_IN_HDLR_IDLE;
				end

				UPDI_IN_HDLR_FIFO_READ: begin
					if (timeout_done) begin
						state <= UPDI_IN_HDLR_IDLE;
					end

					if (!in_fifo_empty) begin
						state <= UPDI_IN_HDLR_FIFO_WRITE;
					end
				end

				UPDI_IN_HDLR_FIFO_WRITE: begin
					if (!out_fifo_full) begin
						if (counter == 'b1) begin
							state <= UPDI_IN_HDLR_DONE;
						end
						else begin
							counter <= counter - 'b1;
							state <= UPDI_IN_HDLR_FIFO_READ;
						end
					end
				end

				UPDI_IN_HDLR_DONE: begin
					state <= UPDI_IN_HDLR_IDLE;
				end
			endcase
		end
	end

	always_comb begin
		ready = 'b0;
		in_fifo_rd_en = 'b0;
		out_fifo_wr_en = 'b0;
		ack_received = 'b0;
		ack_error = 'b0;
		done = 'b0;
		timeout = 'b0;
		timeout_rst = 'b1;
		timeout_start = 'b0;

		case (state)
			UPDI_IN_HDLR_IDLE: begin
				ready = 'b1;
			end

			UPDI_IN_HDLR_READ_ACK: begin
				timeout_start = 'b1;
				timeout_rst = 'b0;

				if (timeout_done) begin
					timeout = 'b1;
				end

				if (!in_fifo_empty) begin
					in_fifo_rd_en = 'b1;
				end
			end

			UPDI_IN_HDLR_CHECK_ACK: begin
				in_fifo_rd_en = 'b0;

				if (in_fifo_data == 'h40) begin
					ack_received = 'b1;
				end
				else begin
					ack_error = 'b0;
				end
			end

			UPDI_IN_HDLR_FIFO_READ: begin
				timeout_start = 'b1;
				timeout_rst = 'b0;

				if (timeout_done) begin
					timeout = 'b1;
				end

				if (!in_fifo_empty) begin
					in_fifo_rd_en = 'b1;
				end
			end

			UPDI_IN_HDLR_FIFO_WRITE: begin
				if (!out_fifo_full) begin
					out_fifo_wr_en = 'b1;
				end
			end

			UPDI_IN_HDLR_DONE: begin
				ready = 'b1;
				done = 'b1;
			end
		endcase
	end

endmodule
