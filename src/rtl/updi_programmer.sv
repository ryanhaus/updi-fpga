// Possible states of the UPDI programmer.
typedef enum {
	UPDI_PROG_IDLE,

	UPDI_PROG_RESET_UPDI_DB_START,
	UPDI_PROG_RESET_UPDI_DB_WAIT,

	UPDI_PROG_READ_UPDI_STATUS_WR_INSTR,
	UPDI_PROG_READ_UPDI_STATUS_READ_DATA,
	UPDI_PROG_READ_UPDI_STATUS_WAIT_DATA,
	UPDI_PROG_READ_UPDI_STATUS_VERIFY,

	UPDI_PROG_RESET_CHIP,
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
	parameter ROM_ADDR_BITS = $clog2(ROM_SIZE),
	parameter ROM_DATA_BITS = 8,

	parameter MAX_INSTRUCTION_DATA_SIZE = 64,
	parameter DATA_ADDR_BITS = $clog2(MAX_INSTRUCTION_DATA_SIZE),
	
	parameter DATA_BLOCK_MAX_SIZE = 2 ** (DATA_ADDR_BITS + 1),

	parameter RX_OUT_FIFO_DEPTH = 16
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
	logic [DATA_ADDR_BITS-1 : 0] instr_data_len;
	logic [MAX_INSTRUCTION_DATA_SIZE-1 : 0] instr_wait_ack_after;

	logic interface_tx_start, interface_tx_ready;
	logic interface_rx_start, interface_rx_ready, interface_rx_done, interface_ack_error;
	logic [DATA_ADDR_BITS-1 : 0] interface_rx_n_bytes;

	logic [7:0] out_rx_fifo_data_in;
	logic out_rx_fifo_wr_en, out_rx_fifo_full;

	// RX out FIFO signals
	logic [7:0] out_rx_fifo_data_out;
	logic out_rx_fifo_rd_en, out_rx_fifo_empty;

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
		.data_len(instr_data_len),
		.wait_ack_after(instr_wait_ack_after),
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

	// State machine
	updi_programmer_state state;
	logic [7:0] counter;

	always_ff @(posedge clk) begin
		if (rst) begin
			state <= UPDI_PROG_IDLE;
			counter <= 'b0;
		end
		else begin
			case (state)
				UPDI_PROG_IDLE: begin
					// wait for start signal
					if (start) begin
						counter <= 'b0;
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
						state <= UPDI_PROG_READ_UPDI_STATUS_WR_INSTR;
					end
				end
				
				UPDI_PROG_READ_UPDI_STATUS_WR_INSTR: begin
					// write instruction for 1 clock cycle, then wait for data
					state <= UPDI_PROG_READ_UPDI_STATUS_READ_DATA;
				end

				UPDI_PROG_READ_UPDI_STATUS_READ_DATA: begin
					if (interface_rx_ready) begin
						state <= UPDI_PROG_READ_UPDI_STATUS_WAIT_DATA;
					end
				end

				UPDI_PROG_READ_UPDI_STATUS_WAIT_DATA: begin
					if (interface_rx_done) begin
						state <= UPDI_PROG_READ_UPDI_STATUS_VERIFY;
					end
				end

				UPDI_PROG_READ_UPDI_STATUS_VERIFY: begin

				end
				
				UPDI_PROG_RESET_CHIP: begin
				
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
		// instr_data = '{default: 'b0};
		// instr_data_len = 'b0;
		// instr_wait_ack_after = 'b0;

		interface_rx_start = 'b0;
		interface_tx_start = 'b0;
		out_rx_fifo_rd_en = 'b0;
		
		case (state)
			UPDI_PROG_IDLE: begin
				busy = 'b0;
			end

			UPDI_PROG_RESET_UPDI_DB_START: begin
				double_break_start = 'b1;
			end

			UPDI_PROG_RESET_UPDI_DB_WAIT: begin
				// do nothing
			end

			UPDI_PROG_READ_UPDI_STATUS_WR_INSTR: begin
				// send instruction to read STATUSA register (0x00)
				instr_converter_en = 'b1;
				instruction = UPDI_LDCS;
				instr_data[0] = 'h00;
				instr_data_len = 'd1;
				interface_tx_start = 'b1;
			end

			UPDI_PROG_READ_UPDI_STATUS_READ_DATA: begin
				// init data read of 1 byte
				interface_rx_n_bytes = 'd1;
				interface_rx_start = 'b1;
			end

			UPDI_PROG_READ_UPDI_STATUS_WAIT_DATA: begin
				// if there is data in the FIFO, try to read it next clk cycle
				if (!out_rx_fifo_empty) begin
					out_rx_fifo_rd_en = 'b1;
				end
			end

			UPDI_PROG_READ_UPDI_STATUS_VERIFY: begin
				// make sure status != 0x00
				if (out_rx_fifo_data_out == 'h00) begin
					// TODO: make synthesizable
					$error();
				end
			end

			UPDI_PROG_RESET_CHIP: begin
				
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
