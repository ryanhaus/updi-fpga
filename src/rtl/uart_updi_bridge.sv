`include "include.sv"

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

	logic updi_en, updi_out;
	assign updi = updi_en ? updi_out : 1'bz;

	always_comb begin
		case (mode)
			UPDI_BRIDGE_MODE_IDLE: begin
				updi_out = 'b1;
				updi_en = 'b1;
				rx = 'b0;
			end

			UPDI_BRIDGE_MODE_TX: begin
				updi_out = tx;
				updi_en = 'b1;
				rx = 'b0;
			end

			UPDI_BRIDGE_MODE_RX: begin
				updi_out = 'b0;
				updi_en = 'b0;
				rx = updi;
			end

			UPDI_BRIDGE_MODE_BREAK: begin
				updi_out = 'b0;
				updi_en = 'b1;
				rx = 'b0;
			end
		endcase
	end

endmodule
