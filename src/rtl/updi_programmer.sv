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
	parameter ROM_FILE_NAME = "",
	parameter ROM_SIZE = 1,
	parameter ROM_ADDR_BITS = 16,
	parameter ROM_DATA_BITS = 8,

	parameter MAX_INSTRUCTION_DATA_SIZE = 64,
	parameter DATA_ADDR_BITS = $clog2(MAX_INSTRUCTION_DATA_SIZE),
	
	parameter DATA_BLOCK_MAX_SIZE = 2 ** (DATA_ADDR_BITS + 1),

	parameter UART_FIFO_DEPTH = 16,
	parameter RX_OUT_FIFO_DEPTH = 16,

	parameter UPDI_DOUBLE_BREAK_PULSE_CLK = 100000
) (
	input clk,
	input rst,

	// control signals
	input logic start,
	output logic busy,

	// UPDI output
	output updi
);

	// program ROM instance
	program_rom #(
		.FILE_NAME(ROM_FILE_NAME),
		.SIZE(ROM_SIZE),
		.DATA_BLOCK_MAX_SIZE(DATA_BLOCK_MAX_SIZE)
	) rom_inst (
		.clk(clk),
		.rst(rst),
		.start(),
		.ready(),
		.done(),
		.block_length(),
		.block_address(),
		.block_type(),
		.block_data()
	);

	// UPDI interface instance
	updi_interface #(
		.MAX_DATA_SIZE(MAX_INSTRUCTION_DATA_SIZE),
		.DATA_ADDR_BITS(DATA_ADDR_BITS)
	) interface_inst (
		.clk(clk),
		.rst(rst),
		.instruction(),
		.size_a(),
		.size_b(),
		.ptr(),
		.cs_addr(),
		.sib(),
		.size_c(),
		.data(),
		.data_len(),
		.wait_ack_after(),
		.tx_start(),
		.tx_ready(),
		.rx_n_bytes(),
		.rx_start(),
		.rx_ready(),
		.ack_error(),
		.out_rx_fifo_data(),
		.out_rx_fifo_wr_en(),
		.out_rx_fifo_full(),
		.uart_rx_fifo_data(),
		.uart_rx_fifo_rd_en(),
		.uart_rx_fifo_empty(),
		.uart_tx_fifo_data(),
		.uart_tx_fifo_wr_en(),
		.uart_tx_fifo_full()
	);

	// RX output FIFO instance
	fifo #(
		.DEPTH(RX_OUT_FIFO_DEPTH)
	) rx_out_fifo_inst (
		.clk(clk),
		.rst(rst),
		.in(),
		.out(),
		.rd_en(),
		.wr_en(),
		.empty(),
		.full()
	);

	// UPDI PHY instance
	updi_phy #(
		.UART_FIFO_DEPTH(UART_FIFO_DEPTH)
	) phy_inst (
		.clk(clk),
		.uart_clk(),
		.rst(rst),
		.uart_tx_fifo_data(),
		.uart_tx_fifo_wr_en(),
		.uart_tx_fifo_full(),
		.uart_rx_fifo_data(),
		.uart_rx_fifo_rd_en(),
		.uart_rx_fifo_empty(),
		.rx_error(),
		.updi_override_en(),
		.updi_override_value(),
		.updi(updi)
	);

	// double break instance
	updi_double_break #(
		.PULSE_CLK(UPDI_DOUBLE_BREAK_PULSE_CLK)
	) double_break_inst (
		.clk(clk),
		.rst(rst),
		.start(),
		.busy(),
		.pulse()
	);
	
	// State machine
	updi_programmer_state state;

	always_ff @(posedge clk) begin
		if (rst) begin
			state <= UPDI_PROG_IDLE;
		end
		else begin
			case (state)
				UPDI_PROG_IDLE: begin

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

	always_comb begin
		case (state)
			UPDI_PROG_IDLE: begin

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

endmodule
