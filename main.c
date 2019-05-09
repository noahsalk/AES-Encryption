/************************************************************************
Lab 9 Nios Software

Dong Kai Wang, Fall 2017
Christine Chen, Fall 2013

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "aes.h"

// Pointer to base address of AES module, make sure it matches Qsys
volatile unsigned int * AES_PTR = (unsigned int *) 0x00000040;

// Execution mode: 0 for testing, 1 for benchmarking
int run_mode = 0;

/** charToHex
 *  Convert a single character to the 4-bit value it represents.
 *
 *  Input: a character c (e.g. 'A')
 *  Output: converted 4-bit value (e.g. 0xA)
 */
char charToHex(char c)
{
	char hex = c;

	if (hex >= '0' && hex <= '9')
		hex -= '0';
	else if (hex >= 'A' && hex <= 'F')
	{
		hex -= 'A';
		hex += 10;
	}
	else if (hex >= 'a' && hex <= 'f')
	{
		hex -= 'a';
		hex += 10;
	}
	return hex;
}

/** charsToHex
 *  Convert two characters to byte value it represents.
 *  Inputs must be 0-9, A-F, or a-f.
 *
 *  Input: two characters c1 and c2 (e.g. 'A' and '7')
 *  Output: converted byte value (e.g. 0xA7)
 */
char charsToHex(char c1, char c2)
{
	char hex1 = charToHex(c1);
	char hex2 = charToHex(c2);
	return (hex1 << 4) + hex2;
}

void SubBytes(unsigned char state[4][4]){
	int i,j;
	for(i=0;i<4;i++){
		for(j=0;j<4;j++){
			state[i][j] = aes_sbox[16*((int)(state[i][j]>>4))+((int)(state[i][j]&0xF))];
		}
	}
}

void InvSubBytes(unsigned char state[4][4]){
	int i,j;
	for(i=0;i<4;i++){
		for(j=0;j<4;j++){
			state[i][j] = aes_invsbox[16*((int)(state[i][j]>>4))+((int)(state[i][j]&0xF))];
		}
	}
}

void ShiftRows(unsigned char state[4][4]){
	unsigned char temp[4][4];
	temp[0][0] = state[0][0];
	temp[0][1] = state[0][1];
	temp[0][2] = state[0][2];
	temp[0][3] = state[0][3];

	temp[1][0] = state[1][1];
	temp[1][1] = state[1][2];
	temp[1][2] = state[1][3];
	temp[1][3] = state[1][0];

	temp[2][0] = state[2][2];
	temp[2][1] = state[2][3];
	temp[2][2] = state[2][0];
	temp[2][3] = state[2][1];

	temp[3][0] = state[3][3];
	temp[3][1] = state[3][0];
	temp[3][2] = state[3][1];
	temp[3][3] = state[3][2];

	int i,j;
	for(i=0;i<4;i++){
		for(j=0;j<4;j++){
			state[i][j] = temp[i][j];
		}
	}
}

void InvShiftRows(unsigned char state[4][4]){
	unsigned char temp[4][4];
	temp[0][0] = state[0][0];
	temp[0][1] = state[0][1];
	temp[0][2] = state[0][2];
	temp[0][3] = state[0][3];

	temp[1][0] = state[1][3];
	temp[1][1] = state[1][0];
	temp[1][2] = state[1][1];
	temp[1][3] = state[1][2];

	temp[2][0] = state[2][2];
	temp[2][1] = state[2][3];
	temp[2][2] = state[2][0];
	temp[2][3] = state[2][1];

	temp[3][0] = state[3][1];
	temp[3][1] = state[3][2];
	temp[3][2] = state[3][3];
	temp[3][3] = state[3][0];

	int i,j;
	for(i=0;i<4;i++){
		for(j=0;j<4;j++){
			state[i][j] = temp[i][j];
		}
	}
}

unsigned char xtime(unsigned char * a){
	unsigned char temp = *a;

	if((temp & 0x80)==0)
		return(temp<<1);
	else{
		temp = temp<<1;
		return(temp^0x1b);
	}
}

void MixColumns(unsigned char state[4][4]){
	unsigned char temp[4][4];
	int i,j;
	for(i=0;i<4;i++){
		for(j=0;j<4;j++){
			temp[i][j]=state[i][j];
		}
	}
	for(j=0;j<4;j++){
		state[0][j] = xtime(&temp[0][j]) ^ xtime(&temp[1][j]) ^ temp[1][j] ^ temp[2][j] ^ temp[3][j];
		state[1][j] = temp[0][j] ^ xtime(&temp[1][j]) ^ xtime(&temp[2][j]) ^ temp[2][j] ^ temp[3][j];
		state[2][j] = temp[0][j] ^ temp[1][j] ^ xtime(&temp[2][j]) ^ xtime(&temp[3][j]) ^ temp[3][j];
		state[3][j] = xtime(&temp[0][j]) ^ temp[0][j] ^ temp[1][j] ^ temp[2][j] ^ xtime(&temp[3][j]);
	}
}

void InvMixColumns(unsigned char state[4][4]){
	unsigned char temp[4][4];
	int i,j;
	for(i=0;i<4;i++){
		for(j=0;j<4;j++){
			temp[i][j]=state[i][j];
		}
	}
	for(j=0;j<4;j++){
		state[0][j] = gf_mul[16*((int)(temp[0][j]>>4))+((int)(temp[0][j]&0xF))][5] ^ gf_mul[16*((int)(temp[1][j]>>4))+((int)(temp[1][j]&0xF))][3] ^
				gf_mul[16*((int)(temp[2][j]>>4))+((int)(temp[2][j]&0xF))][4] ^ gf_mul[16*((int)(temp[3][j]>>4))+((int)(temp[3][j]&0xF))][2];
		state[1][j] = gf_mul[16*((int)(temp[0][j]>>4))+((int)(temp[0][j]&0xF))][2] ^ gf_mul[16*((int)(temp[1][j]>>4))+((int)(temp[1][j]&0xF))][5] ^
				gf_mul[16*((int)(temp[2][j]>>4))+((int)(temp[2][j]&0xF))][3] ^ gf_mul[16*((int)(temp[3][j]>>4))+((int)(temp[3][j]&0xF))][4];
		state[2][j] = gf_mul[16*((int)(temp[0][j]>>4))+((int)(temp[0][j]&0xF))][4] ^ gf_mul[16*((int)(temp[1][j]>>4))+((int)(temp[1][j]&0xF))][2] ^
				gf_mul[16*((int)(temp[2][j]>>4))+((int)(temp[2][j]&0xF))][5] ^ gf_mul[16*((int)(temp[3][j]>>4))+((int)(temp[3][j]&0xF))][3];
		state[3][j] = gf_mul[16*((int)(temp[0][j]>>4))+((int)(temp[0][j]&0xF))][3] ^ gf_mul[16*((int)(temp[1][j]>>4))+((int)(temp[1][j]&0xF))][4] ^
				gf_mul[16*((int)(temp[2][j]>>4))+((int)(temp[2][j]&0xF))][2] ^ gf_mul[16*((int)(temp[3][j]>>4))+((int)(temp[3][j]&0xF))][5];
	}
}

unsigned int * SubWord(unsigned int * temp){
	unsigned char a0,a1,a2,a3;
	a0 = *temp;
	a1 = *temp >> 8;
	a2 = *temp >> 16;
	a3 = *temp >> 24;

	a0 = aes_sbox[16*((int)(a0>>4))+((int)(a0&0xF))];
	a1 = aes_sbox[16*((int)(a1>>4))+((int)(a1&0xF))];
	a2 = aes_sbox[16*((int)(a2>>4))+((int)(a2&0xF))];
	a3 = aes_sbox[16*((int)(a3>>4))+((int)(a3&0xF))];

	*temp = (a3<<24) | (a2<<16) | (a1<<8) | (a0);
	return(temp);
}

unsigned int * RotWord(unsigned int * temp){
	unsigned int temp_temp = (*temp & 0xFF000000)>>24; //take the top byte and bring it to the lowest byte position
	*temp = *temp << 8; //shift the temp up by 3 bytes
	*temp = *temp | temp_temp; //replace the lowest byte (all zeros) with the previous upper byte
	return(temp);
}

unsigned int * KeyExpansion(unsigned char key[4][4]){
	unsigned int temp;
	unsigned int *w;
	w = malloc(sizeof(unsigned int)*44);
	//temp_temp = malloc(sizeof(unsigned int)*44);
	int i=0; //copy key into first round key
	while(i<4){
		w[i]=(key[0][i] << 24) | (key[1][i] << 16) | (key[2][i] << 8) | (key[3][i]); //shifting mechanism
		i++;
	}
	i=4;
	while(i<44){
		temp = w[i-1];
		if((i % 4)==0){
			temp = *(SubWord(RotWord(&temp))) ^ Rcon[i/4];
		}
		w[i] = w[i-4] ^ temp;
		i++;
	}
	return(w);
}

void AddRoundKey(unsigned char state[4][4], unsigned int * w){
	int i,j;
	for(i=0;i<4;i++){
		for(j=0;j<4;j++){
			state[i][j] = (state[i][j]) ^ (*(w+j)>>(24-(8*i)));
		}
	}
}

/** encrypt
 *  Perform AES encryption in software.
 *
 *  Input: msg_ascii - Pointer to 32x 8-bit char array that contains the input message in ASCII format
 *         key_ascii - Pointer to 32x 8-bit char array that contains the input key in ASCII format
 *  Output:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *               key - Pointer to 4x 32-bit int array that contains the input key
 */
void encrypt(unsigned char * msg_ascii, unsigned char * key_ascii, unsigned int * msg_enc, unsigned int * key)
{
	unsigned char state[4][4];
	unsigned char key_inter[4][4];

	// copy msg_ascii into 2D state array
	int i, j;
	for(i=0;i<=3;i++){  //rows
		for(j=0;j<=3;j++){ //columns
			state[j][i] = charsToHex(msg_ascii[(2*j)+(8*i)],msg_ascii[(2*j)+(8*i)+1]); //parse column major into 2D array
			key_inter[j][i] = charsToHex(key_ascii[(2*j)+(8*i)],key_ascii[(2*j)+(8*i)+1]);
		}
	}

	unsigned int * w = KeyExpansion(key_inter); // key schedule


	AddRoundKey(state,&w[0]);

	for(i=1;i<=9;i++){
		SubBytes(state);
		ShiftRows(state);
		MixColumns(state);
		AddRoundKey(state,&w[4*i]);
	}


	SubBytes(state);
	ShiftRows(state);
	AddRoundKey(state,&w[40]);


	for(j=0;j<4;j++){
		msg_enc[j] = (state[0][j]<<24) | (state[1][j]<<16) | (state[2][j]<<8) | state[3][j];
		//key = w[j];
		key[j] = (key_inter[0][j]<<24) | (key_inter[1][j]<<16) | (key_inter[2][j]<<8) | key_inter[3][j];
	}
}

/** decrypt
 *  Perform AES decryption in hardware.
 *
 *  Input:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *              key - Pointer to 4x 32-bit int array that contains the input key
 *  Output: msg_dec - Pointer to 4x 32-bit int array that contains the decrypted message
 */
void decrypt(unsigned int * msg_enc, unsigned int * msg_dec, unsigned int * key)
{
	AES_PTR[14] = 0x80000000 ;//write "start" to the AES
	unsigned int x = AES_PTR[15];
	int j;
	while(x != 0x80000000){
		x = AES_PTR[15]; //wait for done to be flagged
	}
	for(j=0;j<4;j++){
		msg_dec[j] = AES_PTR[11-j];
	}

	AES_PTR[14] = 0x00000000; //write 0 to AES_START

	/*
	unsigned char state[4][4];
	unsigned char key_inter[4][4];

	int j;
	for(j=0;j<4;j++){
		state[3][j] = msg_enc[j];
		state[2][j] = msg_enc[j] >> 8;
		state[1][j] = msg_enc[j] >> 16;
		state[0][j] = msg_enc[j] >> 24;
		key_inter[3][j] = key[j]>>0;
		key_inter[2][j] = key[j]>>8;
		key_inter[1][j] = key[j]>>16;
		key_inter[0][j]= key[j]>>24;
	}

	unsigned int * w = KeyExpansion(key_inter); // key schedule

	AddRoundKey(state,&w[40]);

	int i;
	for(i=9;i>=1;i--){
		InvShiftRows(state);
		InvSubBytes(state);
		AddRoundKey(state,&w[i*4]);
		InvMixColumns(state);
	}

	InvShiftRows(state);
	InvSubBytes(state);
	AddRoundKey(state,&w[0]);

	for(j=0;j<4;j++){
		msg_dec[j] = (state[0][j]<<24) | (state[1][j]<<16) | (state[2][j]<<8) | state[3][j];
	}
	*/
}

/** main
 *  Allows the user to enter the message, key, and select execution mode
 *
 */
int main()
{
	// Input Message and Key as 32x 8-bit ASCII Characters ([33] is for NULL terminator)
	unsigned char msg_ascii[33];
	unsigned char key_ascii[33];
	// Key, Encrypted Message, and Decrypted Message in 4x 32-bit Format to facilitate Read/Write to Hardware
	unsigned int key[4];
	unsigned int msg_enc[4];
	unsigned int msg_dec[4];

	printf("Select execution mode: 0 for testing, 1 for benchmarking: ");
	scanf("%d", &run_mode);

	if (run_mode == 0) {
		// Continuously Perform Encryption and Decryption
		while (1) {
			int i = 0;
			printf("\nEnter Message:\n");
			scanf("%s", msg_ascii);
			printf("\n");
			printf("\nEnter Key:\n");
			scanf("%s", key_ascii);
			printf("\n");
			encrypt(msg_ascii, key_ascii, msg_enc, key);
			printf("\nEncrpted message is: \n");

			for(i = 0; i < 4; i++){
				printf("%08x", msg_enc[i]);
				AES_PTR[4+i] = msg_enc[3-i];
				AES_PTR[0+i] = key[3-i];
			}

			printf("\n");

			decrypt(msg_enc, msg_dec, key);
			printf("\nDecrypted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_dec[i]);
			}
			printf("\n");
		}
	}
	else {
		// Run the Benchmark
		int i = 0;
		int size_KB = 2;
		// Choose a random Plaintext and Key
		for (i = 0; i < 32; i++) {
			msg_ascii[i] = 'a';
			key_ascii[i] = 'b';
		}
		// Run Encryption
		clock_t begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			encrypt(msg_ascii, key_ascii, msg_enc, key);
		clock_t end = clock();
		double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		double speed = size_KB / time_spent;
		printf("Software Encryption Speed: %f KB/s \n", speed);
		// Run Decryption
		begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			decrypt(msg_enc, msg_dec, key);
		end = clock();
		time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		speed = size_KB / time_spent;
		printf("Hardware Decryption Speed: %f KB/s \n", speed);
	}
	return 0;
}
