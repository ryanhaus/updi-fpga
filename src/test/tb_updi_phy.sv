module tb_updi_phy();

	logic clk, rst, updi;

	// UPDI PHY instance
	logic [7:0] uart_tx_fifo_data, uart_rx_fifo_data;
	logic uart_tx_fifo_wr_en, uart_tx_fifo_full, uart_tx_fifo_almost_full,
		uart_rx_fifo_rd_en, uart_rx_fifo_empty, uart_rx_fifo_almost_empty, rx_error,
		double_break_start, double_break_busy, double_break_done;

	updi_phy #(
		.DOUBLE_BREAK_PULSE_CLK(250)
	) dut (
		clk, rst,
		uart_tx_fifo_data, uart_tx_fifo_wr_en, uart_tx_fifo_full, uart_tx_fifo_almost_full,
		uart_rx_fifo_data, uart_rx_fifo_rd_en, uart_rx_fifo_empty, uart_rx_fifo_almost_empty, rx_error,
		double_break_start, double_break_busy, double_break_done,
		updi
	);

	initial #100000 $error();
	int i;

	initial begin
		$dumpfile("trace/tb_updi_phy.fst");
		$dumpvars();

		// reset
		clk = 'b0;
		rst = 'b1;

		#10 clk = 'b1;
		#10 clk = 'b0;
		rst = 'b0;

		// test double break
		double_break_start = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		double_break_start = 'b0;

		i = 0;
		while (!double_break_done) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
			i = i + 1;
		end

		if (i != 1000) $error();

		// send test value
		uart_tx_fifo_data = 'h55;
		uart_tx_fifo_wr_en = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		uart_tx_fifo_wr_en = 'b0;

		#10 clk = 'b1;
		#10 clk = 'b0;

		while (dut.uart_tx_active) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		$finish;
	end

endmodule
