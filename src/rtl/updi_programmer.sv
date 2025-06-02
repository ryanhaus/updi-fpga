// Possible states of the UPDI programmer.
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
	
	// State machine
	updi_programmer_state state;

	always_ff @(posedge clk) begin
		if (rst) begin
			state = UPDI_PROG_IDLE;
			updi_mode = UPDI_BRIDGE_MODE_IDLE;
		end
		else begin
			case (state)
				UPDI_PROG_IDLE: begin
					busy = 'b0;

					if (start) begin
						state = UPDI_PROG_RESET_UPDI;
					end
				end
				
				UPDI_PROG_RESET_UPDI: begin
				
				end
				
				UPDI_PROG_RESET_CHIP: begin
				
				end
				
				UPDI_PROG_READ_UPDI_STATUS: begin
				
				end
				
				UPDI_PROG_UNLOCK_CHIPERASE: begin
				
				end
				
				UPDI_PROG_UNLOCK_NVMPROG: begin
				
				end
				
				UPDI_PROG_READ_DEVICE_ID: begin
				
				end
				
				UPDI_PROG_PROGRAM_ROM: begin
				
				end
				
				UPDI_PROG_VERIFY_ROM: begin
				
				end
			endcase
		end
	end

endmodule
