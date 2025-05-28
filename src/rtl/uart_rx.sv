// Module for handling UART RX traffic
/* verilator lint_off WIDTHEXPAND */
module uart_rx #(
	parameter DATA_BITS = 8, // 5 - 9
	parameter PARITY_BIT = "none" // "none", "even", or "odd"
) (
	input clk,
	input rst,

	output logic [DATA_BITS-1 : 0] rx_data,
	output logic rx_data_valid, // high for 1 clk
	output logic rx_error, // high for 1 clk
	input rx
);

	uart_state state;

	// find frame length in bits (excluding start bit and stop bits)
	localparam FRAME_BITS = DATA_BITS + (PARITY_BIT == "none" ? 0 : 1);

	logic [FRAME_BITS-1 : 0] frame; // holds the UART frame
	logic [$clog2(FRAME_BITS)-1 : 0] counter; // used in state machine

	wire [DATA_BITS-1 : 0] data = frame[DATA_BITS-1 : 0];
	wire frame_parity = frame[$bits(frame)-1];

	// parity module (for verification)
	logic parity_result;
	parity #(.BITS(DATA_BITS)) parity_inst (data, parity_result);

	// parity_result will always be odd, adjust to be even if necessary
	wire expected_parity = (PARITY_BIT == "odd") ? parity_result : ~parity_result;

	// state machine
	always_ff @(posedge clk) begin
		if (rst) begin
			state = UART_IDLE;
			rx_data = 'b0;
			rx_data_valid = 'b0;
			rx_error = 'b0;
		end
		else begin
			// no START or STOP state since they are ignored
			case (state)
				UART_IDLE: begin
					frame = 'b0;
					counter = 'b0;

					rx_data_valid = 'b0;
					rx_error = 'b0;

					// a RX of 0 indicates a start bit
					if (rx == 'b0) begin
						state = UART_DATA;
					end
				end

				UART_DATA: begin
					// this state includes the collection of the parity bit,
					// but it is verified in the UART_PARITY state
					frame[counter] = rx;

					// if done, go to parity check, otherwise keep reading
					if (counter == FRAME_BITS-1) begin
						state = UART_PARITY;
					end
					else begin
						counter = counter + 'b1;
						state = UART_DATA;
					end
				end

				UART_PARITY: begin
					// check parity, if OK update output registers, otherwise
					// set error flag
					if (expected_parity == frame_parity) begin
						rx_data = data;
						rx_data_valid = 'b1;
					end
					else begin
						rx_error = 'b1;
					end

					// either way, go back to IDLE
					state = UART_IDLE;
				end
			endcase
		end
	end

endmodule
/* lint_on */
