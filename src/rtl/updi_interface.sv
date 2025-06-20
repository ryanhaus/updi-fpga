// UPDI interface, acts as bridge between sending commands and
// sending/receiving data and UART FIFO
module updi_interface #(
	parameter MAX_DATA_SIZE = 16,
	parameter DATA_ADDR_BITS = $clog2(MAX_DATA_SIZE),
	parameter TIMEOUT_CLKS = 100
) (
	input clk,
	input rst,

	// instruction inputs
	input instr_converter_en,
	updi_instruction instruction,
	input [1:0] size_a,
	input [1:0] size_b,
	input [1:0] ptr,
	input [3:0] cs_addr,
	input sib,
	input [1:0] size_c,

	// instruction data inputs
	input [7:0] data [MAX_DATA_SIZE],
	input [DATA_ADDR_BITS:0] data_len, // 1 extra bit for sending the whole buffer
	input [MAX_DATA_SIZE-1 : 0] wait_ack_after,

	// tx control signals
	input tx_start,
	output tx_ready,
	output tx_done,

	// rx control signals
	input [DATA_ADDR_BITS-1 : 0] rx_n_bytes,
	input rx_start,
	output rx_ready,
	output rx_done,
	output rx_timeout,
	output ack_error,

	// output rx data FIFO interface
	output [7:0] out_rx_fifo_data,
	output out_rx_fifo_wr_en,
	input out_rx_fifo_full,

	// UART FIFO interface
	input [7:0] uart_rx_fifo_data,
	output uart_rx_fifo_rd_en,
	input uart_rx_fifo_empty,

	output [7:0] uart_tx_fifo_data,
	output uart_tx_fifo_wr_en,
	input uart_tx_fifo_full
);

	logic [7:0] opcode;
	logic waiting_for_ack, ack_received;

	// instruction converter instance
	updi_instruction_converter instr_conv (
		.rst(rst),
		.enable(instr_converter_en),
		.instruction(instruction),
		.size_a(size_a),
		.size_b(size_b),
		.ptr(ptr),
		.cs_addr(cs_addr),
		.sib(sib),
		.size_c(size_c),
		.opcode(opcode)
	);

	// instruction queue handler instance
	updi_instruction_queue_handler #(
		.MAX_DATA_SIZE(MAX_DATA_SIZE),
		.DATA_ADDR_BITS(DATA_ADDR_BITS)
	) instr_hdlr (
		.clk(clk),
		.rst(rst),
		.start(tx_start),
		.ready(tx_ready),
		.done(tx_done),
		.waiting_for_ack(waiting_for_ack),
		.ack_received(ack_received),
		.opcode(opcode),
		.data(data),
		.data_len(data_len),
		.wait_ack_after(wait_ack_after),
		.fifo_data(uart_tx_fifo_data),
		.fifo_wr_en(uart_tx_fifo_wr_en),
		.fifo_full(uart_tx_fifo_full)
	);

	// input handler instance
	updi_input_handler #(
		.BITS_N(DATA_ADDR_BITS),
		.TIMEOUT_CLKS(TIMEOUT_CLKS)
	) input_hdlr (
		.clk(clk),
		.rst(rst),
		.wait_ack(waiting_for_ack),
		.ack_received(ack_received),
		.ack_error(ack_error),
		.n_bytes(rx_n_bytes),
		.start(rx_start),
		.ready(rx_ready),
		.done(rx_done),
		.timeout(rx_timeout),
		.in_fifo_data(uart_rx_fifo_data),
		.in_fifo_empty(uart_rx_fifo_empty),
		.in_fifo_rd_en(uart_rx_fifo_rd_en),
		.out_fifo_data(out_rx_fifo_data),
		.out_fifo_full(out_rx_fifo_full),
		.out_fifo_wr_en(out_rx_fifo_wr_en)
	);

endmodule
