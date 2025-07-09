// testbench for delay module
module tb_delay();

	logic clk, rst, start, active, done;
	delay #(.N_CLKS(100)) dut (clk, rst, start, active, done);

	integer i;

	initial #10000 $error();

	initial begin
		$dumpfile("trace/tb_delay.fst");
		$dumpvars();

		// reset
		clk = 'b0;
		rst = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		rst = 'b0;

		// start a delay
		start = 'b1;

		#10 clk = 'b1;
		#10 clk = 'b0;

		start = 'b0;

		// count clocks
		i = 1; // including clock cycle for start signal
		while (!done) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
			i = i + 1;
		end

		if (i != 100) $error();

		$finish;
	end

endmodule
