// All possible states for updi_instruction_queue_handler
typedef enum {
	UPDI_INSTR_HDLR_IDLE,
	UPDI_INSTR_HDLR_WR_SYNCH,
	UPDI_INSTR_HDLR_WR_OPCODE,
	UPDI_INSTR_HDLR_WR_DATA,
	UPDI_INSTR_HDLR_WAIT_ACK
} updi_instruction_queue_handler_state;

// Takes in instruction requests and writes out individual bytes representing
// the instructions to an external FIFO. Also handles waiting for ACK signals
module updi_instruction_queue_handler #(
	parameter MAX_DATA_SIZE = 16,
	parameter DATA_ADDR_BITS = $clog2(MAX_DATA_SIZE)
) (
	input clk,
	input rst,

	// control signals
	input start,
	output logic ready,
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

	// state machine
	updi_instruction_queue_handler_state state;
	logic [DATA_ADDR_BITS : 0] counter;

	always_ff @(posedge clk) begin
		fifo_wr_en <= 'b0;
		waiting_for_ack <= 'b0;

		if (rst) begin
			state <= UPDI_INSTR_HDLR_IDLE;
			ready <= 'b0;
			fifo_data <= 'b0;
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
						fifo_data <= 'h55;
						fifo_wr_en <= 'b1;
						state <= UPDI_INSTR_HDLR_WR_OPCODE;
					end
				end

				UPDI_INSTR_HDLR_WR_OPCODE: begin
					// push opcode to FIFO if possible
					if (!fifo_full) begin
						fifo_data <= opcode;
						fifo_wr_en <= 'b1;

						// if there is data, write that, otherwise idle
						if (data_len > 'b0) begin
							counter <= 'b0;
							state <= UPDI_INSTR_HDLR_WR_DATA;
						end
						else begin
							state <= UPDI_INSTR_HDLR_IDLE;
						end
					end
				end

				UPDI_INSTR_HDLR_WR_DATA: begin
					if (!fifo_full) begin
						// continually push data to FIFO if possible
						fifo_data <= data[counter[DATA_ADDR_BITS-1 : 0]];
						fifo_wr_en <= 'b1;

						// if done writing data, go back to idle, otherwise
						// keep going
						if (wait_ack_after[counter[DATA_ADDR_BITS-1 : 0]] == 'b1 && !ack_received) begin
							state <= UPDI_INSTR_HDLR_WAIT_ACK;
						end
						else if (counter == data_len - 'b1) begin
							state <= UPDI_INSTR_HDLR_IDLE;
						end
						else begin
							counter <= counter + 'b1;
						end
					end
				end

				UPDI_INSTR_HDLR_WAIT_ACK: begin
					// wait for ack signal in between data bytes
					if (ack_received) begin
						waiting_for_ack <= 'b0;
							
						if (counter == data_len - 'b1) begin
							state <= UPDI_INSTR_HDLR_IDLE;
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

endmodule
