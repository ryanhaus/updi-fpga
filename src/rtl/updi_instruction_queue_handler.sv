// All possible states for updi_instruction_queue_handler
typedef enum {
	UPDI_INSTR_HDLR_IDLE,
	UPDI_INSTR_HDLR_WR_SYNCH,
	UPDI_INSTR_HDLR_WR_OPCODE,
	UPDI_INSTR_HDLR_WR_DATA,
	UPDI_INSTR_HDLR_DELAY_START,
	UPDI_INSTR_HDLR_DELAY,
	UPDI_INSTR_HDLR_WAIT_ACK
} updi_instruction_queue_handler_state;

// Takes in instruction requests and writes out individual bytes representing
// the instructions to an external FIFO. Also handles waiting for ACK signals
module updi_instruction_queue_handler #(
	parameter MAX_DATA_SIZE = 16,
	parameter DATA_ADDR_BITS = $clog2(MAX_DATA_SIZE),
	parameter POST_WRITE_DELAY_CLKS = 1000
) (
	input clk,
	input rst,

	// control signals
	input start,
	output logic ready,
	output logic done,
	output logic waiting_for_ack,
	input ack_received,
	
	// instruction inputs
	input [7:0] opcode, // see updi_instruction_converter
	input [7:0] data [MAX_DATA_SIZE],
	input [DATA_ADDR_BITS : 0] data_len, // 1 extra bit to account for sending the full buffer
	input [MAX_DATA_SIZE-1 : 0] wait_ack_after, // which bytes to wait for ACK after writing

	// FIFO interface
	output logic [7:0] fifo_data,
	output logic fifo_wr_en,
	input fifo_full
);

	// delay module for post-command delays
	logic post_write_delay_start, post_write_delay_done;

	delay #(.N_CLKS(POST_WRITE_DELAY_CLKS)) post_write_delay_inst (
		.clk(clk),
		.rst(rst),
		.start(post_write_delay_start),
		.active(),
		.done(post_write_delay_done)
	);

	// state machine
	updi_instruction_queue_handler_state state;
	logic [DATA_ADDR_BITS : 0] counter;

	always_ff @(posedge clk) begin
		waiting_for_ack <= 'b0;
		done <= 'b0;

		if (rst) begin
			state <= UPDI_INSTR_HDLR_IDLE;
			ready <= 'b0;
		end
		else begin
			case (state)
				UPDI_INSTR_HDLR_IDLE: begin
					// remain idle until start flag
					if (start) begin
						ready <= 'b0;
						state <= UPDI_INSTR_HDLR_WR_SYNCH;
					end
					else begin
						ready <= 'b1;
					end
				end
				
				UPDI_INSTR_HDLR_WR_SYNCH: begin
					// send SYNCH character (0x55)
					if (!fifo_full) begin
						state <= UPDI_INSTR_HDLR_WR_OPCODE;
					end
				end

				UPDI_INSTR_HDLR_WR_OPCODE: begin
					// push opcode to FIFO if possible
					if (!fifo_full) begin
						// if there is data, write that, otherwise idle
						if (data_len > 'b0) begin
							counter <= 'b0;
							state <= UPDI_INSTR_HDLR_WR_DATA;
						end
						else begin
							state <= UPDI_INSTR_HDLR_IDLE;
							done <= 'b1;
						end
					end
				end

				UPDI_INSTR_HDLR_WR_DATA: begin
					if (!fifo_full) begin
						// if done writing data, go back to idle, otherwise
						// keep going
						if (wait_ack_after[counter[DATA_ADDR_BITS-1 : 0]] == 'b1 && !ack_received) begin
							state <= UPDI_INSTR_HDLR_WAIT_ACK;
						end
						else if (counter == data_len - 'b1) begin
							state <= UPDI_INSTR_HDLR_DELAY_START;
						end
						else begin
							counter <= counter + 'b1;
						end
					end
				end

				UPDI_INSTR_HDLR_DELAY_START: begin
					state <= UPDI_INSTR_HDLR_DELAY;
				end

				UPDI_INSTR_HDLR_DELAY: begin
					if (post_write_delay_done) begin
						done <= 'b1;
						state <= UPDI_INSTR_HDLR_IDLE;
					end
				end

				UPDI_INSTR_HDLR_WAIT_ACK: begin
					// wait for ack signal in between data bytes
					if (ack_received) begin
						waiting_for_ack <= 'b0;
							
						if (counter == data_len - 'b1) begin
							state <= UPDI_INSTR_HDLR_IDLE;
							done <= 'b1;
						end
						else begin
							counter <= counter + 'b1;
							state <= UPDI_INSTR_HDLR_WR_DATA;
						end
					end
					else begin
						waiting_for_ack <= 'b1;
					end
				end
			endcase
		end
	end

	logic [DATA_ADDR_BITS-1 : 0] index = counter[DATA_ADDR_BITS-1 : 0];

	always_comb begin
		fifo_data = 'b0;
		fifo_wr_en = 'b0;
		post_write_delay_start = 'b0;

		case (state)
			UPDI_INSTR_HDLR_WR_SYNCH: begin
				fifo_data = 'h55;
				fifo_wr_en = 'b1;
			end

			UPDI_INSTR_HDLR_WR_OPCODE: begin
				fifo_data = opcode;
				fifo_wr_en = 'b1;
			end

			UPDI_INSTR_HDLR_WR_DATA: begin
				fifo_data = data[index];
				fifo_wr_en = 'b1;
			end

			UPDI_INSTR_HDLR_DELAY_START: begin
				post_write_delay_start = 'b1;
			end
		endcase
	end

endmodule
