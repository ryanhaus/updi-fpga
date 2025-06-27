// testbench for updi_double_break
module tb_updi_double_break();

	parameter N_CLKS = 10;

	logic clk, rst, start, busy, done, pulse;
	updi_double_break #(.PULSE_CLK(N_CLKS)) dut (clk, rst, start, busy, done, pulse);

	integer i;

	initial begin
		$dumpfile("trace/tb_updi_double_break.fst");
		$dumpvars();

		clk = 'b0;
		rst = 'b1;
		start = 'b0;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		rst = 'b0;
		start = 'b1;

		// Pulse 1
		#10
		clk = 'b1;

		#10
		clk = 'b0;
		start = 'b0;

		i = 0;

		while (busy && pulse == 'b0) begin
			#10
			clk = 'b1;

			#10
			clk = 'b0;

			i = i + 'b1;
		end

		$display("Pulse 1 took %0d clocks (expected: %0d)", i, N_CLKS);
		
		if (i != N_CLKS) $error();

		// Pulse 2
		i = 0;

		while (busy && pulse == 'b1) begin
			#10
			clk = 'b1;

			#10
			clk = 'b0;

			i = i + 'b1;
		end

		$display("Pulse 2 took %0d clocks (expected: %0d)", i, N_CLKS);

		if (i != N_CLKS) $error();

		// Pulse 3
		i = 0;

		while (busy && pulse == 'b0) begin
			#10
			clk = 'b1;

			#10
			clk = 'b0;

			i = i + 'b1;
		end

		$display("Pulse 3 took %0d clocks (expected: %0d)", i, N_CLKS);

		// Pulse 4
		i = 0;

		while (busy) begin
			#10
			clk = 'b1;

			#10
			clk = 'b0;

			i = i + 'b1;
		end

		$display("Pulse 4 took %0d clocks (expected: %0d)", i, N_CLKS);

		if (i != N_CLKS) $error();
		if (busy) $error();
		if (!done) $error();

		$finish;
	end

endmodule
