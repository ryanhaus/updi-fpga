// testbench for updi_instruction_queue_handler
module tb_updi_instruction_queue_handler();

	parameter MAX_DATA_SIZE = 16;
	parameter DATA_ADDR_BITS = $clog2(MAX_DATA_SIZE);

	// signals
	logic clk, rst, start, ready, waiting_for_ack, ack_received, fifo_wr_en, fifo_full;
	logic [7:0] opcode, fifo_data;
	logic [7:0] data [MAX_DATA_SIZE];
	logic [DATA_ADDR_BITS-1 : 0] data_len;
	logic [MAX_DATA_SIZE-1 : 0] wait_ack_after;
	logic [7:0] fifo_out;
	logic fifo_rd_en, fifo_empty;

	// fifo on negedge
	fifo #(.DEPTH(4)) fifo_inst (
		~clk, rst,
		fifo_data, fifo_out,
		fifo_rd_en, fifo_wr_en,
		fifo_empty, fifo_full
	);

	// dut on posedge
	updi_instruction_queue_handler #( 
		.MAX_DATA_SIZE(MAX_DATA_SIZE),
		.DATA_ADDR_BITS(DATA_ADDR_BITS)
	) dut (
		clk, rst,
		start, ready, waiting_for_ack, ack_received,
		opcode, data, data_len, wait_ack_after,
		fifo_data, fifo_wr_en, fifo_full
	);

	integer i;

	initial begin
		$dumpfile("trace/tb_updi_instruction_queue_handler.vcd");
		$dumpvars();

		// reset
		clk = 'b0;
		rst = 'b1;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		rst = 'b0;

		#10 clk = 'b1;
		#10 clk = 'b0;

		// send test instruction w/o data
		if (!ready) $error();
		opcode = 'b11100101; // instruction to get 16-byte SIB
		data = '{default: 'b0};
		data_len = 'b0;
		wait_ack_after = 'b0;
		start = 'b1;

		#10 clk = 'b1;
		#10 clk = 'b0;
		start = 'b0;

		while (!ready) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// verify only SYNCH and the opcode was written to the FIFO
		#10 clk = 'b1;

		i = 0;
		fifo_rd_en = 'b1;

		while (!fifo_empty) begin
			#10 clk = 'b0;
			#10 clk = 'b1;

			case (i)
				0: if (fifo_out != 'h55) $error();
				1: if (fifo_out != 'b11100101) $error();
				default: $error();
			endcase

			i = i + 1;
		end

		fifo_rd_en = 'b0;
		#10 clk = 'b0;

		// write a command with some data that will fill the FIFO, make sure
		// it stops properly & continues after to keep pushing data, as well
		// as ensure it waits for ACK when necessary
		if (!ready) $error();

		opcode = 'b01000101;

		data = '{default: 'b0};
		data[0] = 'h12;
		data[1] = 'h34;
		data[2] = 'h56;
		data[3] = 'h78;

		data_len = 'd4;

		wait_ack_after = 'b0;
		wait_ack_after[1] = 'b1;
		wait_ack_after[3] = 'b1;
		
		start = 'b1;

		#10 clk = 'b1;
		#10 clk = 'b0;

		start = 'b0;

		// make sure it waits while FIFO is full
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// flush FIFO and verify data
		#10 clk = 'b1;

		i = 0;
		fifo_rd_en = 'b1;

		while (!fifo_empty) begin
			#10 clk = 'b0;
			#10 clk = 'b1;

			case (i)
				0: if (fifo_out != 'h55) $error();
				1: if (fifo_out != 'h45) $error();
				2: if (fifo_out != 'h12) $error();
				3: if (fifo_out != 'h34) $error(); // this byte gets written as FIFO is read from
				default: $error();
			endcase

			i = i + 1;
		end

		fifo_rd_en = 'b0;
		#10 clk = 'b0;

		// make sure ACK is waited for
		for (i = 0; i < 5; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		do begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end while (!waiting_for_ack);

		for (i = 0; i < 5; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		ack_received = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		ack_received = 'b0;

		// allow rest of writes to occur
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end
		
		// flush FIFO and verify data
		#10 clk = 'b1;

		i = 0;
		fifo_rd_en = 'b1;

		while (!fifo_empty) begin
			#10 clk = 'b0;
			#10 clk = 'b1;

			case (i)
				0: if (fifo_out != 'h56) $error();
				1: if (fifo_out != 'h78) $error();
				default: $error();
			endcase

			i = i + 1;
		end

		fifo_rd_en = 'b0;
		#10 clk = 'b0;

		// make sure it is still waiting for last ACK
		if (ready) $error();

		ack_received = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		ack_received = 'b0;

		#10 clk = 'b1;
		#10 clk = 'b0;

		if (!ready) $error();

		$finish;
	end

endmodule
