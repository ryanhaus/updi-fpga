// Testbench for uart module
module tb_uart();

	parameter UART_CLK_DIV = 20;

	logic clk, rst, tx, rx, transmit_start, transmit_ready, rx_data_valid, rx_error;
	logic [dut.DATA_BITS-1 : 0] tx_data, rx_data;
	uart #(.DATA_BITS(8), .PARITY_BIT("even"), .STOP_BITS(2), .UART_CLK_DIV(UART_CLK_DIV)) dut (clk, rst, tx_data, transmit_start, transmit_ready, tx, rx_data, rx_data_valid, rx_error, rx);

	assign rx = tx; // loopback

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
	integer i;

	initial #100000000 $error();

	initial begin
		$dumpfile("trace/tb_uart.fst");
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
			
			transmit_start = 'b0;

			while (!rx_data_valid) begin
				#10 clk = 'b1;
				#10 clk = 'b0;

				if (rx_error) $error();
			end

			if (tx_data != rx_data) $error();

			while (!transmit_ready) begin
				#10 clk = 'b1;
				#10 clk = 'b0;
			end
		end

		$finish;
	end

endmodule
