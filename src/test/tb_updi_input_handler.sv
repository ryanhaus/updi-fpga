// testbench for updi_input_handler
module tb_updi_input_handler();

	parameter BITS_N = 6;

	// updi_input_handler instance (posedge)
	logic clk, rst, wait_ack, ack_received, ack_error, start, ready, in_fifo_empty, in_fifo_rd_en, out_fifo_full, out_fifo_wr_en;
	logic [7:0] in_fifo_data, out_fifo_data;
	logic [BITS_N-1 : 0] n_bytes;

	updi_input_handler #(.BITS_N(BITS_N)) dut (
		clk, rst,
		wait_ack, ack_received, ack_error,
		n_bytes, start, ready,
		in_fifo_data, in_fifo_empty, in_fifo_rd_en,
		out_fifo_data, out_fifo_full, out_fifo_wr_en
	);

	// input FIFO (negedge)
	logic [7:0] rx_data;
	logic rx_fifo_wr_en, rx_fifo_full;

	fifo input_fifo_inst (
		.clk(~clk),
		.rst(rst),
		.in(rx_data),
		.out(in_fifo_data),
		.rd_en(in_fifo_rd_en),
		.wr_en(rx_fifo_wr_en),
		.empty(in_fifo_empty),
		.full(rx_fifo_full)
	);

	// output FIFO (negedge)
	logic [7:0] tx_data;
	logic tx_fifo_rd_en, tx_fifo_empty;

	fifo output_fifo_inst (
		.clk(~clk),
		.rst(rst),
		.in(out_fifo_data),
		.out(tx_data),
		.rd_en(tx_fifo_rd_en),
		.wr_en(out_fifo_wr_en),
		.empty(tx_fifo_empty),
		.full(out_fifo_full)
	);

	// testbench logic
	integer i;

	initial begin
		$dumpfile("trace/tb_updi_input_handler.vcd");
		$dumpvars();

		// reset
		clk = 'b0;
		rst = 'b1;

		#10 clk = 'b1;
		#10	clk = 'b0;
		rst = 'b0;

		// write 11 values to the input FIFO, with an ACK after the first
		#10 clk = 'b1;
		rx_fifo_wr_en = 'b1;

		rx_data = 'hF0;
		#10 clk = 'b0;
		#10 clk = 'b1;

		rx_data = 'h40;
		#10 clk = 'b0;
		#10 clk = 'b1;

		for (i = 1; i < 10; i = i + 1) begin
			rx_data = { 4'hF, i[3:0] };

			#10 clk = 'b0;
			#10 clk = 'b1;
		end

		rx_fifo_wr_en = 'b0;

		// pass 1 value through
		if (!ready) $error();
		n_bytes = 'd1;
		start = 'b1;

		#10 clk = 'b0;
		#10 clk = 'b1;
		start = 'b0;

		while (!ready) begin
			#10 clk = 'b0;
			#10 clk = 'b1;
		end

		// read from FIFO, verify is what is expected
		tx_fifo_rd_en = 'b1;
		#10 clk = 'b0;
		#10 clk = 'b1;
		tx_fifo_rd_en = 'b0;

		if (tx_data != 'hF0) $error();

		// tell input handler to wait for an ACK
		#10 clk = 'b0;
		wait_ack = 'b1;
		
		#10 clk = 'b1;
		#10 clk = 'b0;

		wait_ack = 'b0;

		while (!ready) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		#10 clk = 'b1;

		if (!ack_received) $error();
		if (ack_error) $error();

		// pass remaining 9 values through
		if (!ready) $error();
		n_bytes = 'd9;
		start = 'b1;

		#10 clk = 'b0;
		#10 clk = 'b1;
		start = 'b0;

		while (!ready) begin
			#10 clk = 'b0;
			#10 clk = 'b1;
		end

		// read from FIFO, verify is what is expected
		tx_fifo_rd_en = 'b1;

		for (i = 1; i < 10; i = i + 1) begin
			#10 clk = 'b0;
			#10 clk = 'b1;

			if (tx_data != { 4'hF, i[3:0] }) $error();
		end

		tx_fifo_rd_en = 'b0;

		$finish;
	end

endmodule
