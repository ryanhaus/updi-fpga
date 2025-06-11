// Possible states of the UPDI programmer.
typedef enum {
	UPDI_PROG_IDLE,

	UPDI_PROG_RESET_UPDI_DB_START,
	UPDI_PROG_RESET_UPDI_DB_WAIT,

	UPDI_PROG_READ_UPDI_STATUS_READ,
	UPDI_PROG_READ_UPDI_STATUS_WAIT_DONE,
	UPDI_PROG_READ_UPDI_STATUS_VERIFY,

	UPDI_PROG_UNLOCK_CHIPERASE_SEND_KEY,
	UPDI_PROG_UNLOCK_CHIPERASE_SEND_KEY_WAIT_DONE,
	UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS,
	UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS_WAIT_DONE,
	UPDI_PROG_UNLOCK_CHIPERASE_VERIFY_STATUS,
	UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_START,
	UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_START_WAIT_DONE,
	UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_WAIT_DELAY,
	UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_CLEAR,
	UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_CLEAR_WAIT_DONE,
	UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ,
	UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_WAIT_DONE,
	UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_VERIFY,
	UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_WAIT_DELAY,

	UPDI_PROG_UNLOCK_NVMPROG_SEND_KEY,
	UPDI_PROG_UNLOCK_NVMPROG_SEND_KEY_WAIT_DONE,
	UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS,
	UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS_WAIT_DONE,
	UPDI_PROG_UNLOCK_NVMPROG_VERIFY_STATUS,
	UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_START,
	UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_START_WAIT_DONE,
	UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_WAIT_DELAY,
	UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_CLEAR,
	UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_CLEAR_WAIT_DONE,
	UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ,
	UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_WAIT_DONE,
	UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_VERIFY,
	UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_WAIT_DELAY,

	UPDI_PROG_READ_DEVICE_ID_SET_RD_PTR,
	UPDI_PROG_READ_DEVICE_ID_SET_RD_PTR_WAIT_DONE,
	UPDI_PROG_READ_DEVICE_ID_SET_REPEAT,
	UPDI_PROG_READ_DEVICE_ID_SET_REPEAT_WAIT_DONE,
	UPDI_PROG_READ_DEVICE_ID_READ,
	UPDI_PROG_READ_DEVICE_ID_READ_WAIT_DONE,
	UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE0,
	UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE1,
	UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE2,

	UPDI_PROG_PROGRAM_ROM_DECODER_START_SEGMENT,
	UPDI_PROG_PROGRAM_ROM_DECODER_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_DECODER_VERIFY_SEGMENT,
	UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ,
	UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_VERIFY,
	UPDI_PROG_PROGRAM_ROM_NVM_CLEAR,
	UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ,
	UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_VERIFY,
	UPDI_PROG_PROGRAM_ROM_SET_WR_PTR,
	UPDI_PROG_PROGRAM_ROM_SET_WR_PTR_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_SET_REPEAT,
	UPDI_PROG_PROGRAM_ROM_SET_REPEAT_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_WRITE_DATA,
	UPDI_PROG_PROGRAM_ROM_WRITE_DATA_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_WRITE_PAGE_BUFFER,
	UPDI_PROG_PROGRAM_ROM_WRITE_PAGE_BUFFER_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_START,
	UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_START_WAIT_DONE,
	UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_WAIT_DELAY,
	UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_CLEAR,
	UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_CLEAR_WAIT_DONE,

	UPDI_PROG_VERIFY_ROM
} updi_programmer_state;

// This module handles the high-level programming
// of the UPDI-capable chip.
module updi_programmer #(
	parameter ROM_FILE_NAME = "",
	parameter ROM_SIZE = 1,
	parameter ROM_ADDR_BITS = $clog2(ROM_SIZE),
	parameter ROM_DATA_BITS = 8,

	parameter MAX_INSTRUCTION_DATA_SIZE = 64,
	parameter DATA_ADDR_BITS = $clog2(MAX_INSTRUCTION_DATA_SIZE),
	
	parameter DATA_BLOCK_MAX_SIZE = MAX_INSTRUCTION_DATA_SIZE,

	parameter RX_OUT_FIFO_DEPTH = 16,

	parameter DELAY_N_CLKS = 100
) (
	input clk,
	input rst,

	// control signals
	input logic start,
	output logic busy,

	// UART PHY instance
	output [7:0] uart_tx_fifo_data_in,
	output uart_tx_fifo_wr_en,
	input uart_tx_fifo_full,

	input [7:0] uart_rx_fifo_data_out,
	output uart_rx_fifo_rd_en,
	input uart_rx_fifo_empty,
	
	output double_break_start,
	input double_break_busy,
	input double_break_done
);

	// signals
	// ROM signals
	logic program_start, program_ready, program_done;
	logic [7:0] program_block_length, program_block_type;
	logic [15:0] program_block_address;
	logic [7:0] program_block_data [DATA_BLOCK_MAX_SIZE];

	// interface signals
	logic instr_converter_en;
	updi_instruction instruction;
	logic instr_sib;
	logic [1:0] instr_size_a, instr_size_b, instr_ptr, instr_size_c;
	logic [3:0] instr_cs_addr;

	logic [7:0] instr_data [MAX_INSTRUCTION_DATA_SIZE];
	logic [DATA_ADDR_BITS:0] instr_data_len, latched_instr_data_len;
	logic [MAX_INSTRUCTION_DATA_SIZE-1 : 0] instr_wait_ack_after, latched_instr_wait_ack_after;

	logic interface_tx_start, interface_tx_ready;
	logic interface_rx_start, interface_rx_ready, interface_rx_done, interface_ack_error;
	logic [DATA_ADDR_BITS-1 : 0] interface_rx_n_bytes;

	logic [7:0] out_rx_fifo_data_in;
	logic out_rx_fifo_wr_en, out_rx_fifo_full;

	// RX out FIFO signals
	logic [7:0] out_rx_fifo_data_out;
	logic out_rx_fifo_rd_en, out_rx_fifo_empty;

	// delay signals
	logic delay_start, delay_done;

	// program ROM instance
	program_rom #(
		.FILE_NAME(ROM_FILE_NAME),
		.SIZE(ROM_SIZE),
		.DATA_BLOCK_MAX_SIZE(DATA_BLOCK_MAX_SIZE),
		.ROM_ADDR_BITS(ROM_ADDR_BITS)
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
		.instr_converter_en(instr_converter_en),
		.instruction(instruction),
		.size_a(instr_size_a),
		.size_b(instr_size_b),
		.ptr(instr_ptr),
		.cs_addr(instr_cs_addr),
		.sib(instr_sib),
		.size_c(instr_size_c),
		.data(instr_data),
		.data_len(latched_instr_data_len),
		.wait_ack_after(latched_instr_wait_ack_after),
		.tx_start(interface_tx_start),
		.tx_ready(interface_tx_ready),
		.rx_n_bytes(interface_rx_n_bytes),
		.rx_start(interface_rx_start),
		.rx_ready(interface_rx_ready),
		.rx_done(interface_rx_done),
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
		.in(out_rx_fifo_data_in),
		.out(out_rx_fifo_data_out),
		.rd_en(out_rx_fifo_rd_en),
		.wr_en(out_rx_fifo_wr_en),
		.empty(out_rx_fifo_empty),
		.full(out_rx_fifo_full)
	);

	// delay instance
	delay #(.N_CLKS(DELAY_N_CLKS)) delay_inst (
		.clk(clk),
		.rst(rst),
		.start(delay_start),
		.done(delay_done)
	);

	// State machine
	updi_programmer_state state;
	logic [7:0] device_id [3];
	logic valid;

	always_ff @(posedge clk) begin
		if (rst) begin
			state <= UPDI_PROG_IDLE;
		end
		else begin
			case (state)
				UPDI_PROG_IDLE: begin
					// wait for start signal
					if (start) begin
						state <= UPDI_PROG_RESET_UPDI_DB_START;
					end
				end
				
				UPDI_PROG_RESET_UPDI_DB_START: begin
					// start UPDI double break
					state <= UPDI_PROG_RESET_UPDI_DB_WAIT;
				end

				UPDI_PROG_RESET_UPDI_DB_WAIT: begin
					// wait for UPDI double break to finish
					if (double_break_done && interface_tx_ready) begin
						state <= UPDI_PROG_READ_UPDI_STATUS_READ;
					end
				end

				UPDI_PROG_READ_UPDI_STATUS_READ: begin
					state <= UPDI_PROG_READ_UPDI_STATUS_WAIT_DONE;
				end

				UPDI_PROG_READ_UPDI_STATUS_WAIT_DONE: begin
					if (interface_rx_done) begin
						state <= UPDI_PROG_READ_UPDI_STATUS_VERIFY;
					end
				end

				UPDI_PROG_READ_UPDI_STATUS_VERIFY: begin
					state <= UPDI_PROG_UNLOCK_CHIPERASE_SEND_KEY;
				end

				UPDI_PROG_UNLOCK_CHIPERASE_SEND_KEY: begin
					state <= UPDI_PROG_UNLOCK_CHIPERASE_SEND_KEY_WAIT_DONE;
				end
				
				UPDI_PROG_UNLOCK_CHIPERASE_SEND_KEY_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS;
					end
				end

				UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS: begin
					state <= UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS_WAIT_DONE;
				end

				UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS_WAIT_DONE: begin
					if (interface_rx_done) begin
						state <= UPDI_PROG_UNLOCK_CHIPERASE_VERIFY_STATUS;
					end
				end

				UPDI_PROG_UNLOCK_CHIPERASE_VERIFY_STATUS: begin
					state <= UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_START;
				end

				UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_START: begin
					state <= UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_START_WAIT_DONE;
				end

				UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_START_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_WAIT_DELAY;
					end
				end

				UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_WAIT_DELAY: begin
					if (delay_done) begin
						state <= UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_CLEAR;
					end
				end

				UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_CLEAR: begin
					state <= UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_CLEAR_WAIT_DONE;
				end

				UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_CLEAR_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ;
					end
				end
				
				UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ: begin
					state <= UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_WAIT_DONE;
				end
				
				UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_WAIT_DONE: begin
					if (interface_rx_done) begin
						state <= UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_VERIFY;
					end
				end
				
				UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_VERIFY: begin
					state <= valid
						? UPDI_PROG_UNLOCK_NVMPROG_SEND_KEY
						: UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_WAIT_DELAY;
				end

				UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_WAIT_DELAY: begin
					if (delay_done) begin
						state <= UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ;
					end
				end

				UPDI_PROG_UNLOCK_NVMPROG_SEND_KEY: begin
					state <= UPDI_PROG_UNLOCK_NVMPROG_SEND_KEY_WAIT_DONE;
				end

				UPDI_PROG_UNLOCK_NVMPROG_SEND_KEY_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS;
					end
				end

				UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS: begin
					state <= UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS_WAIT_DONE;
				end

				UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS_WAIT_DONE: begin
					if (interface_rx_done) begin
						state <= UPDI_PROG_UNLOCK_NVMPROG_VERIFY_STATUS;
					end
				end

				UPDI_PROG_UNLOCK_NVMPROG_VERIFY_STATUS: begin
					state <= UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_START;
				end

				UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_START: begin
					state <= UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_START_WAIT_DONE;
				end

				UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_START_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_WAIT_DELAY;
					end
				end

				UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_WAIT_DELAY: begin
					if (delay_done) begin
						state <= UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_CLEAR;
					end
				end
				
				UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_CLEAR: begin
					state <= UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_CLEAR_WAIT_DONE;
				end

				UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_CLEAR_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ;
					end
				end
				
				UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ: begin
					state <= UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_WAIT_DONE;
				end
				
				UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_WAIT_DONE: begin
					if (interface_rx_done) begin
						state <= UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_VERIFY;
					end
				end
				
				UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_VERIFY: begin
					state <= valid
						? UPDI_PROG_READ_DEVICE_ID_SET_RD_PTR
						: UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_WAIT_DELAY;
				end
				
				UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_WAIT_DELAY: begin
					if (delay_done) begin
						state <= UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ;
					end
				end
				
				UPDI_PROG_READ_DEVICE_ID_SET_RD_PTR: begin
					state <= UPDI_PROG_READ_DEVICE_ID_SET_RD_PTR_WAIT_DONE;
				end

				UPDI_PROG_READ_DEVICE_ID_SET_RD_PTR_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_READ_DEVICE_ID_SET_REPEAT;
					end
				end
				
				UPDI_PROG_READ_DEVICE_ID_SET_REPEAT: begin
					state <= UPDI_PROG_READ_DEVICE_ID_SET_REPEAT_WAIT_DONE;
				end

				UPDI_PROG_READ_DEVICE_ID_SET_REPEAT_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_READ_DEVICE_ID_READ;
					end
				end
				
				UPDI_PROG_READ_DEVICE_ID_READ: begin
					state <= UPDI_PROG_READ_DEVICE_ID_READ_WAIT_DONE;
				end

				UPDI_PROG_READ_DEVICE_ID_READ_WAIT_DONE: begin
					if (interface_rx_done) begin
						state <= UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE0;
					end
				end

				UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE0: begin
					state <= UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE1;
				end

				UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE1: begin
					state <= UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE2;
				end

				UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE2: begin
					state <= UPDI_PROG_PROGRAM_ROM_DECODER_START_SEGMENT;
				end

				UPDI_PROG_PROGRAM_ROM_DECODER_START_SEGMENT: begin
					state <= UPDI_PROG_PROGRAM_ROM_DECODER_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_DECODER_WAIT_DONE: begin
					if (program_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_DECODER_VERIFY_SEGMENT;
					end
				end
				
				UPDI_PROG_PROGRAM_ROM_DECODER_VERIFY_SEGMENT: begin
					state <= valid
						? UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ
						: UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_START;
				end

				UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ: begin
					state <= UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_VERIFY;
					end
				end

				UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_VERIFY: begin
					state <= valid
						? UPDI_PROG_PROGRAM_ROM_NVM_CLEAR
						: UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ;
				end
				
				UPDI_PROG_PROGRAM_ROM_NVM_CLEAR: begin
					state <= UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_DONE;
				end
				
				UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ;
					end
				end

				UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ: begin
					state <= UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_VERIFY;
					end
				end

				UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_VERIFY: begin
					state <= valid
						? UPDI_PROG_PROGRAM_ROM_SET_WR_PTR
						: UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ;
				end

				UPDI_PROG_PROGRAM_ROM_SET_WR_PTR: begin
					state <= UPDI_PROG_PROGRAM_ROM_SET_WR_PTR_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_SET_WR_PTR_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_SET_REPEAT;
					end
				end

				UPDI_PROG_PROGRAM_ROM_SET_REPEAT: begin
					state <= UPDI_PROG_PROGRAM_ROM_SET_REPEAT_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_SET_REPEAT_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_WRITE_DATA;
					end
				end

				UPDI_PROG_PROGRAM_ROM_WRITE_DATA: begin
					state <= UPDI_PROG_PROGRAM_ROM_WRITE_DATA_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_WRITE_DATA_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_WRITE_PAGE_BUFFER;
					end
				end
				
				UPDI_PROG_PROGRAM_ROM_WRITE_PAGE_BUFFER: begin
					state <= UPDI_PROG_PROGRAM_ROM_WRITE_PAGE_BUFFER_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_WRITE_PAGE_BUFFER_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_DECODER_START_SEGMENT;
					end
				end

				UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_START: begin
					state <= UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_START_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_START_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_WAIT_DELAY;
					end
				end

				UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_WAIT_DELAY: begin
					if (delay_done) begin
						state <= UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_CLEAR;
					end
				end
				
				UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_CLEAR: begin
					state <= UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_CLEAR_WAIT_DONE;
				end

				UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_CLEAR_WAIT_DONE: begin
					if (interface_tx_ready) begin
						state <= UPDI_PROG_VERIFY_ROM;
					end
				end
				
				UPDI_PROG_VERIFY_ROM: begin
				
				end
			endcase
		end
	end

	always_comb begin
		if (rst) begin
			device_id = '{default: 'b0};
		end

		busy = 'b1;

		double_break_start = 'b0;

		instr_converter_en = 'b0;
		instruction = UPDI_LDS;
		instr_sib = 'b0;
		instr_size_a = 'b0;
		instr_size_b = 'b0;
		instr_ptr = 'b0;
		instr_size_c = 'b0;
		instr_cs_addr = 'b0;
		
		instr_data_len = 'b0;
		instr_wait_ack_after = 'b0;

		interface_rx_start = 'b0;
		interface_tx_start = 'b0;
		out_rx_fifo_rd_en = 'b0;

		delay_start = 'b0;
		program_start = 'b0;

		valid = 'b0;
		
		case (state)
			UPDI_PROG_IDLE: begin
				busy = 'b0;
			end

			UPDI_PROG_RESET_UPDI_DB_START: begin
				double_break_start = 'b1;
			end

			UPDI_PROG_READ_UPDI_STATUS_READ: begin
				// send instruction to read STATUSA register (0x00)
				instr_converter_en = 'b1;
				instruction = UPDI_LDCS;
				instr_cs_addr = 'h0;

				interface_tx_start = 'b1;
				
				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_READ_UPDI_STATUS_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_READ_UPDI_STATUS_VERIFY: begin
				// make sure status != 0x00
				if (out_rx_fifo_data_out != 'h00) begin
					valid = 'b1;
				end

				if (!valid) $error();
			end

			UPDI_PROG_UNLOCK_CHIPERASE_SEND_KEY: begin
				instr_converter_en = 'b1;
				instruction = UPDI_KEY;

				load_key(`KEY_CHIPERASE, instr_data[0:7]);
				instr_data_len = 'd8;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS: begin
				// send instruction to read ASI_KEY_STATUS register (0x07)
				instr_converter_en = 'b1;
				instruction = UPDI_LDCS;
				instr_cs_addr = 'h7;

				interface_tx_start = 'b1;

				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_CHIPERASE_READ_STATUS_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_UNLOCK_CHIPERASE_VERIFY_STATUS: begin
				// make sure status bit 3 == 1
				if (out_rx_fifo_data_out[3] == 'b1) begin
					valid = 'b1;
				end

				if (!valid) $error();
			end

			UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_START: begin
				// store the system reset signature (0x59) into ASI_RESET_REQ (0x08)
				instr_converter_en = 'b1;
				instruction = UPDI_STCS;
				instr_cs_addr = 'h8;

				instr_data[0] = 'h59;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;

				// also, start the delay
				delay_start = 'b1;
			end

			UPDI_PROG_UNLOCK_CHIPERASE_RESET_DEVICE_CLEAR: begin
				// clear ASI_RESET_REQ (0x08)
				instr_converter_en = 'b1;
				instruction = UPDI_STCS;
				instr_cs_addr = 'h8;

				instr_data[0] = 'h00;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ: begin
				// read ASI_SYS_STATUS (0x0B)
				instr_converter_en = 'b1;
				instruction = UPDI_LDCS;
				instr_cs_addr = 'hB;

				interface_tx_start = 'b1;

				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_UNLOCK_CHIPERASE_WAIT_FINISH_READ_VERIFY: begin
				// check if bit 1 is 0
				if (out_rx_fifo_data_in[0] == 'b0) begin
					valid = 'b1;
				end

				// if it's not, start the delay
				if (!valid) begin
					delay_start = 'b1;
				end
			end

			UPDI_PROG_UNLOCK_NVMPROG_SEND_KEY: begin
				instr_converter_en = 'b1;
				instruction = UPDI_KEY;

				load_key(`KEY_NVMPROG, instr_data[0:7]);
				instr_data_len = 'd8;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS: begin
				// send instruction to read ASI_KEY_STATUS register (0x07)
				instr_converter_en = 'b1;
				instruction = UPDI_LDCS;
				instr_cs_addr = 'h7;

				interface_tx_start = 'b1;

				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_NVMPROG_READ_STATUS_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_UNLOCK_NVMPROG_VERIFY_STATUS: begin
				// make sure bit 4 is 1
				if (out_rx_fifo_data_out[4] == 'b1) begin
					valid = 'b1;
				end

				if (!valid) $error();
			end

			UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_START: begin
				// store the system reset signature (0x59) into ASI_RESET_REQ (0x08)
				instr_converter_en = 'b1;
				instruction = UPDI_STCS;
				instr_cs_addr = 'h8;

				instr_data[0] = 'h59;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;

				// also, start the delay
				delay_start = 'b1;
			end

			UPDI_PROG_UNLOCK_NVMPROG_RESET_DEVICE_CLEAR: begin
				// clear ASI_RESET_REQ (0x08)
				instr_converter_en = 'b1;
				instruction = UPDI_STCS;
				instr_cs_addr = 'h8;

				instr_data[0] = 'h00;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ: begin
				// read ASI_SYS_STATUS (0x0B)
				instr_converter_en = 'b1;
				instruction = UPDI_LDCS;
				instr_cs_addr = 'hB;

				interface_tx_start = 'b1;
				
				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_UNLOCK_NVMPROG_WAIT_FINISH_READ_VERIFY: begin
				// check if bit 3 is 1
				if (out_rx_fifo_data_in[3] == 'b1) begin
					valid = 'b1;
				end

				// if it's not, start the delay
				if (!valid) begin
					delay_start = 'b1;
				end
			end
			
			UPDI_PROG_READ_DEVICE_ID_SET_RD_PTR: begin
				// set the read pointer to 0x1100 (signatures base address)
				instr_converter_en = 'b1;
				instruction = UPDI_ST;
				instr_ptr = 'b10;
				instr_size_a = 'b01;

				instr_data[0] = 'h00;
				instr_data[1] = 'h11;
				instr_data_len = 'd2;

				instr_wait_ack_after[1] = 'b1;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_READ_DEVICE_ID_SET_REPEAT: begin
				// want to repeat 2 times to read 3 bytes
				instr_converter_en = 'b1;
				instruction = UPDI_REPEAT;

				instr_data[0] = 'd2;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_READ_DEVICE_ID_READ: begin
				// send LD command to load from (*ptr++)
				instr_converter_en = 'b1;
				instruction = UPDI_LD;
				instr_ptr = 'b01;
				instr_size_a = 'b00;

				interface_tx_start = 'b1;
				
				// init data read of 3 byte
				interface_rx_n_bytes = 'd3;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_READ_DEVICE_ID_READ_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (interface_rx_ready) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE0: begin
				// fill byte 0
				device_id[0] = out_rx_fifo_data_out;
				out_rx_fifo_rd_en = 'b1;
			end

			UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE1: begin
				// fill byte 1
				device_id[1] = out_rx_fifo_data_out;
				out_rx_fifo_rd_en = 'b1;
			end

			UPDI_PROG_READ_DEVICE_ID_GET_ID_BYTE2: begin
				// fill byte 2
				device_id[2] = out_rx_fifo_data_out;
				$display("Device ID: %06X", { device_id[0], device_id[1], device_id[2] });
			end

			UPDI_PROG_PROGRAM_ROM_DECODER_START_SEGMENT: begin
				program_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_DECODER_VERIFY_SEGMENT: begin
				if (program_block_type == 'b0) begin
					valid = 'b1;
				end
			end

			UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ: begin
				// LDS from 0x1002 (NVM STATUS register)
				instr_converter_en = 'b1;
				instruction = UPDI_LDS;
				instr_size_a = 'b01; // word address
				instr_size_b = 'b00; // byte data

				instr_data[0] = 'h02;
				instr_data[1] = 'h10;
				instr_data_len = 'd2;

				interface_tx_start = 'b1;

				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_PROGRAM_ROM_NVM_CLEAR_WAIT_READY_READ_VERIFY: begin
				// check if bit 1 is 0
				if (out_rx_fifo_data_out[1] == 'b0) begin
					valid = 'b1;
				end
			end

			UPDI_PROG_PROGRAM_ROM_NVM_CLEAR: begin
				// clear write buffer by writing PBC opcode (0x04) to the NVM
				// CTRLA register (addr 0x1000)
				instr_converter_en = 'b1;
				instruction = UPDI_STS;
				instr_size_a = 'b01; // word address
				instr_size_b = 'b00; // byte data

				instr_data[0] = 'h00;
				instr_data[1] = 'h10;
				instr_data[2] = 'h04;
				instr_data_len = 'd3;
				instr_wait_ack_after[1] = 'b1;

				interface_tx_start = 'b1;
			end
			
			UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ: begin
				// LDS from 0x1002 (NVM STATUS register)
				instr_converter_en = 'b1;
				instruction = UPDI_LDS;
				instr_size_a = 'b01; // word address
				instr_size_b = 'b00; // byte data

				instr_data[0] = 'h02;
				instr_data[1] = 'h10;
				instr_data_len = 'd2;

				interface_tx_start = 'b1;

				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_WAIT_DONE: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_PROGRAM_ROM_NVM_WAIT_READY_READ_VERIFY: begin
				// check if bit 1 is 0
				if (out_rx_fifo_data_out[1] == 'b0) begin
					valid = 'b1;
				end
			end

			UPDI_PROG_PROGRAM_ROM_SET_WR_PTR: begin
				// set the write pointer by using ST
				instr_converter_en = 'b1;
				instruction = UPDI_ST;
				instr_ptr = 'b10; // writing to the pointer value
				instr_size_a = 'b01; // word address

				instr_data[0] = program_block_address[7:0];
				instr_data[1] = program_block_address[15:8];
				instr_data_len = 'd2;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_SET_REPEAT: begin
				// use REPEAT to write multiple bytes
				instr_converter_en = 'b1;
				instruction = UPDI_REPEAT;

				// n/2 - 1 repeats = n/2 words written = n bytes written (rounded up)
				instr_data[0] = (program_block_length >> 1) - 'b1;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_WRITE_DATA: begin
				// use ST to write all bytes
				instr_converter_en = 'b1;
				instruction = UPDI_ST;
				instr_ptr = 'b01; // *(ptr++)
				instr_size_a = 'b01; // write as words

				/*
				// swap endianness for all words
				for (integer i = 0; i < 64; i = i + 2) begin
					instr_data[i] = program_block_data[i + 1];
					instr_data[i + 1] = program_block_data[i];
				end
				*/

				instr_data = program_block_data;
				instr_data_len = program_block_length[DATA_ADDR_BITS:0];

				// since the values written are words, wait for ACK after
				// every second byte, starting at byte 2 (index 1)
				for (integer i = 1; i < program_block_length; i = i + 2) begin
					instr_wait_ack_after[i] = 'b1;
				end

				interface_tx_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_WRITE_PAGE_BUFFER: begin
				// write the page buffer to flash by writing the WP opcode
				// (0x1) to the NVM CTRLA register (0x1000)
				instr_converter_en = 'b1;
				instruction = UPDI_STS;
				instr_size_a = 'b01; // word address
				instr_size_b = 'b00; // byte data

				instr_data[0] = 'h00;
				instr_data[1] = 'h10;
				instr_data[2] = 'h01;
				instr_data_len = 'd3;
				instr_wait_ack_after[1] = 'b1;

				interface_tx_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_START: begin
				// store the system reset signature (0x59) into ASI_RESET_REQ (0x08)
				instr_converter_en = 'b1;
				instruction = UPDI_STCS;
				instr_cs_addr = 'h8;

				instr_data[0] = 'h59;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;

				// also, start the delay
				delay_start = 'b1;
			end

			UPDI_PROG_PROGRAM_ROM_RESET_DEVICE_CLEAR: begin
				// clear ASI_RESET_REQ (0x08)
				instr_converter_en = 'b1;
				instruction = UPDI_STCS;
				instr_cs_addr = 'h8;

				instr_data[0] = 'h00;
				instr_data_len = 'd1;

				interface_tx_start = 'b1;
			end
			
			UPDI_PROG_VERIFY_ROM: begin

			end
		endcase
	end

	always_latch begin
		// to keep instr_data_len, and instr_wait_ack_after in // 1 extra bit
		// for sending the whole buffer
		// sync with opcode updates
		if (instr_converter_en) begin
			latched_instr_data_len = instr_data_len;
			latched_instr_wait_ack_after = instr_wait_ack_after;
		end
	end

endmodule
