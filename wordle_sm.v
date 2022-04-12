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

module wordle_sm(Clk, reset, Start, Ack, C, curr_letter, q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done);
    /*  INPUTS */
	// Clock & Reset
	input Clk, reset, Start, Ack;
	input C;
	input curr_letter;  
	
	/*  OUTPUTS */
	// store current state
	reg [7:0] state;	
	output q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done;
	assign {q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done} = state;
	
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
    
	output win, lose; 
	
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
	   word19 = "MINUS";
	
	reg [7:0] first_letter; 
	reg [7:0] second_letter;
	reg [7:0] third_letter; 
	reg [7:0] fourth_letter; 
	reg [7:0] fifth_letter; 
	reg [3:0] I; //counter to indicate position in guess, helps with state transition
	reg [39:0] randomWord; //5 ascii character word = 40 bits
	
    	//Selecting Wordle of the Day
	always @(q_I) begin: WordleOfDay //Selects one of the 20 words to be Wordle of the day during Initial State 
		reg[4:0] randomNum; //TODO 
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
	   if(reset) 
	     begin
		state <= QI;
		first_letter <= 8'bXXXXXXXX;
		second_letter <= 8'bXXXXXXXX;
		third_letter <= 8'bXXXXXXXX;
		fourth_letter <= 8'bXXXXXXXX;
		fifth_letter <= 8'bXXXXXXXX;
	     end 
	   else 
	     begin 
		   case(state)
		       QI: 
			   if(C)  
			   state <= Q1G;
			   I <= 0; 
			   first_letter <= 0; 
			   second_letter <= 0;
			   third_letter <= 0; 
			   fourth_letter <= 0; 
			   fifth_letter <= 0; 
		       Q1G:
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
		       Q2G: 
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
		       Q3G: 
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
		       Q4G: 
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
		       Q5G:
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
		       Q6G:
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
		       QDONE: 
			   if(C)
				state <= QI; 
			default: state <= QI;
		   endcase
             end
     	end
	
	assign win = q_Done*({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord);
	assign lose = q_Done*~({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord); 
endmodule
