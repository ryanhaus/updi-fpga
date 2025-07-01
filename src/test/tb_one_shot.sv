module tb_one_shot();

	logic clk, rst, in, out;
	one_shot #(.HOLD_CLOCKS(10)) dut (clk, rst, in, out);

	integer i;

	initial #1000 $error();

	initial begin
		$dumpfile("trace/tb_one_shot.fst");
		$dumpvars();

		in = 'b0;

		// reset
		clk = 'b0;
		rst = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		rst = 'b0;

		// test that it stays off normally
		for (i = 0; i < 10; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;

			if (out == 'b1) $error();
		end

		// test that, when 'in' goes high 1 clock, 'out' stays high for 10
		in = 'b1;
		#10 clk = 'b1;
		#10 clk = 'b0;
		in = 'b0;

		i = 0;
		
		while (out) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
			
			i = i + 1;
		end

		$display("%d", i);
		if (i != 10) $error();

		$finish;
	end

endmodule
