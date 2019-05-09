//this module is a parallel load 32-bit register

module regmod_32(input logic Clk, LD,
				   input logic [31:0] Din,
				   output logic [31:0] Dout);
					
		always_ff @ (posedge Clk)
		begin
			if(LD)
				Dout <= Din;
		end
endmodule
