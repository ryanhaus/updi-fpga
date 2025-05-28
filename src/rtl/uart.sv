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
	parameter STOP_BITS = 1 // 1 - 2
) (
	input clk, // gets divided by CLK_DIV to create baud rate
	input rst,

	// transmit
	input [DATA_BITS-1 : 0] tx_data,
	input transmit_start,
	output transmit_ready,
	output tx,

	// receive
	output [DATA_BITS-1 : 0] rx_data,
	output rx_data_valid,
	input rx
);

	// transmit
	uart_tx #(DATA_BITS, PARITY_BIT, STOP_BITS) tx_module (clk, rst, tx_data, transmit_start, transmit_ready, tx);
		
	// receive
	// TODO

endmodule
