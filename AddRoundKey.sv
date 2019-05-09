module 	AddRoundKey(input logic [3:0] sel,
							input logic [1407:0] w,
							input logic [127:0] state_curr,
							output logic [127:0] state_new);
 	
	logic [127:0] inter;
	
	always_comb
	begin
	
		unique case (sel)
			4'd0	:	inter = w[1407:1280]; //initial key
			4'd1	:	inter = w[1279:1152]; //first round key
			4'd2	:	inter = w[1151:1024];
			4'd3	:	inter = w[1023:896];
			4'd4	:	inter = w[895:768];
			4'd5	:	inter = w[767:640];
			4'd6	:	inter = w[639:512];
			4'd7	:	inter = w[511:384];
			4'd8	:	inter = w[383:256];
			4'd9	:	inter = w[255:128];
			4'd10	:	inter = w[127:0];
		endcase
		
		state_new = state_curr ^ inter;
		
	end
			 
endmodule
