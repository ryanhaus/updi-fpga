// Testbench for parity module
module tb_parity();

	logic [7:0] value;
	logic parity;
	parity dut (value, parity);

	initial begin
		$dumpfile("trace/tb_parity.vcd");
		$dumpvars();

		#10 value = 8'b11111111;
		#10 if (parity != 'b0) $error();

		#10 value = 8'b00000000;
		#10 if (parity != 'b0) $error();

		#10 value = 8'b10101010;
		#10 if (parity != 'b0) $error();

		#10 value = 8'b10010001;
		#10 if (parity != 'b1) $error();

		#10 value = 8'b00010000;
		#10 if (parity != 'b1) $error();

		#10 value = 8'b01111111;
		#10 if (parity != 'b1) $error();

		$finish;
	end

endmodule
