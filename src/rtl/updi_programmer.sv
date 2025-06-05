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
	parameter RX_OUT_FIFO_DEPTH = 16
) (
	input clk,
	input rst,

	// control signals
	input logic start,
	output logic busy,

	// UPDI output
	output updi
);

	// signals
	// ROM signals
	logic program_start, program_ready, program_done;
	logic [7:0] program_block_length, program_block_type;
	logic [15:0] program_block_address;
	logic [7:0] program_block_data [DATA_BLOCK_MAX_SIZE];

	// interface signals
	updi_instruction instruction;
	logic instr_sib;
	logic [1:0] instr_size_a, instr_size_b, instr_ptr, instr_size_c;
	logic [3:0] instr_cs_addr;

	logic [7:0] instr_data [MAX_DATA_SIZE];
	logic [DATA_ADDR_BITS-1 : 0] instr_data_len;
	logic [MAX_DATA_SIZE-1 : 0] instr_wait_ack_after;

	logic interface_tx_start, interface_tx_ready;
	logic interface_rx_start, interface_rx_ready, interface_ack_error;
	logic [DATA_ADDR_BITS-1 : 0] interface_rx_n_bytes;

	logic [7:0] out_rx_fifo_data_in;
	logic out_rx_fifo_wr_en, out_rx_fifo_full;

	logic [7:0] uart_rx_fifo_data_out;
	logic uart_rx_fifo_rd_en, uart_rx_fifo_empty;
	
	logic [7:0] uart_tx_fifo_data_in;
	logic uart_tx_fifo_wr_en, uart_tx_fifo_full;

	// RX out FIFO signals
	logic [7:0] out_rx_fifo_data_out;
	logic out_rx_fifo_rd_en, out_rx_fifo_empty;

	// PHY signals
	logic phy_rx_error;
	logic uart_clk;
	logic double_break_start, double_break_busy, double_break_done;

	// program ROM instance
	program_rom #(
		.FILE_NAME(ROM_FILE_NAME),
		.SIZE(ROM_SIZE),
		.DATA_BLOCK_MAX_SIZE(DATA_BLOCK_MAX_SIZE)
	) rom_inst (
		.clk(clk),
		.rst(rst),
		.start(program_start),
		.ready(program_ready),
		.done(program_done),
		.block_length(program_block_length),
		.block_address(program_block_address),
		.block_type(program_block_type),
		.block_data(program_block_data)
	);

	// UPDI interface instance
	updi_interface #(
		.MAX_DATA_SIZE(MAX_INSTRUCTION_DATA_SIZE),
		.DATA_ADDR_BITS(DATA_ADDR_BITS)
	) interface_inst (
		.clk(clk),
		.rst(rst),
		.instruction(instruction),
		.size_a(instr_size_a),
		.size_b(instr_size_b),
		.ptr(instr_ptr),
		.cs_addr(instr_cs_addr),
		.sib(instr_sib),
		.size_c(instr_size_c),
		.data(instr_data),
		.data_len(instr_data_len),
		.wait_ack_after(instr_wait_ack_after),
		.tx_start(interface_tx_start),
		.tx_ready(interface_tx_ready),
		.rx_n_bytes(interface_rx_n_bytes),
		.rx_start(interface_rx_start),
		.rx_ready(interface_rx_ready),
		.ack_error(interface_ack_error),
		.out_rx_fifo_data(out_rx_fifo_data_in),
		.out_rx_fifo_wr_en(out_rx_fifo_wr_en),
		.out_rx_fifo_full(out_rx_fifo_full),
		.uart_rx_fifo_data(uart_rx_fifo_data_out),
		.uart_rx_fifo_rd_en(uart_rx_fifo_rd_en),
		.uart_rx_fifo_empty(uart_rx_fifo_empty),
		.uart_tx_fifo_data(uart_tx_fifo_data_in),
		.uart_tx_fifo_wr_en(uart_tx_fifo_wr_en),
		.uart_tx_fifo_full(uart_tx_fifo_full)
	);

	// RX output FIFO instance
	fifo #(
		.DEPTH(RX_OUT_FIFO_DEPTH)
	) rx_out_fifo_inst (
		.clk(clk),
		.rst(rst),
		.in(out_rx_fifo_data),
		.out(out_rx_fifo_data_out),
		.rd_en(out_rx_fifo_rd_en),
		.wr_en(out_rx_fifo_wr_en),
		.empty(out_rx_fifo_empty),
		.full(out_rx_fifo_full)
	);

	// UPDI PHY instance
	updi_phy #(
		.UART_FIFO_DEPTH(UART_FIFO_DEPTH)
	) phy_inst (
		.clk(clk),
		.uart_clk(uart_clk),
		.rst(rst),
		.uart_tx_fifo_data(uart_tx_fifo_data),
		.uart_tx_fifo_wr_en(uart_tx_fifo_wr_en),
		.uart_tx_fifo_full(uart_tx_fifo_full),
		.uart_rx_fifo_data(uart_rx_fifo_data),
		.uart_rx_fifo_rd_en(uart_rx_fifo_rd_en),
		.uart_rx_fifo_empty(uart_rx_fifo_empty),
		.rx_error(phy_rx_error),
		.double_break_start(double_break_start),
		.double_break_busy(double_break_busy),
		.double_break_done(double_break_done),
		.updi(updi)
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
