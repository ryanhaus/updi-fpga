`ifndef INCLUDE_SV
`define INCLUDE_SV

// All of the UPDI instructions
typedef enum {
	UPDI_LDS,
	UPDI_LD,
	UPDI_STS,
	UPDI_ST,
	UPDI_LDCS,
	UPDI_REPEAT,
	UPDI_STCS,
	UPDI_KEY
} updi_instruction;

// The mode that the UART/UPDI bridge is in.
// The bridge can either let TX or RX traffic
// pass through the UPDI line.
typedef enum {
	UPDI_BRIDGE_MODE_IDLE, // pulls UPDI line high
	UPDI_BRIDGE_MODE_TX, // allows TX traffic through
	UPDI_BRIDGE_MODE_RX, // allows RX traffic through
	UPDI_BRIDGE_MODE_BREAK // pulls UPDI line low
} updi_bridge_mode;

// key constants
`define KEY_CHIPERASE 'h4E564D4572617365
`define KEY_NVMPROG 'h4E564D50726F6720

task load_key (input [63:0] key, output [7:0] arr [8]);
	// loads a key into an array
	begin
		arr[0] = key[7:0];
		arr[1] = key[15:8];
		arr[2] = key[23:16];
		arr[3] = key[31:24];
		arr[4] = key[39:32];
		arr[5] = key[47:40];
		arr[6] = key[55:48];
		arr[7] = key[63:56];
	end
endtask

`endif
