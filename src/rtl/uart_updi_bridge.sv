// The mode that the UART/UPDI bridge is in.
// The bridge can either let TX or RX traffic
// pass through the UPDI line.
typedef enum {
	UPDI_BRIDGE_MODE_IDLE, // pulls UPDI line high
	UPDI_BRIDGE_MODE_TX, // allows TX traffic through
	UPDI_BRIDGE_MODE_RX, // allows RX traffic through
	UPDI_BRIDGE_MODE_BREAK // pulls UPDI line low
} updi_bridge_mode;

// Converts UART (a TX/RX pair) into an UPDI signal.
// Note that the 'mode' has to be selected
module uart_updi_bridge (
	// UART
	input logic tx,
	output logic rx,

	// mode selection
	input updi_bridge_mode mode,

	// UPDI
	inout updi
);

	always_comb begin
		case (mode)
			UPDI_BRIDGE_MODE_IDLE: begin
				updi <= 'b1;
				rx <= 'b0;
			end

			UPDI_BRIDGE_MODE_TX: begin
				updi <= tx;
				rx <= 'b0;
			end

			UPDI_BRIDGE_MODE_RX: begin
				updi <= 'bz;
				rx <= updi;
			end

			UPDI_BRIDGE_MODE_BREAK: begin
				updi <= 'b0;
				rx <= 'b0;
			end
		endcase
	end

endmodule
