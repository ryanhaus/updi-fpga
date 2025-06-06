module top (
	input clk,
	input rst,
	input start,
	output busy,

	output [7:0] uart_tx_fifo_data_in,
	output uart_tx_fifo_wr_en,
	input uart_tx_fifo_full,

	input [7:0] uart_rx_fifo_data_out,
	output uart_rx_fifo_rd_en,
	input uart_rx_fifo_empty,
	
	output double_break_start,
	input double_break_busy,
	input double_break_done
);

	// `ROM_NAME and `ROM_SIZE are passed from compiler
	// buffer size should be next highest pwr of 2
	localparam ROM_BUFFER_SIZE = 2 ** $clog2(`ROM_SIZE);

	// UPDI programmer instance
	updi_programmer #(
		.ROM_FILE_NAME(`ROM_NAME),
		.ROM_SIZE(ROM_BUFFER_SIZE),
		.ROM_ADDR_BITS($clog2(ROM_BUFFER_SIZE))
	) programmer_inst (
		.clk(clk),
		.rst(rst),
		.start(start),
		.busy(busy),
		.uart_tx_fifo_data_in(uart_tx_fifo_data_in),
		.uart_tx_fifo_wr_en(uart_tx_fifo_wr_en),
		.uart_tx_fifo_full(uart_tx_fifo_full),
		.uart_rx_fifo_data_out(uart_rx_fifo_data_out),
		.uart_rx_fifo_rd_en(uart_rx_fifo_rd_en),
		.uart_rx_fifo_empty(uart_rx_fifo_empty),
		.double_break_start(double_break_start),
		.double_break_busy(double_break_busy),
		.double_break_done(double_break_done)
	);

endmodule
