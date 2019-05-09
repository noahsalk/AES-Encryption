/************************************************************************
Avalon-MM Interface for AES Decryption IP Core

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department

Register Map:

 0-3 : 4x 32bit AES Key
 4-7 : 4x 32bit AES Encrypted Message
 8-11: 4x 32bit AES Decrypted Message
   12: Not Used
	13: Not Used
   14: 32bit Start Register
   15: 32bit Done Register

************************************************************************/

module avalon_aes_interface (
	// Avalon Clock Input
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,						// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,		// Avalon-MM Byte Enable
	input  logic [3:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,	// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,	// Avalon-MM Read Data
	
	// Exported Conduit
	output logic [31:0] EXPORT_DATA		// Exported Conduit Signal to LEDs
);

	logic [31:0] start, dec0, dec1, dec2, dec3, done0;
	logic done;
	logic [127:0] key, encoded_msg, decoded_msg;
	
	always_comb
	begin
		unique case(AVL_ADDR)
		4'd8	:	AVL_READDATA = dec0;
		4'd9	:	AVL_READDATA = dec1;
		4'd10	:	AVL_READDATA = dec2;
		4'd11	:	AVL_READDATA = dec3;
		4'd15	:	AVL_READDATA = done0;
		endcase
	end
	
	reg_file  reg_unit(.Clk(CLK),
							 .Reset(RESET),
							 .r(AVL_READ),
							 .w(AVL_WRITE),
							 .cs(AVL_CS),
							 .byte_en(AVL_BYTE_EN),
							 .addr(AVL_ADDR),
							 .Din(AVL_WRITEDATA),
							 .ex(EXPORT_DATA),
							 .A(key[31:0]),
							 .B(key[63:32]),
							 .C(key[95:64]),
							 .D(key[127:96]),
							 .E(encoded_msg[31:0]),
							 .F(encoded_msg[63:32]),
							 .G(encoded_msg[95:64]),
							 .H(encoded_msg[127:96]), 
							 .I(dec0),
							 .J(dec1),
							 .K(dec2),
							 .L(dec3),
							 .M(start),
							 .N(done0),
							 .I_in(decoded_msg[31:0]),
							 .J_in(decoded_msg[63:32]),
							 .K_in(decoded_msg[95:64]),
							 .L_in(decoded_msg[127:96]),
							 .N_in(done)); // to be set by AES
	
	AES 	AES_inst(.CLK(CLK),
						.RESET(RESET),
						.AES_START(start[31]), //start is MSB of the AES_START register
						.AES_DONE(done),
						.AES_KEY(key),
						.AES_MSG_ENC(encoded_msg),
						.AES_MSG_DEC(decoded_msg));
endmodule
