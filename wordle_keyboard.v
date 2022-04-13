`timescale 1ns / 1ps

module wordle_keyboard(Clk, reset, Start, Ack, U, D, L, R, C, q_I, q_Run, q_Done, curr_letter, done);
    /*  INPUTS */
	// Clock & Reset
	input Clk, reset, Start, Ack;
	input U, D, L, R, C;
	input done;  
	
	/*  OUTPUTS */
    output curr_letter;
	// store current state
	output q_I, q_Run, q_Done;
	reg[2:0] = state; 
	assign {q_I, q_Run, q_Done} = state;
	
	// aliasing states with one-hot state encoding
	localparam
	   QI = 3'b100,
	   QRUN = 3'b010,
	   QDONE = 3'b001;
    
	reg [4:0] col;
    reg [1:0] row;
    
    // Create keyboard arrangement as a localparam
    localparam keyboard = "ABCDEFGHIJKLMNOPQRSTUVWXYZ,.";
	
    // NSL AND SM
    always @ (posedge Clk, posedge reset)
	begin
	   if(reset) begin
			state <= QI;
			col <= 5'bXXXXX;
            row <= 2'bXX;
	    end else begin
           case(state)
               QI: 
                   if(Start)
                       state <= QRUN;
               QRUN: 
                   begin
		    if(done)
                       state <= QDONE;
                    if(U && row != 0)
                       row <= row - 1;
                    else if(D && row != 2)
                       row <= row + 1;
		    else if(L && col != 0)
                       col <= col -1;
                    else if(C && (row == 2 && col != 7 || row != 2 && col != 9))
                       col <= col + 1;
		   end
               QDONE: 
                   if(Ack)
                       state <= QI;
		default: state <= QI;
            endcase
        end
	end
    
    assign curr_letter = keyboard[row*10+col];
endmodule
