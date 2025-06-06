// UART states
typedef enum {
	UART_IDLE,
	UART_START,
	UART_DATA,
	UART_PARITY,
	UART_STOP
} uart_state;

// UART module
module uart #(
	parameter DATA_BITS = 8, // 5 - 9
	parameter PARITY_BIT = "none", // "none", "even", or "odd"
	parameter STOP_BITS = 1, // 1 - 2
	parameter UART_CLK_DIV = 10
) (
	input clk,
	input rst,

	// transmit
	input [DATA_BITS-1 : 0] tx_data,
	input transmit_start,
	output transmit_ready,
	output tx,

	// receive
	output [DATA_BITS-1 : 0] rx_data,
	output rx_data_valid,
	output rx_error,
	input rx
);

	// transmit
	uart_tx #(DATA_BITS, PARITY_BIT, STOP_BITS, UART_CLK_DIV) tx_module (clk, rst, tx_data, transmit_start, transmit_ready, tx);
		
	// receive
	uart_rx #(DATA_BITS, PARITY_BIT, UART_CLK_DIV) rx_module (clk, rst, rx_data, rx_data_valid, rx_error, rx);

endmodule
