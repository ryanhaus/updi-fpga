// testbench for updi_interface
module tb_updi_interface();

	parameter MAX_DATA_SIZE = 64;
	parameter DATA_ADDR_BITS = $clog2(MAX_DATA_SIZE);
	parameter FIFO_DEPTH = 64;

	// updi_interface instance
	logic clk, rst, sib, tx_start, tx_ready, tx_done, rx_start, rx_ready, rx_done, rx_timeout, ack_error,
		out_rx_fifo_wr_en, out_rx_fifo_full, uart_rx_fifo_rd_en, uart_rx_fifo_empty,
		uart_tx_fifo_wr_en, uart_tx_fifo_full;
	logic [1:0] size_a, size_b, ptr, size_c;
	logic [3:0] cs_addr;
	logic [7:0] out_rx_fifo_data, uart_rx_fifo_data, uart_tx_fifo_data;
	logic [DATA_ADDR_BITS : 0] data_len;
	logic [DATA_ADDR_BITS-1 : 0] rx_n_bytes;
	logic [MAX_DATA_SIZE-1 : 0] wait_ack_after;
	logic [7:0] data [MAX_DATA_SIZE];
	updi_instruction instruction;

	updi_interface #(
		.MAX_DATA_SIZE(MAX_DATA_SIZE),
		.DATA_ADDR_BITS(DATA_ADDR_BITS)
	) dut (
		.clk(clk),
		.rst(rst),
		.instr_converter_en('b1),
		.instruction(instruction),
		.size_a(size_a),
		.size_b(size_b),
		.ptr(ptr),
		.cs_addr(cs_addr),
		.sib(sib),
		.size_c(size_c),
		.data(data),
		.data_len(data_len),
		.wait_ack_after(wait_ack_after),
		.tx_start(tx_start),
		.tx_ready(tx_ready),
		.tx_done(tx_done),
		.rx_n_bytes(rx_n_bytes),
		.rx_start(rx_start),
		.rx_ready(rx_ready),
		.rx_done(rx_done),
		.rx_timeout(rx_timeout),
		.ack_error(ack_error),
		.out_rx_fifo_data(out_rx_fifo_data),
		.out_rx_fifo_wr_en(out_rx_fifo_wr_en),
		.out_rx_fifo_full(out_rx_fifo_full),
		.uart_rx_fifo_data(uart_rx_fifo_data),
		.uart_rx_fifo_rd_en(uart_rx_fifo_rd_en),
		.uart_rx_fifo_empty(uart_rx_fifo_empty),
		.uart_tx_fifo_data(uart_tx_fifo_data),
		.uart_tx_fifo_wr_en(uart_tx_fifo_wr_en),
		.uart_tx_fifo_full(uart_tx_fifo_full)
	);

	// fifo instance (for TX output)
	logic [7:0] tx_out_fifo_data;
	logic tx_out_fifo_rd_en, tx_out_fifo_empty;

	fifo #(.DEPTH(FIFO_DEPTH)) tx_out_fifo (
		.clk(clk),
		.rst(rst),
		.in(uart_tx_fifo_data),
		.out(tx_out_fifo_data),
		.rd_en(tx_out_fifo_rd_en),
		.wr_en(uart_tx_fifo_wr_en),
		.empty(tx_out_fifo_empty),
		.almost_empty(),
		.full(uart_tx_fifo_full),
		.almost_full()
	);
	
	// fifo instance (for RX input)
	logic [7:0] rx_in_fifo_data;
	logic rx_in_fifo_wr_en, rx_in_fifo_full;

	fifo #(.DEPTH(FIFO_DEPTH)) rx_in_fifo (
		.clk(clk),
		.rst(rst),
		.in(rx_in_fifo_data),
		.out(uart_rx_fifo_data),
		.rd_en(uart_rx_fifo_rd_en),
		.wr_en(rx_in_fifo_wr_en),
		.empty(uart_rx_fifo_empty),
		.almost_empty(),
		.full(rx_in_fifo_full),
		.almost_full()
	);

	// fifo instance (for RX output)
	logic [7:0] rx_out_fifo_data;
	logic rx_out_fifo_rd_en, rx_out_fifo_empty;
	fifo #(.DEPTH(FIFO_DEPTH)) rx_out_fifo (
		.clk(clk),
		.rst(rst),
		.in(out_rx_fifo_data),
		.out(rx_out_fifo_data),
		.rd_en(rx_out_fifo_rd_en),
		.wr_en(out_rx_fifo_wr_en),
		.empty(rx_out_fifo_empty),
		.almost_empty(),
		.full(out_rx_fifo_full),
		.almost_full()
	);

	// testbench logic
	integer i;

	initial #10000 $error();
	initial begin
		$dumpfile("trace/tb_updi_interface.fst");
		$dumpvars();

		// reset
		rst = 'b1;
		clk = 'b0;

		#10 clk = 'b1;
		#10 clk = 'b0;
		rst = 'b0;
		#10 clk = 'b1;
		#10 clk = 'b0;

		// send a test instruction with ACK and data expected
		instruction = UPDI_STS;
		size_a = 'b01;
		size_b = 'b01;

		data = '{default: 'b0};
		data[0] = 'h12;
		data[1] = 'h34;
		data[2] = 'h56;
		data[3] = 'h78;

		data_len = 'd4;
		
		wait_ack_after = 'b0;
		wait_ack_after[1] = 'b1;
		wait_ack_after[3] = 'b1;

		if (!tx_ready) $error();
		tx_start = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		tx_start = 'b0;

		// delay
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// write ACK to RX in FIFO
		#10 clk = 'b1;
		rx_in_fifo_data = 'h40;
		rx_in_fifo_wr_en = 'b1;
		#10 clk = 'b0;
		#10 clk = 'b1;
		rx_in_fifo_wr_en = 'b0;
		#10 clk = 'b0;

		// delay
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
			if (ack_error) $error();
		end

		if (tx_ready) $error(); // should still wait for last ACK

		// write second ACK to RX in FIFO
		#10 clk = 'b1;
		rx_in_fifo_data = 'h40;
		rx_in_fifo_wr_en = 'b1;
		#10 clk = 'b0;
		#10 clk = 'b1;
		rx_in_fifo_wr_en = 'b0;
		#10 clk = 'b0;

		while (!tx_ready) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
			if (ack_error) $error();
		end

		// verify TX out FIFO contents
		i = 0;
		tx_out_fifo_rd_en = 'b1;
		while (!tx_out_fifo_empty) begin
			#10 clk = 'b1;
			#10 clk = 'b0;

			case (i)
				0: if (tx_out_fifo_data != 'h55) $error();
				1: if (tx_out_fifo_data != 'h45) $error();
				2: if (tx_out_fifo_data != 'h12) $error();
				3: if (tx_out_fifo_data != 'h34) $error();
				4: if (tx_out_fifo_data != 'h56) $error();
				5: if (tx_out_fifo_data != 'h78) $error();
				default: $error();
			endcase

			i = i + 1;
		end

		tx_out_fifo_rd_en = 'b0;

		// send another instruction that expects to read data back
		instruction = UPDI_LDS;
		size_a = 'b01;
		size_b = 'b01;

		data = '{default: 'b0};
		data[0] = 'h12;
		data[1] = 'h34;

		data_len = 'd2;
		
		wait_ack_after = 'b0;

		if (!tx_ready) $error();
		tx_start = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		tx_start = 'b0;

		// delay
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// write some values to RX input FIFO
		rx_in_fifo_wr_en = 'b1;
		rx_in_fifo_data = 'h56;
		#10 clk = 'b1;
		#10 clk = 'b0;
		rx_in_fifo_data = 'h78;
		#10 clk = 'b1;
		#10 clk = 'b0;
		rx_in_fifo_wr_en = 'b0;

		// delay
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// read out 2 values
		if (!rx_ready) $error();
		rx_n_bytes = 'd2;
		rx_start = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		rx_start = 'b0;

		// delay
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// verify values in RX out FIFO
		i = 0;
		rx_out_fifo_rd_en = 'b1;

		while (!rx_out_fifo_empty) begin
			#10 clk = 'b1;
			#10 clk = 'b0;

			case (i)
				0: if (rx_out_fifo_data != 'h56) $error();
				1: if (rx_out_fifo_data != 'h78) $error();
				default: $error();
			endcase

			i = i + 1;
		end

		rx_out_fifo_rd_en = 'b0;

		$finish;
	end

endmodule
