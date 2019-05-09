module reg_file(input logic Clk, Reset, r, w, cs, N_in,
					 input logic [3:0] addr, byte_en,
					 input logic [31:0] Din, I_in, J_in, K_in, L_in,
					 output logic [31:0] ex, A,B,C,D,E,F,G,H,I,J,K,L,M,N);
	
	logic [15:0] ld_inter, ld_fin;
	
	always_comb
		begin
			unique case(addr) // load logic
				4'h0	:	begin 
							ld_inter = 16'h0001;
							end
				4'h1	:	begin
							ld_inter = 16'h0002;
							end
				4'h2	:	begin
							ld_inter = 16'h0004;
							end
				4'h3	:	begin
							ld_inter = 16'h0008;
							end
				4'h4	:	begin
							ld_inter = 16'h0010;
							end
				4'h5	:	begin
							ld_inter = 16'h0020;
							end
				4'h6	:	begin
							ld_inter = 16'h0040;
							end
				4'h7	:	begin
							ld_inter = 16'h0080;
							end
				4'h8	:	begin
							ld_inter = 16'h0100;
							end
				4'h9	:	begin
							ld_inter = 16'h0200;
							end
				4'ha	:	begin
							ld_inter = 16'h0400;
							end
				4'hb	:	begin
							ld_inter = 16'h0800;
							end
				// space of two
				4'he	:	begin
							ld_inter = 16'h4000;
							end
				4'hf	:	begin
							ld_inter = 16'h8000;
							end
			endcase
			
		end
	
	
	assign ld_fin = ld_inter & {16{w}} & {16{cs}}; // make sure chip select and write are high
	assign ex = {L[31:16], I[15:0]}; // for export first and last two bytes of encrypted message
	
	
	reg_32		AES_KEY0(.Clk(Clk), .LD(ld_fin[0]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(A));
	reg_32		AES_KEY1(.Clk(Clk), .LD(ld_fin[1]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(B));
	reg_32		AES_KEY2(.Clk(Clk), .LD(ld_fin[2]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(C));
	reg_32		AES_KEY3(.Clk(Clk), .LD(ld_fin[3]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(D));
						
	reg_32		AES_MSG_ENC0(.Clk(Clk), .LD(ld_fin[4]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(E));
	reg_32		AES_MSG_ENC1(.Clk(Clk), .LD(ld_fin[5]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(F));
	reg_32		AES_MSG_ENC2(.Clk(Clk), .LD(ld_fin[6]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(G));
	reg_32		AES_MSG_ENC3(.Clk(Clk), .LD(ld_fin[7]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(H));
						
	reg_32		AES_MSG_DEC0(.Clk(Clk), .LD(1'b1), .Reset(Reset), .Din(I_in), .byte_en(4'b1111),
						.Dout(I));
	reg_32		AES_MSG_DEC1(.Clk(Clk), .LD(1'b1), .Reset(Reset), .Din(J_in), .byte_en(4'b1111),
						.Dout(J));
	reg_32		AES_MSG_DEC2(.Clk(Clk), .LD(1'b1), .Reset(Reset), .Din(K_in), .byte_en(4'b1111),
						.Dout(K));
	reg_32		AES_MSG_DEC3(.Clk(Clk), .LD(1'b1), .Reset(Reset), .Din(L_in), .byte_en(4'b1111),
						.Dout(L));
						
	reg_32		AES_START(.Clk(Clk), .LD(ld_fin[14]), .Reset(Reset), .Din(Din), .byte_en(byte_en),
						.Dout(M));
	reg_32		AES_DONE(.Clk(Clk), .LD(1'b1), .Reset(Reset), .Din({N_in,31'd0}), .byte_en(4'b1111),
						.Dout(N));					
						
endmodule
