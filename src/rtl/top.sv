`ifdef VERILATOR
// top-level module for verilator
module top (
	input clk,
	input rst,
	input start,
	output busy,
	input phy_error,

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
		.phy_error(phy_error),
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

`else
// top-level module for synthesis
module top (
	input clk,
	input rst,
	input programmer_start,
	output programmer_busy,
	inout updi
);

	localparam CLK_FREQ = 100000000;
	localparam DOUBLE_BREAK_MS = 50;
	localparam DELAY_MS = 50;
	localparam TIMEOUT_MS = 500;
	localparam UART_CLK_FREQ = 57600;

	localparam DOUBLE_BREAK_CLKS = CLK_FREQ * DOUBLE_BREAK_MS / 1000;
	localparam DELAY_CLKS = CLK_FREQ * DELAY_MS / 1000;
	localparam TIMEOUT_CLKS = CLK_FREQ * TIMEOUT_MS / 1000;
	localparam UART_CLK_DIV = CLK_FREQ / UART_CLK_FREQ;

	// programmer instance
	logic [7:0] uart_tx_fifo_data_in, uart_rx_fifo_data_out;
	logic uart_tx_fifo_wr_en, uart_tx_fifo_full;
	logic uart_rx_fifo_rd_en, uart_rx_fifo_empty;
	logic phy_error;

	updi_programmer #(
		.ROM_FILE_NAME("program.mem"),
		.ROM_SIZE(512),
		.DELAY_N_CLKS(DELAY_CLKS),
		.TIMEOUT_CLKS(TIMEOUT_CLKS)
	) programmer_inst (
		.clk(clk),
		.rst(rst),
		.start(programmer_start),
		.busy(programmer_busy),
		.phy_error(phy_error),
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

	// PHY instance
	updi_phy #(
		.DOUBLE_BREAK_PULSE_CLK(DOUBLE_BREAK_CLKS),
		.UART_CLK_DIV(UART_CLK_DIV)
	) phy_inst (
		.clk(clk),
		.rst(rst),
		.uart_tx_fifo_data(uart_tx_fifo_data_in),
		.uart_tx_fifo_wr_en(uart_tx_fifo_wr_en),
		.uart_tx_fifo_full(uart_tx_fifo_full),
		.uart_rx_fifo_data(uart_rx_fifo_data_out),
		.rx_error(phy_error),
		.uart_rx_fifo_rd_en(uart_rx_fifo_rd_en),
		.uart_rx_fifo_empty(uart_rx_fifo_empty),
		.double_break_start(double_break_start),
		.double_break_busy(double_break_busy),
		.double_break_done(double_break_done),
		.updi(updi)
	);

endmodule
`endif
