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

//To do 
//wordle dictionary, finish transitions based on match 
//output

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
    
	output win, lose; //TO DO assign state
	
	reg [7:0] first_letter; 
	reg [7:0] second_letter;
	reg [7:0] third_letter; 
	reg [7:0] fourth_letter; 
	reg [7:0] fifth_letter; 
	reg [3:0] I; //counter for the guess 
	reg [3:0] J; //for wordle
	
	
	
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
			       if 
		       Q1G:
			       if(I==4) 
				state <= Q2G; 

		       Q2G: 
			       if(I==4)
				state <= Q3G; 
		       Q3G: 
			       if(I==4)
				state <= Q4G; 
		       Q4G: 
			       if(I==4)
				state <= Q5G; 
		       Q5G:
			       if(I==4) 
				state <= Q6G; 
		       Q6G:
			       if(I==4) 
				state <= QDONE; 
		       QDONE: 
			       if(C)
				state <= QI; 
			default: state <= QI;
		   endcase
             end
     	end
	
	//assign win = 
endmodule
