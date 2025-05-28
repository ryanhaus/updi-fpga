// Testbench for uart module
module tb_uart();

	logic clk, rst, tx, rx, transmit_start, transmit_ready, rx_data_valid;
	logic [dut.DATA_BITS-1 : 0] tx_data, rx_data;
	uart #(.DATA_BITS(8), .PARITY_BIT("none"), .STOP_BITS(2)) dut (clk, rst, tx_data, transmit_start, transmit_ready, tx, rx_data, rx_data_valid, rx);

	logic [10:0] tx_buffer;
	integer i;

	// reverse tx_data bit order for verification
	wire [dut.DATA_BITS-1 : 0] tx_data_rev;
	genvar n;

	generate
		for (n = 0; n < dut.DATA_BITS; n = n + 1) begin
			assign tx_data_rev[n] = tx_data[dut.DATA_BITS - (n+1)];
		end
	endgenerate

	initial begin
		$dumpfile("trace/tb_uart.vcd");
		$dumpvars();

		#10
		clk = 'b0;
		rst = 'b1;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		rst = 'b0;

		// test transfers
		// transmit values from 0x00 to 0xFF, verify results
		// parity is tested separately in tb_parity
		for (i = 0; i < 255; i = i + 1) begin
			tx_data = i[7:0];
			transmit_start = 'b1;

			do begin
				#10 clk = 'b1;
				#10 clk = 'b0;

				transmit_start = 'b0;

				tx_buffer = tx_buffer << 1;
				tx_buffer[0] = tx;
			end while (!transmit_ready);

			if (tx_buffer != { 1'b0, tx_data_rev, 2'b11 }) $error();
		end

		// test receives
		// TODO

		$finish;
	end

endmodule
