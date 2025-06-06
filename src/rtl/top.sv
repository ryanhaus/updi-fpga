module top (
	input clk,
	input rst,
	input start,
	output busy,
	inout updi
);

	// `ROM_NAME and `ROM_SIZE are passed from compiler
	// buffer size should be next highest pwr of 2
	localparam ROM_BUFFER_SIZE = 2 ** $clog2(`ROM_SIZE);

	// UPDI programmer instance
	updi_programmer #(
		.ROM_FILE_NAME(`ROM_NAME),
		.ROM_SIZE(ROM_BUFFER_SIZE),
		.ROM_ADDR_BITS($clog2(ROM_BUFFER_SIZE)),
		.UART_CLK_DIV(100),
		.DOUBLE_BREAK_PULSE_CLK(100)
	) programmer_inst (
		.clk(clk),
		.rst(rst),
		.start(start),
		.busy(busy),
		.updi(updi)
	);

endmodule
