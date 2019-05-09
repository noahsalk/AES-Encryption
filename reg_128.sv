//this module is a parallel load 128-bit register

module reg_128(input logic Clk, Reset, LD,
				   input logic [127:0] Din,
				   output logic [127:0] Dout);
					
		always_ff @ (posedge Clk)
		begin
			if(Reset)
				Dout <= 128'd0;
			else if(LD)
				Dout <= Din;
		end
endmodule
