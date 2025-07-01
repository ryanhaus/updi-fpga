// testbench for clock_divider module
module tb_clock_divider();

	// clock divider instance
	logic clk, rst, out;

	clock_divider #(
		.DIV(5),
		.SHIFT(2)
	) dut (clk, rst, out);

	// testbench logic
	logic [9:0] out_reg = 'b0;
	integer i;

	initial begin
		$dumpfile("trace/tb_clock_divider.fst");
		$dumpvars();

		// shift values into register
		for (i = 0; i < 10; i = i + 1) begin
			out_reg[i] = out;
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// verify
		if (out_reg != 'b0010000100) $error();

		$finish;
	end

endmodule
