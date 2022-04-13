//////////////////////////////////////////////////////////////////////////////////
// Author: Kristian Bostic, Vy Ho
// Create Date:	4/7/2022
// File Name: wordle_top.v
// Description: Top design for Wordle
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module wordle_top (   
		MemOE, MemWR, RamCS, QuadSpiFlashCS, // Disable the three memory chips
        	ClkPort, // the 100 MHz incoming clock signal
		BtnL, BtnR, BtnU, BtnD, BtnC, // left, right, up, down, and center buttons
		Sw0, // Used for reset since no buttons left
		Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // LEDs for displaying state on Nexys4
		vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b //TODO: ADD VGA STUFF HERE
	  );


	/*  INPUTS */
	// Clock & Reset I/O
	input	ClkPort;
	input	BtnL, BtnR, BtnU, BtnD, BtnC;
	input Sw0; 
	
	/*  OUTPUTS */
	// Control signals on Memory chips 	(to disable them)
	output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;
	// Project Specific Outputs
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b; 
	// TODO: ADD VGA STUFF HERE
	
	/*  LOCAL SIGNALS */
	wire			reset, ClkPort;
	wire			board_clk, sys_clk;
	reg [26:0]	    	DIV_CLK;
	wire			U, D, L, R, C;
	wire 			curr_letter;  
	wire 			q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done;
	wire 			q_IKB, q_Run, q_DoneKB;
	wire 			win, lose; 
	reg [2*8-1:0] 		state;
	wire  			Start_Ack_SCEN; // debounced Start and Ack signal
	wire[9:0] 		CounterX; 
	wire[9:0] 		CounterY; 
	wire			inDisplayArea; 
	reg			vga_r, vga_g, vga_b; 

	
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

	
	assign reset = Sw0;
	
//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
	if (reset)
			DIV_CLK <= 0;
	else
		DIV_CLK <= DIV_CLK + 1'b1;
	end		
//------------	
	// pick a divided clock bit to assign to system clock
	// your decision should not be "too fast" or you will not see you state machine working
	assign	sys_clk = DIV_CLK[25]; // DIV_CLK[25] (~1.5Hz) = (100MHz / 2**26)
	

//------------
// INPUT: SWITCHES & BUTTONS
	assign {U, D, L, R, C} = {BtnU, BtnD, BtnL, BtnR, BtnC};

//------------
// DESIGN
	wordle_sm SM1(.Clk(sys_clk), .reset(reset), .Start(Start_Ack_SCEN), .Ack(Start_Ack_SCEN), .C(C), .curr_letter(curr_letter), .q_I(q_I), 
		      .q_1G(q_1G), .q_2G(q_2G), .q_3G(q_3G), .q_4G(q_4G), .q_5G(q_5G), .q_6G(q_6G), .q_Done(q_Done), .win(win), .lose(lose));	
	
	wordle_keyboard KB1(.Clk(sys_clk), .reset(reset), .Start(Start_Ack_SCEN), .Ack(Start_Ack_SCEN), .U(U), .D(D), .L(L), .R(R), 
			    .q_I(q_IKB), .q_Run(q_Run), .q_Done(q_DoneKB), .curr_letter(curr_letter));
	
	ee201_debouncer #(.N_dc(25)) ee201_debouncer_1 (.CLK(sys_clk), .RESET(reset), .PB(BtnC), .DPB( ), .SCEN(Start_Ack_SCEN), .MCEN( ), .CCEN( ));	
	
	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

	always @ ( q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done )
	begin : OUTPUT_STATE_AS_STRING
		(* full_case, parallel_case *) // to avoid prioritization (Verilog 2001 standard)
		case ( {q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done} )
			8'b10000000: state = "QI";
			8'b01000000: state = "Q1";
			8'b00100000: state = "Q2";
			8'b00010000: state = "Q3";
			8'b00001000: state = "Q4";
			8'b00000100: state = "Q5";
			8'b00000010: state = "Q6";
			8'b00000001: state = "QD";
		endcase
	end
	
//------------
// OUTPUT: LED
	
	assign {Ld7, Ld6, Ld5, Ld4} = {q_I, q_Sub, q_Mult, q_Done};
	assign {Ld3, Ld2, Ld1, Ld0} = {BtnL, BtnU, BtnR, BtnD}; // Reset is driven by BtnC
	
//------------
// TODO: OUTPUT: VGA Display
	always @ (q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done) begin: VGA_DISPLAY
		if (~q_Done)
			//
			
		else
		
	
	end
		
	
endmodule


