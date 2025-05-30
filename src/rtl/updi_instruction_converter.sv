// All of the UPDI instructions
enum {
	UPDI_LDS,
	UPDI_LD,
	UPDI_STS,
	UPDI_ST,
	UPDI_LDCS,
	UPDI_REPEAT,
	UPDI_STCS,
	UPDI_KEY
} updi_instruction;

// Takes in an UPDI instruction and relevant parameters and converts it into
// an opcode
module updi_instruction_converter ( 
	// control
	input rst,
	input enable,

	// instruction inputs
	input updi_instruction instruction,
	input [1:0] size_a,
	input [1:0] size_b,
	input [1:0] ptr,
	input [3:0] cs_addr,
	input sib,
	input [1:0] size_c,

	// output byte
	output logic [7:0] opcode
);

	always_latch begin
		if (rst) begin
			opcode = 'b0;
		end
		else if (enable) begin
			case (instruction)
				UPDI_LDS: begin
					opcode = {
						3'b000,
						1'b0,
						size_a,
						size_b
					};
				end
				
				UPDI_LD: begin
					opcode = {
						3'b001,
						1'b0,
						ptr,
						size_a // technically size a/b
					};
				end
				
				UPDI_STS: begin
					opcode = {
						3'b010,
						1'b0,
						size_a,
						size_b
					};
				end
				
				UPDI_ST: begin
					opcode = {
						3'b011,
						1'b0,
						ptr,
						size_a // technicaly size a/b
					};
				end
				
				UPDI_LDCS: begin
					opcode = {
						3'b100,
						1'b0,
						cs_addr
					};
				end
				
				UPDI_REPEAT: begin
					opcode = {
						3'b101,
						3'b000,
						size_b
					};
				end
				
				UPDI_STCS: begin
					opcode = {
						3'b110,
						1'b0,
						cs_addr
					};
				end
				
				UPDI_KEY: begin
					opcode = {
						3'b111,
						2'b00,
						sib,
						size_c
					};
				end
			endcase
		end
	end

endmodule
