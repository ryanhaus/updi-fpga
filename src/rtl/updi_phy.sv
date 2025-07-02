`include "include.sv"

// Handles UART/UPDI transactions
module updi_phy #(
	parameter UART_FIFO_DEPTH = 16,
	parameter DOUBLE_BREAK_PULSE_CLK = 100000,
	parameter UART_CLK_DIV = 10
) (
	input clk,
	input rst,

	// UART FIFO interface
	input [7:0] uart_tx_fifo_data,
	input uart_tx_fifo_wr_en,
	output uart_tx_fifo_full,
	output uart_tx_fifo_almost_full,

	output [7:0] uart_rx_fifo_data,
	input uart_rx_fifo_rd_en,
	output uart_rx_fifo_empty,
	output uart_rx_fifo_almost_empty,
	output rx_error,

	// UPDI double break interface
	input double_break_start,
	output double_break_busy,
	output double_break_done,

	// UPDI output
	inout updi
);

	logic tx, rx;
	logic uart_tx_active;
	logic double_break_pulse;
	updi_bridge_mode bridge_mode;

	// UART FIFO instance
	uart_fifo #(
		.DATA_BITS(8),
		.PARITY_BIT("even"),
		.STOP_BITS(2),
		.FIFO_DEPTH(UART_FIFO_DEPTH),
		.UART_CLK_DIV(UART_CLK_DIV)
	) uart_fifo_inst (
		.clk(clk),
		.rst(rst),
		.tx_data(uart_tx_fifo_data),
		.rx_data(uart_rx_fifo_data),
		.tx_fifo_wr_en(uart_tx_fifo_wr_en),
		.rx_fifo_rd_en(uart_rx_fifo_rd_en),
		.tx_fifo_full(uart_tx_fifo_full),
		.tx_fifo_almost_full(uart_tx_fifo_almost_full),
		.tx_fifo_empty(),
		.tx_fifo_almost_empty(),
		.rx_fifo_full(),
		.rx_fifo_almost_full(),
		.rx_fifo_empty(uart_rx_fifo_empty),
		.rx_fifo_almost_empty(uart_rx_fifo_almost_empty),
		.rx_error(rx_error),
		.uart_busy(uart_tx_active),
		.tx(tx),
		.rx(rx)
	);

	// UPDI bridge instance
	uart_updi_bridge bridge_inst (
		.tx(tx),
		.rx(rx),
		.mode(bridge_mode),
		.updi(updi)
	);

	// UPDI bridge controller instance
	updi_bridge_controller bridge_ctrl_inst (
		.wr_en(uart_tx_active),
		.override_en(double_break_busy),
		.override_value(double_break_pulse),
		.bridge_mode(bridge_mode)
	);

	// UPDI double break instance
	updi_double_break #(
		.PULSE_CLK(DOUBLE_BREAK_PULSE_CLK)
	) double_break_inst (
		.clk(clk),
		.rst(rst),
		.start(double_break_start),
		.busy(double_break_busy),
		.done(double_break_done),
		.pulse(double_break_pulse)
	);

endmodule
