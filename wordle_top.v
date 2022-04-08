//////////////////////////////////////////////////////////////////////////////////
// Author: Kristian Bostic, Vy Ho
// Create Date:	4/7/2022
// File Name: wordle_top.v
// Description: Top design for Wordle
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module ee354_numlock_top (   
		MemOE, MemWR, RamCS, QuadSpiFlashCS, // Disable the three memory chips
        	ClkPort, // the 100 MHz incoming clock signal
		BtnL, BtnR, BtnU, BtnD, BtnC, // left, right, up, down, and center buttons
		// ADD VGA STUFF HERE
	  );


	/*  INPUTS */
	// Clock & Reset I/O
	input	ClkPort;
	input	BtnL, BtnR, BtnU, BtnD, BtnC;
	
	/*  OUTPUTS */
	// Control signals on Memory chips 	(to disable them)
	output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;
	// Project Specific Outputs
	// ADD VGA STUFF HERE
	
	/*  LOCAL SIGNALS */
	wire			reset, ClkPort;
	wire			board_clk, sys_clk;
	wire [1:0]		ssdscan_clk;
	reg [26:0]	    DIV_CLK;
	wire 			U, Z;
	wire 			q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, q_G1011get, q_G1011, q_Opening, q_Bad;
	wire 			Unlock;	
	reg [3:0] 		state_num;
	reg [3:0] 		state_sum;
	wire [3:0] 		selected_state;
	reg 			hot1_state_error;	
	reg 			selected_state_value;	
	reg [3:0]		SSD;
	wire [3:0]		SSD0, SSD1, SSD2, SSD3;	
	reg [6:0]  		SSD_CATHODES;
	wire [6:0] 		SSD_CATHODES_blinking;	

	
//------------	
// Disable the three memories so that they do not interfere with the rest of the design.
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	
//------------
// CLOCK DIVISION

	// The clock division circuitary works like this:
	//
	// ClkPort ---> [BUFGP2] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> DIV_CLK
	// DIV_CLK ---> [constant assignment] ---> sys_clk;
	
	BUFGP BUFGP1 (board_clk, ClkPort);

// As the ClkPort signal travels throughout our design,
// it is necessary to provide global routing to this signal. 
// The BUFGPs buffer these input ports and connect them to the global 
// routing resources in the FPGA.

	
	assign reset = BtnC;
	
//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
// TODO: create the sensitivity list
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			// just incrementing makes our life easier
// TODO: add the incrementer code
		DIV_CLK <= DIV_CLK + 1'b1;
	end		
//------------	
	// pick a divided clock bit to assign to system clock
	// your decision should not be "too fast" or you will not see you state machine working
	assign	sys_clk = DIV_CLK[25]; // DIV_CLK[25] (~1.5Hz) = (100MHz / 2**26)
	

//------------
// INPUT: SWITCHES & BUTTONS
	// BtnL/BtnR is abstract
	// let's form some wire aliases with easier naming (U and Z, for UNO and ZERO) 

// TODO: add the lines to assign your I/O inputs to U and Z
	assign {U,Z} = {BtnL, BtnR};
	
	
	// switches used to send the value of a specific state to LD6

	assign selected_state = {Sw3, Sw2, Sw1, Sw0};
	

//------------
// DESIGN

// TODO: finish the port list
// 
	ee354_numlock_sm SM1(.Clk(sys_clk), .reset(reset), .U(U), .Z(Z),
								.q_I(q_I), .q_G1get(q_G1get), .q_G1(q_G1), .q_G10get(q_G10get), 
								.q_G10(q_G10), .q_G101get(q_G101get), .q_G101(q_G101), .q_G1011get(q_G1011get),
								.q_G1011(q_G1011), .q_Opening(q_Opening), .q_Bad(q_Bad), .Unlock(Unlock)
								);		

								
	
	
	// convert the 1-hot state to a hex-number for easy display	
	localparam 	QI_NUM 			=	4'b0000,
				QG1GET_NUM		=	4'b0001,
				QG1_NUM			=	4'b0010,
				QG10GET_NUM		=	4'b0011,
				QG10_NUM		=	4'b0100,
				QG101GET_NUM	=	4'b0101,
				QG101_NUM		=	4'b0110,
				QG1011GET_NUM	=	4'b0111,
				QG1011_NUM		=	4'b1000,
				QOPENING_NUM	=	4'b1001,
				QBAD_NUM		=	4'b1010;
	
	always @ ( q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, q_G1011get, q_G1011, q_Opening, q_Bad )
	begin : ONE_HOT_TO_HEX
		(* full_case, parallel_case *) // to avoid prioritization (Verilog 2001 standard)
		case ( {q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, q_G1011get, q_G1011, q_Opening, q_Bad} )		

// TODO: complete the 1-hot encoder	
			11'b10000000000: state_num = QI_NUM;
			11'b01000000000: state_num = QG1GET_NUM;
			11'b00100000000: state_num = QG1_NUM;
			11'b00010000000: state_num = QG10GET_NUM;
			11'b00001000000: state_num = QG10_NUM;
			11'b00000100000: state_num = QG101GET_NUM;
			11'b00000010000: state_num = QG101_NUM;
			11'b00000001000: state_num = QG1011GET_NUM;
			11'b00000000100: state_num = QG1011_NUM;
			11'b00000000010: state_num = QOPENING_NUM;
			11'b00000000001: state_num = QBAD_NUM;
		endcase
	end
	
	
//------------
// OUTPUT: LEDS
	assign {Ld7,Ld6,Ld5,Ld4} = state_num;
	
	// display 1-hot state errors
	// add all of the state bits.  if the sum != 1 then we have a problem
	// we need to support 0-10 so sum must be 4-bit
		
	always @ (q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, q_G1011get, q_G1011, q_Opening, q_Bad)
	begin
	// TODO: finish the logic for state_sum
		state_sum = q_I + q_G1get + q_G1 + q_G10get + q_G10 + q_G101get+ q_G101 + q_G1011get + q_G1011 + q_Opening + q_Bad;
	end
	
	// we could do the following with an assign statement also. 
	// Ofcourse, then we need to declare hot1_state_error as a wire.
	// assign hot1_state_error = (state_sum != 4'b0001) ? 1'b1 : 1'b0;
	// Or we can avoid this intermediate hot1_state_error altogether!
	// assign Ld2 = (state_sum != 4'b0001) ? 1'b1 : 1'b0;

	always @ (state_sum)
	begin
		hot1_state_error = (state_sum != 4'b0001) ? 1'b1 : 1'b0;
	end
	
	assign Ld2 = hot1_state_error;	
	
	// display the value of selected state
	
	always @ ( selected_state, q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, q_G1011get, q_G1011, q_Opening, q_Bad )
	begin : SELECTED_STATE_VALUE
		(* full_case, parallel_case *) // to avoid prioritization (Verilog 2001 standard)
		case ( selected_state )		
			QI_NUM: 			selected_state_value = q_I;
			QG1GET_NUM: 		selected_state_value = q_G1get;
			QG1_NUM: 			selected_state_value = q_G1;
			QG10GET_NUM: 		selected_state_value = q_G10get;			
			QG10_NUM: 			selected_state_value = q_G10;
			QG101GET_NUM: 		selected_state_value = q_G101get;
			QG101_NUM: 			selected_state_value = q_G101;
			QG1011GET_NUM: 		selected_state_value = q_G1011get;	
			QG1011_NUM: 		selected_state_value = q_G1011;	
			QOPENING_NUM: 		selected_state_value = q_Opening;	
			QBAD_NUM: 			selected_state_value = q_Bad;			
		endcase
	end	
	assign Ld3 = selected_state_value;
	
	assign {Ld1, Ld0} = {U, Z};
	
	
	
//------------
// SSD (Seven Segment Display)

// TODO: finish the assignment for SSD3, SSD2, SSD1	Consider using the concatenation operator
	assign SSD3 = {1'b0, q_Bad, q_Opening, q_G1011};
	assign SSD2 = {q_G1011get, q_G101, q_G101get, q_G10};
	assign SSD1 = {q_G10get, q_G1, q_G1get, q_I};
	assign SSD0 = state_num;
	
	
	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//
	
	assign ssdscan_clk = DIV_CLK[19:18];
	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
// TODO: inactivate the following four annodes
	assign {An7,An6,An5,An4} = 4'b1111; 
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
		
// TODO: finish the multiplexer to scan through SSD0-SSD3 with ssdscan_clk[1:0]
			2'b00: SSD = SSD0;
			2'b01: SSD = SSD1; 
			2'b10: SSD = SSD2; 
			2'b11: SSD = SSD3; 
		endcase 
	end	
	
	
	// and finally convert hex to ssd
// TODO: write the code to enable "blinking"
	// we want the CATHODES to turn "on-off-on-off" with system clock
	// while we are in state: OPENING
	//make the dot point constantly OFF so we can differentiate your .bit file from the "TA" .bit file
	assign SSD_CATHODES_blinking = SSD_CATHODES | ( {7{q_Opening & sys_clk}} );
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES_blinking, 1'b1};

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)
// TODO: write cases for 0-9. A-F are already given to you. 
			4'b0000: SSD_CATHODES = 7'b0000001 ; // 0
			4'b0001: SSD_CATHODES = 7'b1001111 ; // 1
			4'b0010: SSD_CATHODES = 7'b0010010 ; // 2
			4'b0011: SSD_CATHODES = 7'b0000110 ; // 3
			4'b0100: SSD_CATHODES = 7'b1001100 ; // 4
			4'b0101: SSD_CATHODES = 7'b0100100 ; // 5
			4'b0110: SSD_CATHODES = 7'b0100000 ; // 6
			4'b0111: SSD_CATHODES = 7'b0001111 ; // 7
			4'b1000: SSD_CATHODES = 7'b0000000 ; // 8
			4'b1001: SSD_CATHODES = 7'b0000100 ; // 9
			4'b1010: SSD_CATHODES = 7'b0001000 ; // A
			4'b1011: SSD_CATHODES = 7'b1100000 ; // B
			4'b1100: SSD_CATHODES = 7'b0110001 ; // C
			4'b1101: SSD_CATHODES = 7'b1000010 ; // D
			4'b1110: SSD_CATHODES = 7'b0110000 ; // E
			4'b1111: SSD_CATHODES = 7'b0111000 ; // F    
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end	
	
endmodule


