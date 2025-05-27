// This module handles the high-level programming
// of the UPDI-capable chip.
module updi_programmer #(
	parameter ROM_ADDR_BITS = 16,
	parameter ROM_DATA_BITS = 8
) (
	input clk,
	input rst,

	// control signals
	input logic start,
	output logic busy,
	
	// ROM interface
	output logic [ROM_ADDR_BITS-1 : 0] rom_addr,
	input logic [ROM_DATA_BITS-1 : 0] rom_data,

	// UART/UPDI bridge interface
	output updi_bridge_mode updi_mode
);
	
	// State machine instance
	updi_programmer_sm state_machine (
		.clk(clk),
		.rst(rst),
		.start(start),
		.busy(busy),
		.updi_mode(updi_mode)
	);

endmodule
