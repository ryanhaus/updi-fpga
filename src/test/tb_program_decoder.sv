// testbench for program_decoder module
module tb_program_decoder();

	parameter PROGRAM_FILE = "src/test/test_program.mem";
	parameter PROGRAM_SIZE = 64;

	// signals
	logic clk, rst, start, ready, done;
	logic [7:0] prog_data, block_length, block_type;
	logic [dut.PROG_ADDR_BITS-1 : 0] prog_addr;
	logic [15:0] block_address;
	logic [7:0] block_data [dut.DATA_BLOCK_MAX_SIZE];

	// program decoder on posedge
	program_decoder #(.PROGRAM_SIZE(PROGRAM_SIZE)) dut (
		clk, rst,
		prog_addr, prog_data,
		start, ready, done,
		block_length, block_address, block_type, block_data
	);

	// ROM
	rom #(
		.FILE_NAME(PROGRAM_FILE),
		.SIZE(PROGRAM_SIZE)
	) rom_inst (clk, prog_addr, prog_data);

	// test
	logic [7:0] expected_data [dut.PROGRAM_SIZE];
	integer i, block;

	initial begin
		$dumpfile("trace/tb_program_decoder.fst");
		$dumpvars();

		expected_data[0] = 'h48;
		expected_data[1] = 'h65;
		expected_data[2] = 'h6C;
		expected_data[3] = 'h6C;
		expected_data[4] = 'h6F;
		expected_data[5] = 'h2C;
		expected_data[6] = 'h20;
		expected_data[7] = 'h77;
		expected_data[8] = 'h6F;
		expected_data[9] = 'h72;
		expected_data[10] = 'h6C;
		expected_data[11] = 'h64;
		expected_data[12] = 'h21;
		expected_data[13] = 'h00;
		expected_data[14] = 'h00;
		expected_data[15] = 'h00;

		// reset
		clk = 'b0;
		rst = 'b1;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		rst = 'b0;

		#10 clk = 'b1;
		#10 clk = 'b0;

		// process first block of ROM
		if (!ready) $error();
		start = 'b1;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		start = 'b0;
		
		while (!done) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// verify first block of ROM
		if (block_length != 'd16) $error();
		if (block_address != 'h1234) $error();
		if (block_type != '0) $error();

		for (i = 0; i < 16; i = i + 1) begin
			if (block_data[i] != { 4'h1, i[3:0] }) $error();
		end

		// process first block of ROM
		if (!ready) $error();
		start = 'b1;

		#10
		clk = 'b1;

		#10
		clk = 'b0;
		start = 'b0;
		
		while (!done) begin
			#10 clk = 'b1;
			#10 clk = 'b0;
		end

		// verify first block of ROM
		if (block_length != 'd16) $error();
		if (block_address != 'h5678) $error();
		if (block_type != '0) $error();

		for (i = 0; i < 16; i = i + 1) begin
			if (block_data[i] != { 4'h2, i[3:0] }) $error();
		end
	end

endmodule
