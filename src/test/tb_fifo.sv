// testbench for fifo
module tb_fifo();

	parameter DEPTH = 32;
	parameter WIDTH = 8;

	logic clk, rst, rd_en, wr_en, empty, full;
	logic [WIDTH-1 : 0] in, out;
	fifo #(DEPTH, WIDTH) dut (clk, rst, in, out, rd_en, wr_en, empty, full);

	integer i;

	initial begin
		$dumpfile("trace/tb_fifo.vcd");
		$dumpvars();

		clk = 'b0;
		rst = 'b1;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		rst = 'b0;

		// test writes
		if (empty != 'b1) $error();
		if (full != 'b0) $error();

		wr_en = 'b1;

		for (i = 0; i < 30; i = i + 1) begin
			in = i[7:0];

			#10 clk = 'b1;
			#10 clk = 'b0;

			if (empty != 'b0) $error();
			if (full != 'b0) $error();
		end

		in = 'd30;
		#10 clk = 'b1;
		#10 clk = 'b0;
		wr_en = 'b0;

		if (empty != 'b0) $error();
		if (full != 'b1) $error();

		// test reads
		rd_en = 'b1;
		
		for (i = 0; i < 31; i = i + 1) begin
			#10 clk = 'b1;
			#10 clk = 'b0;

			if (out != i[7:0]) $error();
		end

		if (empty != 'b1) $error();

		$finish;
	end

endmodule
