//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kristian Bostic, Vy Ho
// 
// Create Date: 04/07/2022
// Design Name: Wordle for Nexys4
// Module Name: wordle_sm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module wordle_sm(Clk, reset, Start, Ack, C, q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done, win, lose, first_letter, second_letter,
		 third_letter, fourth_letter, fifth_letter, randomWord, I, vga_letters, curr_letter);
    /*  INPUTS */
	// Clock & Reset
	input Clk, reset, Start, Ack;
	input C;
	
	/*  OUTPUTS */
	// store current state
	reg [7:0] state;	
	output q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done;
	assign {q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done} = state;
	
	// Output to be used by top design 
	output win, lose;
	output first_letter, second_letter, third_letter, fourth_letter, fifth_letter;
	output randomWord; 
	output I; 
	output [118:0] vga_letters[0:113]; // add 1 to row, 28 to column
	
	// Local variables, dealing with current guess 
	reg [7:0] first_letter, second_letter, third_letter, fourth_letter, fifth_letter; 
	reg [3:0] I; //counter to indicate position in guess, helps with state transition 
	input wire [7:0] curr_letter; //taken from keyboard 
	
	// Variables dealing with selecting Wordle of the Day 
	reg [39:0] randomWord; //5 ascii character word = 40 bits
	wire rnd; //random number 
	
	assign win = q_Done&({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord);
	assign lose = q_Done&~({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord); 

	// variables for finding correct row and column
	reg [4:0] rownum;
	reg [4:0] colnum;
	
	// aliasing states with one-hot state encoding
	localparam
	   QI = 8'b10000000,
	   Q1G = 8'b01000000,
	   Q2G = 8'b00100000,
	   Q3G = 8'b00010000,
	   Q4G = 8'b00001000,
	   Q5G = 8'b00000100,
	   Q6G = 8'b00000010,
	   QDONE = 8'b00000001; 
	
	//twenty words, one to be selected as wordle of the day 
	localparam
	   word0 = "RENEW",
	   word1 = "STOVE",
  	   word2 = "EPOXY",
	   word3 = "LAPSE", 
  	   word4 = "BRINE", 
	   word5 = "ROBOT", 
  	   word6 = "AROMA", 
	   word7 = "CRIMP", 
  	   word8 = "BANAL", 
	   word9 = "VIVID", 
  	   word10 = "ULCER", 
	   word11 = "ROBIN", 
  	   word12 = "HAIKU", 
	   word13 = "GRIME", 
  	   word14 = "CACAO", 
	   word15 = "ONION", 
  	   word16 = "ABBOT", 
	   word17 = "WALTZ", 
  	   word18 = "AGLET",
	   word19 = "MINUS"
	   row_pos = 8'd021426385062, //valid starting row positions in groups of 2 digits
	   col_pos = 8'd0012243648; //valid starting column positions in groups of 2 digits
	
	LFSR RAN1(.rnd(rnd));
	
	wordle_keyboard KB1(.Clk(sys_clk), .reset(reset), .Start(Start_Ack_SCEN), .Ack(Start_Ack_SCEN), .curr_letter(curr_letter));
	
    	//Selecting Wordle of the Day
	always @(q_I) begin: WordleOfDay //Selects one of the 20 words to be Wordle of the day during Initial State 
		reg[4:0] randomNum; //TODO 
		randomNum = rnd; 
		case(randomNum)  
			5'b00000: randomWord <= word0; 
			5'b00001: randomWord <= word1; 
			5'b00010: randomWord <= word2; 
			5'b00011: randomWord <= word3; 
			5'b00100: randomWord <= word4; 
			5'b00101: randomWord <= word5; 
			5'b00110: randomWord <= word6; 
			5'b00111: randomWord <= word7; 
			5'b01000: randomWord <= word8; 
			5'b01001: randomWord <= word9; 
			5'b01010: randomWord <= word10; 
			5'b01011: randomWord <= word11; 
			5'b01100: randomWord <= word12; 
			5'b01101: randomWord <= word13; 
			5'b01110: randomWord <= word14; 
			5'b01111: randomWord <= word15; 
			5'b10000: randomWord <= word16; 
			5'b10001: randomWord <= word17; 
			5'b10010: randomWord <= word18; 
			5'b10011: randomWord <= word19; 
		endcase
	end

    	// NSL AND SM
    	always @ (posedge Clk, posedge reset)
		begin
			integer r,c;
	   		if(reset) 
		    begin
				state <= QI;
				first_letter <= 8'bXXXXXXXX;
				second_letter <= 8'bXXXXXXXX;
				third_letter <= 8'bXXXXXXXX;
				fourth_letter <= 8'bXXXXXXXX;
				fifth_letter <= 8'bXXXXXXXX;
				rownum <= 4'bXXXX; // start from far left
				colnum <= 4'bXXXX;
		    end 
	    else 
	      begin 
		    case(state)
		       QI: 
			 	begin
			       if(C) begin 
					   state <= Q1G;
					   I <= 0; 
					   first_letter <= 0; 
					   second_letter <= 0;
					   third_letter <= 0; 
					   fourth_letter <= 0; 
					   fifth_letter <= 0;
					   rownum <= 4'b1011;
					   colnum <= 4'b1001;
					   for (r=0; r<114; r=r+1) begin
					   		for (c=0; c<92; c=r+1) begin
					   			vga_letters[r][c] <= 0;
					   		end
					   end
					   // override vga_letters to display keyboard letters
					   	// A: (5,3) (6,3) (4,4) (7,4) (4,5) (7,5) (4,6) (5,6) (6,6) (7,6) (4,7) (7,7) (4,8) (7,8)
					   	vga_letters[79 + 2][3] <= 0;
					   	vga_letters[79 + 2][4] <= 0;
					   	vga_letters[79 + 3][2] <= 0;
					   	vga_letters[79 + 3][5] <= 0;
					   	vga_letters[79 + 4][2] <= 0;
					   	vga_letters[79 + 4][5] <= 0;
					   	vga_letters[79 + 5][2] <= 0;
					   	vga_letters[79 + 5][3] <= 0;
					   	vga_letters[79 + 5][4] <= 0;
					   	vga_letters[79 + 5][5] <= 0;
					   	vga_letters[79 + 6][2] <= 0;
					   	vga_letters[79 + 6][5] <= 0;
					   	vga_letters[79 + 7][2] <= 0;
					   	vga_letters[79 + 7][5] <= 0;
						// B: (4,3) (5,3) (6,3) (4,4) (7,4) (4,5) (5,5) (6,5) (4,6) (7,6) (4,7) (7,7) (4,8) (5,8) (6,8)
						vga_letters[79 + 2][11 + 3] <= 0;
						vga_letters[79 + 2][11 + 4] <= 0;
						vga_letters[79 + 2][11 + 5] <= 0;
						vga_letters[79 + 3][11 + 3] <= 0;
						vga_letters[79 + 3][11 + 6] <= 0;
						vga_letters[79 + 4][11 + 3] <= 0;
						vga_letters[79 + 4][11 + 4] <= 0;
						vga_letters[79 + 4][11 + 5] <= 0;
						vga_letters[79 + 5][11 + 3] <= 0;
						vga_letters[79 + 5][11 + 6] <= 0;
						vga_letters[79 + 6][11 + 3] <= 0;
						vga_letters[79 + 6][11 + 6] <= 0;
						vga_letters[79 + 7][11 + 3] <= 0;
						vga_letters[79 + 7][11 + 4] <= 0;
						vga_letters[79 + 7][11 + 5] <= 0;
						// C: (5,3) (6,3) (4,4) (7,4) (4,5) (4,6) (4,7) (5,8) (6,8) (7,7)
						vga_letters[79 + 2][23 + 4] <= 0;
						vga_letters[79 + 2][23 + 5] <= 0;
						vga_letters[79 + 3][23 + 3] <= 0;
						vga_letters[79 + 3][23 + 6] <= 0;
						vga_letters[79 + 4][23 + 3] <= 0;
						vga_letters[79 + 5][23 + 3] <= 0;
						vga_letters[79 + 6][23 + 3] <= 0;
						vga_letters[79 + 7][23 + 4] <= 0;
						vga_letters[79 + 7][23 + 5] <= 0;
						vga_letters[79 + 6][23 + 6] <= 0;
						// D: (4,3) (5,3) (6,3) (4,4) (7,4) (4,5) (7,5) (4,6) (7,6) (4,7) (7,7) (4,8) (5,8) (6,8)
						vga_letters[79 + 2][35 + 3] <= 0;
						vga_letters[79 + 2][35 + 4] <= 0;
						vga_letters[79 + 2][35 + 5] <= 0;
						vga_letters[79 + 3][35 + 3] <= 0;
						vga_letters[79 + 3][35 + 6] <= 0;
						vga_letters[79 + 4][35 + 3] <= 0;
						vga_letters[79 + 4][35 + 6] <= 0;
						vga_letters[79 + 5][35 + 3] <= 0;
						vga_letters[79 + 5][35 + 6] <= 0;
						vga_letters[79 + 6][35 + 3] <= 0;
						vga_letters[79 + 6][35 + 6] <= 0;
						vga_letters[79 + 7][35 + 3] <= 0;
						vga_letters[79 + 7][35 + 4] <= 0;
						vga_letters[79 + 7][35 + 5] <= 0;
						// E: (4,3) (5,3) (6,3) (7,3) (4,4) (4,5) (5,5) (6,5) (7,5) (4,6) (4,7) (4,8) (5,8) (6,8) (7,8)
						vga_letters[79 + 2][47 + 3] <= 0;
						vga_letters[79 + 2][47 + 4] <= 0;
						vga_letters[79 + 2][47 + 5] <= 0;
						vga_letters[79 + 2][47 + 6] <= 0;
						vga_letters[79 + 3][47 + 3] <= 0;
						vga_letters[79 + 4][47 + 3] <= 0;
						vga_letters[79 + 4][47 + 4] <= 0;
						vga_letters[79 + 4][47 + 5] <= 0;
						vga_letters[79 + 4][47 + 6] <= 0;
						vga_letters[79 + 5][47 + 3] <= 0;
						vga_letters[79 + 6][47 + 3] <= 0;
						vga_letters[79 + 7][47 + 3] <= 0;
						vga_letters[79 + 7][47 + 4] <= 0;
						vga_letters[79 + 7][47 + 5] <= 0;
						vga_letters[79 + 7][47 + 6] <= 0;
						// F: (4,3) (5,3) (6,3) (7,3) (4,4) (4,5) (5,5) (6,5) (7,5) (4,6) (4,7) (4,8)
						vga_letters[79 + 2][59 + 3] <= 0;
						vga_letters[79 + 2][59 + 4] <= 0;
						vga_letters[79 + 2][59 + 5] <= 0;
						vga_letters[79 + 2][59 + 6] <= 0;
						vga_letters[79 + 3][59 + 3] <= 0;
						vga_letters[79 + 4][59 + 3] <= 0;
						vga_letters[79 + 4][59 + 4] <= 0;
						vga_letters[79 + 4][59 + 5] <= 0;
						vga_letters[79 + 4][59 + 6] <= 0;
						vga_letters[79 + 5][59 + 3] <= 0;
						vga_letters[79 + 6][59 + 3] <= 0;
						vga_letters[79 + 7][59 + 3] <= 0;
						// G: (5,3) (6,3) (4,4) (7,4) (4,5) (4,6) (4,7) (5,8) (6,8) (7,7) (7,6) (6,6)
						vga_letters[79 + 2][71 + 4] <= 0;
						vga_letters[79 + 2][71 + 5] <= 0;
						vga_letters[79 + 3][71 + 3] <= 0;
						vga_letters[79 + 3][71 + 6] <= 0;
						vga_letters[79 + 4][71 + 3] <= 0;
						vga_letters[79 + 5][71 + 3] <= 0;
						vga_letters[79 + 6][71 + 3] <= 0;
						vga_letters[79 + 7][71 + 4] <= 0;
						vga_letters[79 + 7][71 + 5] <= 0;
						vga_letters[79 + 6][71 + 6] <= 0;
						vga_letters[79 + 5][71 + 6] <= 0;
						vga_letters[79 + 5][71 + 5] <= 0;
						// H: (4,3) (4,4) (4,5) (4,6) (4,7) (4,8) (5,5) (6,5) (7,3) (7,4) (7,5) (7,6) (7,7) (7,8)
						vga_letters[79 + 2][83 + 3] <= 0;
						vga_letters[79 + 3][83 + 3] <= 0;
						vga_letters[79 + 4][83 + 3] <= 0;
						vga_letters[79 + 5][83 + 3] <= 0;
						vga_letters[79 + 6][83 + 3] <= 0;
						vga_letters[79 + 7][83 + 3] <= 0;
						vga_letters[79 + 4][83 + 4] <= 0;
						vga_letters[79 + 4][83 + 5] <= 0;
						vga_letters[79 + 2][83 + 6] <= 0;
						vga_letters[79 + 3][83 + 6] <= 0;
						vga_letters[79 + 4][83 + 6] <= 0;
						vga_letters[79 + 5][83 + 6] <= 0;
						vga_letters[79 + 6][83 + 6] <= 0;
						vga_letters[79 + 7][83 + 6] <= 0;
						// I: (5,3) (5,4) (5,5) (5,6) (5,7) (5,8) (4,3) (6,3) (4,8) (6,8)
						vga_letters[79 + 2][95 + 4] <= 0;
						vga_letters[79 + 3][95 + 4] <= 0;
						vga_letters[79 + 4][95 + 4] <= 0;
						vga_letters[79 + 5][95 + 4] <= 0;
						vga_letters[79 + 6][95 + 4] <= 0;
						vga_letters[79 + 7][95 + 4] <= 0;
						vga_letters[79 + 2][95 + 3] <= 0;
						vga_letters[79 + 2][95 + 5] <= 0;
						vga_letters[79 + 7][95 + 3] <= 0;
						vga_letters[79 + 7][95 + 5] <= 0;
						// J: (4,3) (5,3) (6,3) (7,3) (6,4) (6,5) (6,6) (6,7) (5,8) (4,7)
						vga_letters[79 + 2][107 + 3] <= 0;
						vga_letters[79 + 2][107 + 4] <= 0;
						vga_letters[79 + 2][107 + 5] <= 0;
						vga_letters[79 + 2][107 + 6] <= 0;
						vga_letters[79 + 3][107 + 5] <= 0;
						vga_letters[79 + 4][107 + 5] <= 0;
						vga_letters[79 + 5][107 + 5] <= 0;
						vga_letters[79 + 6][107 + 5] <= 0;
						vga_letters[79 + 7][107 + 4] <= 0;
						vga_letters[79 + 6][107 + 3] <= 0;
						// K: (4,3) (5,3) (4,4) (6,4) (4,5) (5,5) (4,6) (6,6) (4,7) (7,7) (4,8) (7,8)
						vga_letters[91 + 2][2] <= 0;
						vga_letters[91 + 2][3] <= 0;
						vga_letters[91 + 3][2] <= 0;
						vga_letters[91 + 3][4] <= 0;
						vga_letters[91 + 4][2] <= 0;
						vga_letters[91 + 4][3] <= 0;
						vga_letters[91 + 5][2] <= 0;
						vga_letters[91 + 5][4] <= 0;
						vga_letters[91 + 6][2] <= 0;
						vga_letters[91 + 6][5] <= 0;
						vga_letters[91 + 7][2] <= 0;
						vga_letters[91 + 7][5] <= 0;
						// L: (4,3) (4,4) (4,5) (4,6) (4,7) (4,8) (5,8) (6,8) (7,8)
						vga_letters[91 + 2][11 + 3] <= 0;
						vga_letters[91 + 3][11 + 3] <= 0;
						vga_letters[91 + 4][11 + 3] <= 0;
						vga_letters[91 + 5][11 + 3] <= 0;
						vga_letters[91 + 6][11 + 3] <= 0;
						vga_letters[91 + 7][11 + 3] <= 0;
						vga_letters[91 + 7][11 + 4] <= 0;
						vga_letters[91 + 7][11 + 5] <= 0;
						vga_letters[91 + 7][11 + 6] <= 0;
						// M: (3,3) (3,4) (3,5) (3,6) (3,7) (3,8) (4,4) (5,5) (6,4) (7,3) (7,4) (7,5) (7,6) (7,7) (7,8)
						vga_letters[91 + 2][23 + 2] <= 0;
						vga_letters[91 + 3][23 + 2] <= 0;
						vga_letters[91 + 4][23 + 2] <= 0;
						vga_letters[91 + 5][23 + 2] <= 0;
						vga_letters[91 + 6][23 + 2] <= 0;
						vga_letters[91 + 7][23 + 2] <= 0;
						vga_letters[91 + 3][23 + 3] <= 0;
						vga_letters[91 + 4][23 + 4] <= 0;
						vga_letters[91 + 3][23 + 5] <= 0;
						vga_letters[91 + 2][23 + 6] <= 0;
						vga_letters[91 + 3][23 + 6] <= 0;
						vga_letters[91 + 4][23 + 6] <= 0;
						vga_letters[91 + 5][23 + 6] <= 0;
						vga_letters[91 + 6][23 + 6] <= 0;
						vga_letters[91 + 7][23 + 6] <= 0;
						// N: (3,3) (3,4) (3,5) (3,6) (3,7) (3,8) (4,4) (5,5) (6,6) (7,7) (8,3) (8,4) (8,5) (8,5) (8,7) (8,8)
						vga_letters[91 + 2][35 + 2] <= 0;
						vga_letters[91 + 3][35 + 2] <= 0;
						vga_letters[91 + 4][35 + 2] <= 0;
						vga_letters[91 + 5][35 + 2] <= 0;
						vga_letters[91 + 6][35 + 2] <= 0;
						vga_letters[91 + 7][35 + 2] <= 0;
						vga_letters[91 + 3][35 + 3] <= 0;
						vga_letters[91 + 4][35 + 4] <= 0;
						vga_letters[91 + 5][35 + 5] <= 0;
						vga_letters[91 + 6][35 + 6] <= 0;
						vga_letters[91 + 2][35 + 7] <= 0;
						vga_letters[91 + 3][35 + 7] <= 0;
						vga_letters[91 + 4][35 + 7] <= 0;
						vga_letters[91 + 4][35 + 7] <= 0;
						vga_letters[91 + 6][35 + 7] <= 0;
						vga_letters[91 + 7][35 + 7] <= 0;
						// O: (5,3) (6,3) (4,4) (7,4) (4,5) (4,6) (4,7) (5,8) (6,8) (7,7) (7,5) (7,6) 
						vga_letters[91 + 2][47 + 4] <= 0;
						vga_letters[91 + 2][47 + 5] <= 0;
						vga_letters[91 + 3][47 + 3] <= 0;
						vga_letters[91 + 3][47 + 6] <= 0;
						vga_letters[91 + 4][47 + 3] <= 0;
						vga_letters[91 + 5][47 + 3] <= 0;
						vga_letters[91 + 6][47 + 3] <= 0;
						vga_letters[91 + 7][47 + 4] <= 0;
						vga_letters[91 + 7][47 + 5] <= 0;
						vga_letters[91 + 6][47 + 6] <= 0;
						vga_letters[91 + 4][47 + 6] <= 0;
						vga_letters[91 + 5][47 + 6] <= 0;
						// P: (4,3) (4,4) (4,5) (4,6) (4,7) (4,8) (5,3) (6,3) (5,6) (6,6) (7,4) (7,6) 
						vga_letters[91 + 2][59 + 3] <= 0;
						vga_letters[91 + 3][59 + 3] <= 0;
						vga_letters[91 + 4][59 + 3] <= 0;
						vga_letters[91 + 5][59 + 3] <= 0;
						vga_letters[91 + 6][59 + 3] <= 0;
						vga_letters[91 + 7][59 + 3] <= 0;
						vga_letters[91 + 2][59 + 4] <= 0;
						vga_letters[91 + 2][59 + 5] <= 0;
						vga_letters[91 + 5][59 + 4] <= 0;
						vga_letters[91 + 5][59 + 5] <= 0;
						vga_letters[91 + 3][59 + 6] <= 0;
						vga_letters[91 + 5][59 + 6] <= 0;
						// Q: (5,3) (6,3) (4,4) (4,5) (4,6) (5,7) (6,6) (7,4) (7,5) (7,7) 
						vga_letters[91 + 2][71 + 4] <= 0;
						vga_letters[91 + 2][71 + 5] <= 0;
						vga_letters[91 + 3][71 + 3] <= 0;
						vga_letters[91 + 4][71 + 3] <= 0;
						vga_letters[91 + 5][71 + 3] <= 0;
						vga_letters[91 + 6][71 + 4] <= 0;
						vga_letters[91 + 5][71 + 5] <= 0;
						vga_letters[91 + 3][71 + 6] <= 0;
						vga_letters[91 + 4][71 + 6] <= 0;
						vga_letters[91 + 6][71 + 6] <= 0;
						// R: (4,3) (4,4) (4,5) (4,6) (4,7) (4,8) (5,3) (6,3) (5,6) (6,5) (6,7) (7,4) (7,8) 
						vga_letters[91 + 2][83 + 3] <= 0;
						vga_letters[91 + 3][83 + 3] <= 0;
						vga_letters[91 + 4][83 + 3] <= 0;
						vga_letters[91 + 5][83 + 3] <= 0;
						vga_letters[91 + 6][83 + 3] <= 0;
						vga_letters[91 + 7][83 + 3] <= 0;
						vga_letters[91 + 2][83 + 4] <= 0;
						vga_letters[91 + 2][83 + 5] <= 0;
						vga_letters[91 + 5][83 + 4] <= 0;
						vga_letters[91 + 4][83 + 5] <= 0;
						vga_letters[91 + 6][83 + 5] <= 0;
						vga_letters[91 + 3][83 + 6] <= 0;
						vga_letters[91 + 7][83 + 6] <= 0;
						// S: (5,3) (6,3) (7,3) (4,4) (5,5) (6,6) (7,7) (4,8) (5,8) (6,8) 
						vga_letters[91 + 2][94 + 4] <= 0;
						vga_letters[91 + 2][94 + 5] <= 0;
						vga_letters[91 + 2][94 + 6] <= 0;
						vga_letters[91 + 3][94 + 3] <= 0;
						vga_letters[91 + 4][94 + 4] <= 0;
						vga_letters[91 + 5][94 + 5] <= 0;
						vga_letters[91 + 6][94 + 6] <= 0;
						vga_letters[91 + 7][94 + 3] <= 0;
						vga_letters[91 + 7][94 + 4] <= 0;
						vga_letters[91 + 7][94 + 5] <= 0;
						// T: (3,3) (4,3) (5,3) (6,3) (7,3) (5,4) (5,5) (5,6) (5,7) (5,8) 
						vga_letters[91 + 2][107 + 2] <= 0;
						vga_letters[91 + 2][107 + 3] <= 0;
						vga_letters[91 + 2][107 + 4] <= 0;
						vga_letters[91 + 2][107 + 5] <= 0;
						vga_letters[91 + 2][107 + 6] <= 0;
						vga_letters[91 + 3][107 + 4] <= 0;
						vga_letters[91 + 4][107 + 4] <= 0;
						vga_letters[91 + 5][107 + 4] <= 0;
						vga_letters[91 + 6][107 + 4] <= 0;
						vga_letters[91 + 7][107 + 4] <= 0;
						// U: (3,3) (3,4) (3,5) (3,6) (3,7) (4,8) (5,8) (6,8) (7,3) (7,4) (7,5) (7,6) (7,7) 
						vga_letters[104 + 2][0 + 2] <= 0;
						vga_letters[104 + 3][0 + 2] <= 0;
						vga_letters[104 + 4][0 + 2] <= 0;
						vga_letters[104 + 5][0 + 2] <= 0;
						vga_letters[104 + 6][0 + 2] <= 0;
						vga_letters[104 + 7][0 + 3] <= 0;
						vga_letters[104 + 7][0 + 4] <= 0;
						vga_letters[104 + 7][0 + 5] <= 0;
						vga_letters[104 + 2][0 + 6] <= 0;
						vga_letters[104 + 3][0 + 6] <= 0;
						vga_letters[104 + 4][0 + 6] <= 0;
						vga_letters[104 + 5][0 + 6] <= 0;
						vga_letters[104 + 6][0 + 6] <= 0;
						// V: (3,3) (3,4) (3,5) (3,6) (4,7) (5,8) (6,7) (7,3) (7,4) (7,5) (7,6) 
						vga_letters[104 + 2][11 + 2] <= 0;
						vga_letters[104 + 3][11 + 2] <= 0;
						vga_letters[104 + 4][11 + 2] <= 0;
						vga_letters[104 + 5][11 + 2] <= 0;
						vga_letters[104 + 6][11 + 3] <= 0;
						vga_letters[104 + 7][11 + 4] <= 0;
						vga_letters[104 + 6][11 + 5] <= 0;
						vga_letters[104 + 2][11 + 6] <= 0;
						vga_letters[104 + 3][11 + 6] <= 0;
						vga_letters[104 + 4][11 + 6] <= 0;
						vga_letters[104 + 5][11 + 6] <= 0;
						// W: (3,4) (3,5) (3,6) (4,7) (5,6) (6,6) (7,7) (8,4) (8,5) (8,6) 
						vga_letters[104 + 3][23 + 2] <= 0;
						vga_letters[104 + 4][23 + 2] <= 0;
						vga_letters[104 + 5][23 + 2] <= 0;
						vga_letters[104 + 6][23 + 3] <= 0;
						vga_letters[104 + 5][23 + 4] <= 0;
						vga_letters[104 + 5][23 + 5] <= 0;
						vga_letters[104 + 6][23 + 6] <= 0;
						vga_letters[104 + 3][23 + 7] <= 0;
						vga_letters[104 + 4][23 + 7] <= 0;
						vga_letters[104 + 5][23 + 7] <= 0;
						// X: (3,3) (3,4) (3,8) (4,5) (4,7) (5,6) (6,5) (6,7) (7,3) (7,4) (7,8) 
						vga_letters[104 + 2][35 + 2] <= 0;
						vga_letters[104 + 3][35 + 2] <= 0;
						vga_letters[104 + 7][35 + 2] <= 0;
						vga_letters[104 + 4][35 + 3] <= 0;
						vga_letters[104 + 6][35 + 3] <= 0;
						vga_letters[104 + 5][35 + 4] <= 0;
						vga_letters[104 + 4][35 + 5] <= 0;
						vga_letters[104 + 5][35 + 5] <= 0;
						vga_letters[104 + 6][35 + 6] <= 0;
						vga_letters[104 + 6][35 + 6] <= 0;
						vga_letters[104 + 6][35 + 6] <= 0;
						// Y: (3,3) (3,4) (3,5) (4,6) (4,8) (5,6) (5,7) (6,3) (6,4) (6,5) 
						vga_letters[104 + 2][47 + 2] <= 0;
						vga_letters[104 + 3][47 + 2] <= 0;
						vga_letters[104 + 4][47 + 2] <= 0;
						vga_letters[104 + 5][47 + 3] <= 0;
						vga_letters[104 + 7][47 + 3] <= 0;
						vga_letters[104 + 5][47 + 4] <= 0;
						vga_letters[104 + 6][47 + 4] <= 0;
						vga_letters[104 + 2][47 + 5] <= 0;
						vga_letters[104 + 3][47 + 5] <= 0;
						vga_letters[104 + 4][47 + 5] <= 0;
						// Z: (4,3) (5,3) (6,3) (7,3) (7,4) (6,5) (5,6) (4,7) (4,8) (5,8) (6,8) (7,8) 
						vga_letters[104 + 2][59 + 3] <= 0;
						vga_letters[104 + 2][59 + 4] <= 0;
						vga_letters[104 + 2][59 + 5] <= 0;
						vga_letters[104 + 2][59 + 6] <= 0;
						vga_letters[104 + 3][59 + 6] <= 0;
						vga_letters[104 + 4][59 + 5] <= 0;
						vga_letters[104 + 5][59 + 4] <= 0;
						vga_letters[104 + 6][59 + 3] <= 0;
						vga_letters[104 + 7][59 + 3] <= 0;
						vga_letters[104 + 7][59 + 4] <= 0;
						vga_letters[104 + 7][59 + 5] <= 0;
						vga_letters[104 + 7][59 + 6] <= 0;
			       end 
				end
		       	Q1G:
				begin
					if (C) begin
						I <= I + 1;
						if (I==3'b000) //if I = 0
							first_letter <= curr_letter;
		   				else if (I==3'b001) //if I = 1
							second_letter <= curr_letter;
					   	else if (I==3'b010) //if I = 2 
							third_letter <= curr_letter; 
					   	else if (I==3'b011) //if I = 3
							fourth_letter <= curr_letter; 
					   	else begin //if I = 4 
							fifth_letter = curr_letter; 
						   	if({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord)
						  		state <= QDONE; 
							else begin
								state <= Q2G; 
								first_letter <= 0; 
								second_letter <= 0; 
								third_letter <= 0; 
								fourth_letter <= 0; 
								fifth_letter <= 0; 
								I <= 0; 
							end
					   	end 
				  	end
				end
		       	Q2G: 
	 			 begin
				   	if (C) begin
				   		I <= I + 1; 
					   	if (I==3'b000) //if I = 0
							first_letter <= curr_letter;
					   	else if (I==3'b001) //if I = 1
							second_letter <= curr_letter;
					   	else if (I==3'b010) //if I = 2 
							third_letter <= curr_letter; 
					   	else if (I==3'b011) //if I = 3
							fourth_letter <= curr_letter; 
					   	else begin //if I = 4 
							fifth_letter = curr_letter; 
						   	if({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord)
								state <= QDONE; 
							else begin
								state <= Q3G; 
								first_letter <= 0; 
								second_letter <= 0; 
								third_letter <= 0; 
								fourth_letter <= 0; 
								fifth_letter <= 0; 
								I <= 0; 
							end
					   	end 
					end
				 end
		       	Q3G: 
	 			  begin
				   	if(C) begin
				   		I <= I + 1;
					   	if (I==3'b000) //if I = 0
							first_letter <= curr_letter;
					   	else if (I==3'b001) //if I = 1
							second_letter <= curr_letter;
					   	else if (I==3'b010) //if I = 2 
							third_letter <= curr_letter; 
					   	else if (I==3'b011) //if I = 3
							fourth_letter <= curr_letter; 
					   	else begin //if I = 4 
							fifth_letter = curr_letter; 
						   	if({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord)
						  		state <= QDONE; 
							else begin
								state <= Q4G; 
								first_letter <= 0; 
								second_letter <= 0; 
								third_letter <= 0; 
								fourth_letter <= 0; 
								fifth_letter <= 0; 
								I <= 0; 
							end
				   		end
				  	end
				  end
		       	Q4G: 
	 			  begin
					if (C) begin
				   		I <= I + 1; 
				   		if (I==3'b000) //if I = 0
							first_letter <= curr_letter;
				   		else if (I==3'b001) //if I = 1
							second_letter <= curr_letter;
				   		else if (I==3'b010) //if I = 2 
							third_letter <= curr_letter; 
				   		else if (I==3'b011) //if I = 3
							fourth_letter <= curr_letter; 
				   		else begin //if I = 4 
							fifth_letter = curr_letter; 
					   		if({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord)
					  			state <= QDONE; 
							else begin
								state <= Q5G; 
								first_letter <= 0; 
								second_letter <= 0; 
								third_letter <= 0; 
								fourth_letter <= 0; 
								fifth_letter <= 0; 
								I <= 0; 
							end
				   		end
				  	end
				  end
		       	Q5G:
	 			   	begin
	 			   		if (C) begin
				   			I <= I + 1; 
				   			if (I==3'b000) //if I = 0
								first_letter <= curr_letter;
				   			else if (I==3'b001) //if I = 1
								second_letter <= curr_letter;
				   			else if (I==3'b010) //if I = 2 
								third_letter <= curr_letter; 
				   			else if (I==3'b011) //if I = 3
								fourth_letter <= curr_letter; 
				   			else begin //if I = 4 
								fifth_letter = curr_letter; 
					   			if({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord)
					  				state <= QDONE; 
								else begin
									state <= Q6G; 
									first_letter <= 0; 
									second_letter <= 0; 
									third_letter <= 0; 
									fourth_letter <= 0; 
									fifth_letter <= 0; 
									I <= 0; 
								end
				   			end
				  		end
				   	end
		       	Q6G:
				 begin
				   	if (C) begin
				   		I <= I + 1;
					   	if (I==3'b000) //if I = 0
							first_letter <= curr_letter;
					   	else if (I==3'b001) //if I = 1
							second_letter <= curr_letter;
					   	else if (I==3'b010) //if I = 2 
							third_letter <= curr_letter; 
					   	else if (I==3'b011) //if I = 3
							fourth_letter <= curr_letter; 
					   	else begin //if I = 4 
							fifth_letter <= curr_letter;
							state <= QDONE; 
					   	end
				 	end
				 end
		       	QDONE: 
				   if(C)
					state <= QI; 
				default: state <= QI;
		   endcase
             end
     	end

     	always @ ( I )
     	begin
     		//TODO: update letter according to current letter, starting from position vga_letters[row_pos[rownum]][col_pos[colnum]] 
     		//(switch case for each letter) and update counts, colnum increases and when it reaches 4, it resets and rownum increases
     		if(!q_I) begin
     			colnum <= colnum - 2;
     			if(colnum == 1) begin 
     				colnum <= 4'b1001;
     				rownum <= rownum - 2;
 				end
     			case(curr_letter)
     				"A": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
					   	vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"B": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
     				end
     				"C": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"D": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
     				end
     				"E": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"F": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
     				end
     				"G": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
     				end
     				"H": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"I": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
     				end
     				"J": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
     				end
     				"K": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"L": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"M": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"N": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 7] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 7] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 7] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 7] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 7] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 7] <= 0;
     				end
     				"O": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"P": begin
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"Q": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"R": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"S": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
     				end
     				"T": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
     				end
     				"U": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"V": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"W": begin
     					vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 7] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 7] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 7] <= 0;
     				end
     				"X": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
     				"Y": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 2] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
     				end
     				"Z": begin
     					vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 2][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 3][col_pos[colnum:colnum-1] + 6] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 4][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 5][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 6][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 3] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 4] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 5] <= 0;
						vga_letters[row_pos[rownum:rownum-1] + 7][col_pos[colnum:colnum-1] + 6] <= 0;
     				end
 				endcase
     		end
     	end

endmodule
