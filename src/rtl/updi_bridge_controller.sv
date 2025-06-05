// Handles what mode the UART/UPDI bridge should be in
module updi_bridge_controller (
	// inputs
	input wr_en, // high = writing mode, low = reading mode
	input override_en, // overrides the UPDI line (used for BREAK)
	input override_value, // what value the UPDI line will have

	// output
	output updi_bridge_mode bridge_mode
);

	always_comb begin
		if (override_en) begin
			bridge_mode = override_value
				? UPDI_BRIDGE_MODE_IDLE
				: UPDI_BRIDGE_MODE_BREAK;
		end
		else begin
			bridge_mode = wr_en
				? UPDI_BRIDGE_MODE_TX
				: UPDI_BRIDGE_MODE_RX;
		end
	end

endmodule
