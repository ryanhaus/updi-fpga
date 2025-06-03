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


`endif
