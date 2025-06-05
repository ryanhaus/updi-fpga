module tb_uart_fifo();

  	parameter DATA_BITS = 8;
  	parameter PARITY_BIT = "even";
  	parameter STOP_BITS = 2;
  	parameter FIFO_DEPTH = 16;

  	logic uart_clk, clk, rst;
  	logic [DATA_BITS-1 : 0] tx_data, rx_data;
  	logic tx_fifo_wr_en, rx_fifo_rd_en;
  	logic tx_fifo_full, tx_fifo_empty;
  	logic rx_fifo_full, rx_fifo_empty;
  	logic rx_error, uart_busy;
  	logic tx;

  	uart_fifo #(DATA_BITS, PARITY_BIT, STOP_BITS, FIFO_DEPTH) dut (
  	  .clk(clk),
  	  .uart_clk(uart_clk),
  	  .rst(rst),
  	  .tx_data(tx_data),
  	  .rx_data(rx_data),
  	  .tx_fifo_wr_en(tx_fifo_wr_en),
  	  .rx_fifo_rd_en(rx_fifo_rd_en),
  	  .tx_fifo_full(tx_fifo_full),
  	  .tx_fifo_empty(tx_fifo_empty),
  	  .rx_fifo_full(rx_fifo_full),
  	  .rx_fifo_empty(rx_fifo_empty),
  	  .rx_error(rx_error),
	  .uart_busy(uart_busy),
  	  .tx(tx),
  	  .rx(tx) // note: loopback configuration for testing
  	);

  	integer i;

  	initial begin
		// make uart clk 1/10th logic clk
		uart_clk = 'b0;
		forever #100 uart_clk = ~uart_clk;
	end

	initial begin
		clk = 'b0;
		forever #10 clk = ~clk;
	end

	initial begin
    	$dumpfile("trace/tb_uart_fifo.fst");
    	$dumpvars();


		// reset
		tx_data = 'b0;
		tx_fifo_wr_en = 'b0;
		rx_fifo_rd_en = 'b0;
		rst = 'b1;

		#200
		rst = 'b0;

		// test UART FIFO with a loopback, write to FIFO first
		tx_fifo_wr_en = 'b1;

		for (i = 0; i < FIFO_DEPTH - 1; i = i + 1) begin
			tx_data = i[DATA_BITS-1 : 0];

			#20 clk=clk;
		end

		tx_fifo_wr_en = 'b0;

		// wait for all writes to be done
		while (!tx_fifo_empty || uart_busy) begin
			#20 clk=clk;
		end

		// verify that values read from FIFO match what is expected
		rx_fifo_rd_en = 'b1;
		for (i = 0; i < FIFO_DEPTH - 1; i = i + 1) begin
			#20
			if (rx_data != i[DATA_BITS-1 : 0]) $error();
		end

		$finish;
  	end

endmodule
