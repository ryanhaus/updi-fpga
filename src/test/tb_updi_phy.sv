module tb_updi_phy();

	logic clk, rst;

	// UPDI PHY instance 1
	logic [7:0] uart_tx_fifo_data1, uart_rx_fifo_data1;
	logic uart_tx_fifo_wr_en1, uart_tx_fifo_full1, uart_tx_fifo_almost_full1,
		uart_rx_fifo_rd_en1, uart_rx_fifo_empty1, uart_rx_fifo_almost_empty1, rx_error1,
		double_break_start1, double_break_busy1, double_break_done1,
		updi1;

	updi_phy #(
		.DOUBLE_BREAK_PULSE_CLK(250)
	) dut1 (
		clk, rst,
		uart_tx_fifo_data1, uart_tx_fifo_wr_en1, uart_tx_fifo_full1, uart_tx_fifo_almost_full1,
		uart_rx_fifo_data1, uart_rx_fifo_rd_en1, uart_rx_fifo_empty1, uart_rx_fifo_almost_empty1, rx_error1,
		double_break_start1, double_break_busy1, double_break_done1,
		updi1
	);

	// UPDI PHY instance 2
	logic [7:0] uart_tx_fifo_data2, uart_rx_fifo_data2;
	logic uart_tx_fifo_wr_en2, uart_tx_fifo_full2, uart_tx_fifo_almost_full2,
		uart_rx_fifo_rd_en2, uart_rx_fifo_empty2, uart_rx_fifo_almost_empty2, rx_error2,
		double_break_start2, double_break_busy2, double_break_done2,
		updi2;

	updi_phy #(
		.DOUBLE_BREAK_PULSE_CLK(250)
	) dut2 (
		clk, rst,
		uart_tx_fifo_data2, uart_tx_fifo_wr_en2, uart_tx_fifo_full2, uart_tx_fifo_almost_full2,
		uart_rx_fifo_data2, uart_rx_fifo_rd_en2, uart_rx_fifo_empty2, uart_rx_fifo_almost_empty2, rx_error2,
		double_break_start2, double_break_busy2, double_break_done2,
		updi2
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
		double_break_start1 = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		double_break_start1 = 'b0;

		i = 0;
		while (!double_break_done1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
			i = i + 1;
		end

		if (i != 1000) $error();

		// send test value
		uart_tx_fifo_data1 = 'h55;
		uart_tx_fifo_wr_en1 = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		uart_tx_fifo_wr_en1 = 'b0;

		#10 clk = 'b1;
		#10 clk = 'b0;

		while (dut1.uart_tx_active) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		$finish;
	end

endmodule
