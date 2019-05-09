/************************************************************************
AES Decryption Core Logic

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

module AES (
	input	 logic CLK,
	input  logic RESET,
	input  logic AES_START,
	output logic AES_DONE,
	input  logic [127:0] AES_KEY,
	input  logic [127:0] AES_MSG_ENC,
	output logic [127:0] AES_MSG_DEC
);

	enum logic [4:0] {WAIT, DONE, LDMSG, KE, ADD_0, LOOP, SH, SU, ADD, MIX_0, MIX_1, MIX_2, MIX_3,
							MIX_4, SH_F, SU_F, ADD_F} State, Next_state;
	
	
	//intermediate logic
	logic [15:0] counter;
	logic [1407:0] w; //keyschedule
	logic [3:0] sel_add; //11 unique selects for add round key
	logic ld_state;
	logic [2:0] sel_state_in;
	logic [3:0] sel_word;
	
	logic [127:0] state_in, state_mix, state_add, state_sub, state_shift;
	logic [31:0] mix_in, word_in, word_out;
		
	always_ff @ (posedge CLK) // maybe negative edge is needed
	begin
		if (RESET) 
			State <= WAIT;
		else
			begin
			State <= Next_state;
			if (State == LDMSG)
				counter <= 16'd0;
			else if (State == KE)
				counter <= counter + 1'b1;
			else if (State == ADD_0)
				counter <= 16'd9;
			else if (State == MIX_3)
				counter <= counter - 1'b1;
			end
	end
	
	always_comb
	begin 
		Next_state = State; 								//default to stay in current state
		
		// Defaults (incomplete)
		ld_state = 1'b0;
		sel_word = 4'd0;
		sel_state_in = 3'd0;
		sel_add = 4'd0;
		AES_DONE = 1'b0;
		//counter = counter;
		
		// Next State logic
		unique case (State)
			WAIT	:	
				begin
				if(AES_START)
					Next_state = LDMSG;
				end
			LDMSG	:
				begin
					Next_state = KE;
					//counter = 16'd0;
				end
			KE		:											//key expansion
				begin
				if(counter==16'd14) 					//number of cycles for KeyExpansion to complete (currently random)
					begin
					Next_state = ADD_0; 
					//counter = 16'd0; 						//reset counter
					end
				/*else
					counter = counter + 1'b1; 	*/		//increment counter
				end
			ADD_0	:
				begin
					Next_state = LOOP;
					//counter = 16'd9;
				end
			LOOP	:
				begin
					if(counter == 16'd0)
						begin
						Next_state = SH_F;
						end
					else
						Next_state = SH;
				end
			SH		:
				Next_state = SU;
			SU 	:
				Next_state = ADD;
			ADD	:
				Next_state = MIX_0;
			MIX_0	:
				Next_state = MIX_1;
			MIX_1	:
				Next_state = MIX_2;
			MIX_2	:
				Next_state = MIX_3;
			MIX_3	:
				Next_state = MIX_4;
			MIX_4	:
				begin
				Next_state = LOOP;
				//counter = counter - 1'b1;
				end
			SH_F	:
				Next_state = SU_F;
			SU_F	:
				Next_state = ADD_F;
			ADD_F	:
				Next_state = DONE;
			DONE	:
				if(~AES_START)
					Next_state = WAIT;
			default	:
				Next_state = WAIT;
		endcase
		
		//State descriptions
		case (State)
			WAIT	:	;
			LDMSG	:
				begin
					sel_state_in = 3'd4;
					ld_state = 1'b1;
				end
			KE		:	;
			ADD_0	:
				begin
					sel_add = 4'd10;	//take last round key
					sel_state_in = 3'd0; //choose add input
					ld_state = 1'b1;
				end
			SH		:
				begin
					sel_state_in = 3'd1;
					ld_state = 1'b1;
				end
			SU		:
				begin
					sel_state_in = 3'd2;
					ld_state = 1'b1;
				end
			ADD	:
				begin
					sel_add = counter[3:0];
					sel_state_in = 3'd0;
					ld_state = 1'b1;
				end
			MIX_0	:
				begin
					sel_word = 4'b0001;
				end
			MIX_1	:
				begin
					sel_word = 4'b0010;
				end
			MIX_2	:
				begin
					sel_word = 4'b0100;
				end
			MIX_3	:
				begin
					sel_word = 4'b1000;
				end
			MIX_4	:
				begin
					sel_state_in = 3'd3;
					ld_state = 1'b1;
				end
			SH_F	:
				begin
					sel_state_in = 3'd1;
					ld_state = 1'b1;
				end
			SU_F	:
				begin
					sel_state_in = 3'd2;
					ld_state = 1'b1;
				end
			ADD_F	:
				begin
					sel_add = 4'd0;
					sel_state_in = 3'd0; 
					ld_state = 1'b1;
				end
			DONE	:	
				begin
					AES_DONE = 1'b1;
				end
			default : ;
		endcase
	end
	
	reg_128					    state(.Clk(CLK),
											 .Reset(1'b0), //never reset
											 .LD(ld_state),
											 .Din(state_in),
											 .Dout(AES_MSG_DEC));
											 
	regmod_32				MIX_temp0(.Clk(CLK),
											 .LD(sel_word[0]),
											 .Din(mix_in),
											 .Dout(state_mix[31:0]));
											 
	regmod_32				MIX_temp1(.Clk(CLK),
											 .LD(sel_word[1]),
											 .Din(mix_in),
											 .Dout(state_mix[63:32]));
											 
	regmod_32				MIX_temp2(.Clk(CLK),
											 .LD(sel_word[2]),
											 .Din(mix_in),
											 .Dout(state_mix[95:64]));
											 
	regmod_32				MIX_temp3(.Clk(CLK),
											 .LD(sel_word[3]),
											 .Din(mix_in),
											 .Dout(state_mix[127:96]));
	
	KeyExpansion 			  KE_inst(.clk(CLK),
											 .Cipherkey(AES_KEY),
											 .KeySchedule(w));
											 
	AddRoundKey				 ARK_inst(.sel(sel_add),
											 .w(w),
											 .state_curr(AES_MSG_DEC),
											 .state_new(state_add)); //always point
											 
	InvShiftRows 			 ISR_inst(.data_in(AES_MSG_DEC),
											 .data_out(state_shift));
											 
	//All InvSubBytes Instantiations
											 
	InvSubBytes	  			    ISB_0(.clk(CLK),
											 .in(AES_MSG_DEC[7:0]), 					
											 .out(state_sub[7:0]));
	InvSubBytes	  			    ISB_1(.clk(CLK),
											 .in(AES_MSG_DEC[15:8]), 					
											 .out(state_sub[15:8]));	
	InvSubBytes	  			    ISB_2(.clk(CLK),
											 .in(AES_MSG_DEC[23:16]), 					
											 .out(state_sub[23:16]));	
	InvSubBytes	  			    ISB_3(.clk(CLK),
											 .in(AES_MSG_DEC[31:24]), 					
											 .out(state_sub[31:24]));	
	InvSubBytes	  			    ISB_4(.clk(CLK),
											 .in(AES_MSG_DEC[39:32]), 					
											 .out(state_sub[39:32]));	
	InvSubBytes	  			    ISB_5(.clk(CLK),
											 .in(AES_MSG_DEC[47:40]), 					
											 .out(state_sub[47:40]));	
	InvSubBytes	  			    ISB_6(.clk(CLK),
											 .in(AES_MSG_DEC[55:48]), 					
											 .out(state_sub[55:48]));	
	InvSubBytes	  			    ISB_7(.clk(CLK),
											 .in(AES_MSG_DEC[63:56]), 					
											 .out(state_sub[63:56]));	
	InvSubBytes	  			    ISB_8(.clk(CLK),
											 .in(AES_MSG_DEC[71:64]), 					
											 .out(state_sub[71:64]));	
	InvSubBytes	  			    ISB_9(.clk(CLK),
											 .in(AES_MSG_DEC[79:72]), 					
											 .out(state_sub[79:72]));	
	InvSubBytes	  			   ISB_10(.clk(CLK),
											 .in(AES_MSG_DEC[87:80]), 					
											 .out(state_sub[87:80]));	
	InvSubBytes	  			   ISB_11(.clk(CLK),
											 .in(AES_MSG_DEC[95:88]), 					
											 .out(state_sub[95:88]));			
	InvSubBytes	  			   ISB_12(.clk(CLK),
											 .in(AES_MSG_DEC[103:96]), 					
											 .out(state_sub[103:96]));		
	InvSubBytes	  			   ISB_13(.clk(CLK),
											 .in(AES_MSG_DEC[111:104]), 					
											 .out(state_sub[111:104]));	
	InvSubBytes	  			   ISB_14(.clk(CLK),
											 .in(AES_MSG_DEC[119:112]), 					
											 .out(state_sub[119:112]));	
	InvSubBytes	  			   ISB_15(.clk(CLK),
											 .in(AES_MSG_DEC[127:120]), 					
											 .out(state_sub[127:120]));	

											 
											 
	InvMixColumns         IMC_inst(.in(word_in),					
											 .out(word_out));					
	
	
	always_comb
	begin
		unique case(sel_state_in)
			3'd0	:	state_in = state_add;
			3'd1	:	state_in = state_shift;
			3'd2	:	state_in = state_sub;
			3'd3	:	state_in = state_mix;
			3'd4	:	state_in = AES_MSG_ENC;
		endcase
		
		unique case(sel_word)
			4'b0001	:
				begin
					word_in = AES_MSG_DEC[31:0];
					mix_in = word_out;
				end
			4'b0010	:
				begin
					word_in = AES_MSG_DEC[63:32];
					mix_in = word_out;
				end
			4'b0100	:
				begin
					word_in = AES_MSG_DEC[95:64];
					mix_in = word_out;
				end
			4'b1000	:
				begin
					word_in = AES_MSG_DEC[127:96];
					mix_in = word_out;
				end
		endcase
	end
	
	
endmodule
