// Testbench for spram module
module tb_spram();

	logic clk, rst;
	spram_mode mode;
	logic [dut.ADDR_BITS-1 : 0] rd_addr, wr_addr;
	logic [dut.DATA_BITS-1 : 0] data_wr, data_rd;
	spram #(.SIZE(32)) dut (clk, rst, mode, rd_addr, wr_addr, data_wr, data_rd);

	integer i;

	initial begin
		$dumpfile("trace/tb_spram.fst");
		$dumpvars();

		// test writes
		mode = SPRAM_WRITE;

		for (i = 0; i < 32; i = i + 1) begin
			#10 clk = 'b0;
			wr_addr = i[dut.ADDR_BITS-1 : 0];
			data_wr = i[dut.DATA_BITS-1 : 0];

			#10 clk = 'b1;
		end

		// test reads
		#10 clk = 'b0;
		mode = SPRAM_READ;

		for (i = 0; i < 32; i = i + 1) begin
			rd_addr = i[dut.ADDR_BITS-1 : 0];

			#10 clk = 'b1;
			#10 clk = 'b0;

			if (data_rd != i[dut.DATA_BITS-1 : 0]) $error();
		end
	end

endmodule
