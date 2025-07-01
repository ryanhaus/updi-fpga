// Module for handling UART TX traffic
/* verilator lint_off WIDTHEXPAND */
module uart_tx #(
	parameter DATA_BITS = 8, // 5 - 9
	parameter PARITY_BIT = "none", // "none", "even", or "odd"
	parameter STOP_BITS = 1, // 1 - 2
	parameter UART_CLK_DIV = 10
) (
	input clk, // logic clk
	input rst,

	input [DATA_BITS-1 : 0] tx_data,
	input start,
	output logic ready,
	output logic tx
);

	uart_state state;
	logic [DATA_BITS-1 : 0] data;
	logic [$clog2(DATA_BITS)-1 : 0] counter; // used for data & stop bits

	// parity module
	logic parity;
	parity #(.BITS(DATA_BITS), .PARITY(PARITY_BIT)) parity_inst (data, parity);

	// clock divider module
	logic uart_clk, uart_clk_div_rst;

	clock_divider #(.DIV(UART_CLK_DIV)) clk_div_inst (
		.clk_in(clk),
		.rst(rst || uart_clk_div_rst),
		.clk_out(uart_clk)
	);

	// UART state machine
	always_ff @(posedge clk) begin
		if (rst) begin
			state <= UART_IDLE;
			ready <= 'b0;
		end
		else begin
			case (state)
				UART_IDLE: begin
					// idle until start signal
					if (start) begin
						uart_clk_div_rst <= 'b1;
						state <= UART_START;
						ready <= 'b0;
						data <= tx_data;
						counter <= 'b0;
					end
					else begin
						ready <= 'b1;
					end
				end

				UART_START: begin
					uart_clk_div_rst <= 'b0;

					// always one 0 bit
					if (uart_clk == 'b1) begin
						state <= UART_DATA;
					end
				end

				UART_DATA: begin
					if (uart_clk == 'b1) begin
						// handle going to next state if applicable
						if (counter == DATA_BITS-1) begin
							if (PARITY_BIT == "none") begin
								state <= UART_STOP;
							end
							else begin
								state <= UART_PARITY;
							end
						end
						else begin
							// otherwise just keep going through data bits
							counter <= counter + 'b1;
							state <= UART_DATA;
						end
					end
				end

				UART_PARITY: begin
					if (uart_clk == 'b1) begin
						// for just 1 stop bit, simply going back to idle is
						// enough since it will pull TX high
						if (STOP_BITS > 1) begin
							counter <= STOP_BITS;
							state <= UART_STOP;
						end
						else begin
							state <= UART_IDLE;
						end
					end
				end

				UART_STOP: begin
					if (uart_clk == 'b1) begin
						if (counter != 'b1) begin
							// have to repeat for multiple stop bits
							counter <= counter - 'b1;
							state <= UART_STOP;
						end
						else begin
							state <= UART_IDLE;
							ready <= 'b1;
						end
					end
				end
			endcase
		end
	end

	always_comb begin
		case (state)
			UART_IDLE: tx = 'b1;
			UART_START: tx = 'b0;
			UART_DATA: tx = data[counter];
			UART_PARITY: tx = parity;
			UART_STOP: tx = 'b1;
		endcase
	end

endmodule
/* lint_on */
