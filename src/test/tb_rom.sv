module tb_rom();

	parameter FILE_NAME = "src/test/test.mem";
	parameter SIZE = 16;

	logic clk;
	logic[dut.ADDR_BITS-1 : 0] addr;
	logic [7:0] out;
	rom #(FILE_NAME, SIZE) dut (clk, addr, out);

	logic [7:0] expected [SIZE];
	integer i;

	initial begin
		$dumpfile("trace/tb_rom.vcd");
		$dumpvars();

		expected[0] = 'h48;
		expected[1] = 'h65;
		expected[2] = 'h6C;
		expected[3] = 'h6C;
		expected[4] = 'h6F;
		expected[5] = 'h2C;
		expected[6] = 'h20;
		expected[7] = 'h77;
		expected[8] = 'h6F;
		expected[9] = 'h72;
		expected[10] = 'h6C;
		expected[11] = 'h64;
		expected[12] = 'h21;
		expected[13] = 'h00;
		expected[14] = 'h00;
		expected[15] = 'h00;

		for (i = 0; i < SIZE; i = i + 1) begin
			addr = i[dut.ADDR_BITS-1 : 0];
			#10 clk = 'b1;
			#10 clk = 'b0;

			if (expected[i] != out) $error();
		end

	end

endmodule
