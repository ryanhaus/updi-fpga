// Current state of the UPDI programmer.
typedef enum {
	UPDI_PROG_IDLE,
	UPDI_PROG_RESET_UPDI,
	UPDI_PROG_RESET_CHIP,
	UPDI_PROG_READ_UPDI_STATUS,
	UPDI_PROG_UNLOCK_CHIPERASE,
	UPDI_PROG_UNLOCK_NVMPROG,
	UPDI_PROG_READ_DEVICE_ID,
	UPDI_PROG_PROGRAM_ROM,
	UPDI_PROG_VERIFY_ROM
} updi_programmer_state;

// UPDI programmer state machine
module updi_programmer_sm(
	input clk,
	input rst,

	// control signals
	input start,
	output busy,

	// UART/UPDI bridge interface
	output updi_bridge_mode updi_mode
);

	updi_programmer_state state;

	always_ff @(posedge clk) begin
		if (rst) begin
			state = UPDI_PROG_IDLE;
			updi_bridge_mode = UPDI_BRIDGE_MODE_IDLE;
		end
		else begin
			busy = 'b1;

			case (state)
				UPDI_PROG_STATE_IDLE: begin
					busy = 'b0;

					if (start)
						state = UPDI_PROG_RESET_UPDI;
				end

				UPDI_PROG_RESET_UPDI: begin
					
				end
			endcase

		end
	end

endmodule
