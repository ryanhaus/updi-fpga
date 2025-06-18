// states for the UART FIFO TX state machine
typedef enum {
	UART_FIFO_TX_IDLE,
	UART_FIFO_TX_READ_FIFO,
	UART_FIFO_TX_WAIT_UART_READY,
	UART_FIFO_TX_TRANSMISSION_START
} uart_fifo_tx_state;

// UART FIFO module for sending/receiving multiple bytes faster
module uart_fifo #(
	parameter DATA_BITS = 8, // 5 - 9
	parameter PARITY_BIT = "none", // "none", "even", or "odd"
	parameter STOP_BITS = 1, // 1 - 2
	parameter FIFO_DEPTH = 16, // how many values
	parameter UART_CLK_DIV = 10
) (
	input clk,
	input rst,

	input [DATA_BITS-1 : 0] tx_data,
	output [DATA_BITS-1 : 0] rx_data,

	input tx_fifo_wr_en,
	input rx_fifo_rd_en,

	output tx_fifo_full,
	output tx_fifo_empty,
	output rx_fifo_full,
	output rx_fifo_empty,

	output rx_error,
	output logic uart_busy,

	output tx,
	input rx
);

	logic [DATA_BITS-1 : 0] tx_data_current;
	logic [DATA_BITS-1 : 0] rx_data_current;

	logic tx_fifo_rd_en;
	logic rx_fifo_wr_en;

	logic transmit_start;
	wire transmit_ready;
	wire rx_data_valid;

	// UART instance
	uart #(DATA_BITS, PARITY_BIT, STOP_BITS, UART_CLK_DIV) uart_inst (
		.clk(clk),
		.rst(rst),
		.tx_data(tx_data_current),
		.transmit_start(transmit_start),
		.transmit_ready(transmit_ready),
		.tx(tx),
		.rx_data(rx_data_current),
		.rx_data_valid(rx_data_valid),
		.rx_error(rx_error),
		.rx(rx)
	);

	// FIFOs
	fifo #(.DEPTH(FIFO_DEPTH), .WIDTH(DATA_BITS)) tx_fifo (
		.clk(clk),
		.rst(rst),
		.in(tx_data),
		.out(tx_data_current),
		.rd_en(tx_fifo_rd_en),
		.wr_en(tx_fifo_wr_en),
		.empty(tx_fifo_empty),
		.full(tx_fifo_full)
	);

	fifo #(.DEPTH(FIFO_DEPTH), .WIDTH(DATA_BITS)) rx_fifo (
		.clk(clk),
		.rst(rst),
		.in(rx_data_current),
		.out(rx_data),
		.rd_en(rx_fifo_rd_en),
		.wr_en(rx_fifo_wr_en),
		.empty(rx_fifo_empty),
		.full(rx_fifo_full)
	);

	// RX controller logic
	logic prev_rx_data_valid; // used for edge detection on rx_data_valid

	always_ff @(posedge clk) begin
		if (rst) begin
			prev_rx_data_valid <= 'b0;
			rx_fifo_wr_en <= 'b0;
		end
		else begin
			if (prev_rx_data_valid == 'b0 && rx_data_valid == 'b1) begin
				// positive edge of rx_data_valid:
				// write to rx fifo
				rx_fifo_wr_en <= 'b1;
			end
			else begin
				rx_fifo_wr_en <= 'b0;
			end

			prev_rx_data_valid <= rx_data_valid;
		end
	end

	// TX controller logic
	uart_fifo_tx_state tx_state; // TX state machine state
	logic queue_transmit_start; // set transmit_start on the next clock cycle

	always_ff @(posedge clk) begin

		if (rst) begin
			queue_transmit_start <= 'b0;
			tx_fifo_rd_en <= 'b0;
		end
		else begin
			// TX state machine
			case (tx_state)
				UART_FIFO_TX_IDLE: begin
					// wait idle until there is data available in FIFO
					tx_fifo_rd_en <= 'b0;

					if (!tx_fifo_empty) begin
						tx_state <= UART_FIFO_TX_READ_FIFO;
					end
				end

				UART_FIFO_TX_READ_FIFO: begin
					// if UART is ready, pop a value from FIFO & start transmission, otherwise wait
					if (transmit_ready) begin
						tx_fifo_rd_en <= 'b1;
						tx_state <= UART_FIFO_TX_TRANSMISSION_START;
					end
					else begin
						tx_fifo_rd_en <= 'b1;
						tx_state <= UART_FIFO_TX_WAIT_UART_READY;
					end
				end

				UART_FIFO_TX_WAIT_UART_READY: begin
					// wait until UART is ready for transmission
					tx_fifo_rd_en <= 'b0;

					if (transmit_ready) begin
						tx_state <= UART_FIFO_TX_TRANSMISSION_START;
					end
				end

				UART_FIFO_TX_TRANSMISSION_START: begin
					// attempt to start transmission until the UART
					// "acknowledges" it by setting transmit_ready low
					transmit_start <= 'b1;
					tx_fifo_rd_en <= 'b0;

					if (!transmit_ready) begin
						// if there is still data, skip going back to idle and
						// start processing that data
						if (!tx_fifo_empty) begin
							tx_state <= UART_FIFO_TX_READ_FIFO;
						end
						else begin
							tx_state <= UART_FIFO_TX_IDLE;
						end
					end
				end
			endcase
		end
	end

	// busy flag, set whenever UART is actively transmitting something or
	// a transmission is being prepared
	always_comb begin
		uart_busy = 'b0;

		if (tx_state != UART_FIFO_TX_IDLE) begin
			uart_busy = 'b1;
		end

		if (!transmit_ready) begin
			uart_busy = 'b1;
		end
	end

endmodule
