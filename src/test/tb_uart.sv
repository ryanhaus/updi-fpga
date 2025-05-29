// Testbench for uart module
module tb_uart();

	logic clk, rst, tx, rx, transmit_start, transmit_ready, rx_data_valid, rx_error;
	logic [dut.DATA_BITS-1 : 0] tx_data, rx_data;
	uart #(.DATA_BITS(8), .PARITY_BIT("even"), .STOP_BITS(2)) dut (clk, rst, tx_data, transmit_start, transmit_ready, tx, rx_data, rx_data_valid, rx_error, rx);

	// generate parity for verification
	logic [7:0] parity_data;
	logic parity_result;
	wire parity = ~parity_result; // inverted to make even parity
	parity parity_inst (parity_data, parity_result);

	// reverse tx_data bit order for verification
	wire [dut.DATA_BITS-1 : 0] tx_data_rev;
	genvar n;

	generate
		for (n = 0; n < dut.DATA_BITS; n = n + 1) begin
			assign tx_data_rev[n] = tx_data[dut.DATA_BITS - (n+1)];
		end
	endgenerate

	// used in testbench
	logic [11:0] tx_buffer;
	integer i, j;

	initial begin
		$dumpfile("trace/tb_uart.vcd");
		$dumpvars();

		rx = 'b1;

		#10
		clk = 'b0;
		rst = 'b1;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		rst = 'b0;

		// test transfers and receives with a loopback
		// transmit values from 0x00 to 0xFF, verify results
		// parity is tested separately in tb_parity
		for (i = 0; i < 255; i = i + 1) begin
			tx_data = i[7:0];
			parity_data = tx_data;

			transmit_start = 'b1;
			
			#10 clk = 'b1;
			#10 clk = 'b0;

			for (j = 0; j < 12; j = j + 1) begin
				#10 clk = 'b1;
				#10 clk = 'b0;

				rx = tx; // loopback

				transmit_start = 'b0;

				tx_buffer = tx_buffer << 1;
				tx_buffer[0] = tx;
			end

			if (tx_buffer != { 1'b0, tx_data_rev, parity, 2'b11 }) $error();
			if (!rx_data_valid || rx_error) $error();
			if (tx_data != rx_data) $error();
		end

		$finish;
	end

endmodule
