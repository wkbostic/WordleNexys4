`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Create Date:   04/17/2022
// Design Name:   wordle_sm
// Testbench name: wordle_sm_tb
////////////////////////////////////////////////////////////////////////////////

module wordle_sm_tb;

	// Inputs
	reg Clk = 0;
	reg Start, Ack, reset;
	reg C;
	reg [7:0] curr_letter; 
	
	// Outputs
	wire q_I;
	wire q_1G;
	wire q_2G;
	wire q_3G;
	wire q_4G;
	wire q_5G;
	wire q_6G;
	wire q_Done;
	wire win;
	wire lose;
	wire[2:0] I;
	integer Clk_cnt, i, k; 
	
	localparam
		guessWord = "HAIKU", 
		guessWord2 = "HAIKO",
		randomWord = "HAIKU";

	// Instantiate the Unit Under Test (UUT)
	wordle_sm uut (
		.Clk(Clk), 
		.reset(reset), 
		.q_I(q_I), 
		.q_1G(q_1G), 
		.q_2G(q_2G), 
		.q_3G(q_3G), 
		.q_4G(q_4G), 
		.q_5G(q_5G), 
		.q_6G(q_6G), 
		.q_Done(q_Done), 
		.win(win), 
		.lose(lose),
		.C(C),
		.curr_letter(curr_letter),
		.randomWord(randomWord),
		.Start(Start), 
		.Ack(Ack),
		.I(I)
	);
	
	initial
	  begin  : CLK_GENERATOR
		Clk = 0;
		forever
		   begin
			  #10 Clk = ~Clk;
		   end 
	  end
	
	initial
	  begin  : RESET_GENERATOR
		reset = 1;
		#20; reset = 0;
	  end
	  
	initial
	  begin  : CLK_COUNTER
		Clk_cnt = 0;
		#2; // wait until a little after the positive edge
		forever
		   begin
			  #10; Clk_cnt = Clk_cnt + 1;
		   end 
	  end
	
	task run_test;
	  integer Start_clock_count, Clocks_taken;
		begin
			// test begin
			@(posedge Clk);
			#2;  // a little (2ns) after the clock edge
			Start = 1;		// After a little while provide START
			@(posedge Clk); // After waiting for a clock
			#5;
			Start = 0;	// After a little while remove START
			Start_clock_count = Clk_cnt;
			wait (q_Done);  // wait until done
			#5;
			Clocks_taken = Clk_cnt - Start_clock_count;
			//$display ("           Clock taken for this test = %0d. \n", Clocks_taken);
			#4;  // wait a little (4ns) (we want to show a little delay to represent
					 // that the Higher-Order system takes a little time to respond)
			Ack = 1;	// Provide ACK
			@(posedge Clk); // Wait for a clock
			#1;
			Ack = 0;	// Remove ACK
			// test  end
		end
	endtask
	
	initial begin: WORD_GUESSING
		k = 39;
		wait(!reset); //wait for reset to be over
		for (i=1; i<=31; i=i+1) begin //first guess is correct
			C = 0; #(20*4); C = 1; #20;
			curr_letter = guessWord[k-:8];
			k = k - 8;
			if (i%5==0) k = 39; 
			$display ("\nLetter entered: %s", curr_letter); 
			if (win) $display("Correct guess!"); 
			else if (lose)$display("You lost!"); 
			else $display("Done State Not Reached");
		end
		for (i=1; i<=31; i=i+1) begin //last guess is correct
			C = 0; #(20*4); C = 1; #20;
			curr_letter = guessWord2[k-:8];
			if (i == 30) curr_letter = "U"; //correction
			k = k - 8;
			if (i%5==0) k = 39; 
			$display ("\nLetter entered: %s", curr_letter); 
			if (win) $display("Correct guess!"); 
			else if (lose)$display("You lost!"); 
			else $display("Done State Not Reached");
		end		
		$display ("\n All tests concluded.\n Current Clock Count = %0d \n", Clk_cnt);
		$stop; 
	end 
      
endmodule

