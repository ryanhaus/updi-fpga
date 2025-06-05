// Module for representing a program. Combines a 'rom' and 'program_decoder'
// module together
module program_rom #(
	parameter FILE_NAME = "",
	parameter SIZE = 1,
	parameter DATA_BLOCK_MAX_SIZE = 64
) (
	input clk,
	input rst,

	input start,
	output ready,
	output done,

	output [7:0] block_length,
	output [15:0] block_address,
	output [7:0] block_type,
	output [7:0] block_data [DATA_BLOCK_MAX_SIZE]
);

	localparam ROM_ADDR_BITS = $clog2(SIZE);
	localparam ROM_DATA_BITS = 8;

	// ROM module
	logic [ROM_ADDR_BITS-1 : 0] rom_addr;
	logic [ROM_DATA_BITS-1 : 0] rom_data;

	rom #(
		.FILE_NAME(FILE_NAME),
		.SIZE(SIZE),
		.DATA_BITS(ROM_DATA_BITS),
		.ADDR_BITS(ROM_ADDR_BITS)
	) rom_inst (
		.clk(clk),
		.addr(rom_addr),
		.out(rom_data)
	);

	// program decoder module
	program_decoder #(
		.PROGRAM_SIZE(SIZE),
		.PROG_ADDR_BITS(ROM_ADDR_BITS),
		.DATA_BLOCK_MAX_SIZE(DATA_BLOCK_MAX_SIZE)
	) program_decoder_inst (
		.clk(clk),
		.rst(rst),
		.prog_addr(rom_addr),
		.prog_data(rom_data),
		.start(start),
		.ready(ready),
		.done(done),
		.block_length(block_length),
		.block_address(block_address),
		.block_type(block_type),
		.block_data(block_data)
	);

endmodule
