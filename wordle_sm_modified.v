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

module wordle_sm(Clk, reset, Start, Ack, C, q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done, win, lose, randomWord, curr_letter, I);
		//first_letter, second_letter, third_letter, fourth_letter, fifth_letter)
    /*  INPUTS */
	// Clock & Reset
	input Clk, reset, Start, Ack;
	input C;
	input[39:0] randomWord;
	input[7:0] curr_letter;
	
	/*  OUTPUTS */
	// store current state
	reg [7:0] state;	
	output q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done;
	assign {q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done} = state;
	
	// Output to be used by top design 
	output win, lose;
	//output first_letter, second_letter, third_letter, fourth_letter, fifth_letter;
	//output randomWord; 
	//output I; 
	
	// Local variables, dealing with current guess 
	reg [7:0] first_letter, second_letter, third_letter, fourth_letter, fifth_letter; 
	output reg [2:0] I; //counter to indicate position in guess, helps with state transition 
	//wire curr_letter; //taken from keyboard 
	
	// Variables dealing with selecting Wordle of the Day 
	//reg [39:0] randomWord; //5 ascii character word = 40 bits
	//wire rnd; //random number 
	
	assign win = q_Done&({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord);
	assign lose = q_Done&~({first_letter, second_letter, third_letter, fourth_letter, fifth_letter} == randomWord); 
	
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
			 begin
			       if(C) begin 
				   state <= Q1G;
				   I <= 0; 
				   first_letter <= 0; 
				   second_letter <= 0;
				   third_letter <= 0; 
				   fourth_letter <= 0; 
				   fifth_letter <= 0;
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
				   if( ({first_letter, second_letter, third_letter, fourth_letter, fifth_letter}-randomWord) == 0)
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
				   else if (I==3'b100) //if I = 4 
					fifth_letter <= curr_letter; 
					else begin
					   if( ({first_letter, second_letter, third_letter, fourth_letter, fifth_letter}-randomWord) == 0)
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
				   if( ({first_letter, second_letter, third_letter, fourth_letter, fifth_letter}-randomWord) == 0)
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
				   if( ({first_letter, second_letter, third_letter, fourth_letter, fifth_letter}-randomWord) == 0)
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
				if( ({first_letter, second_letter, third_letter, fourth_letter, fifth_letter}-randomWord) == 0)				  	state <= QDONE; 
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

endmodule
