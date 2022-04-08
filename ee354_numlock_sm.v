`timescale 1ns / 1ps

module wordle_sm(Clk, reset, U, Z, q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, 
    q_G1011get, q_G1011, q_Bad, q_Opening, Unlock);
    /*  INPUTS */
	// Clock & Reset
	input Clk, reset;
	input U, Z;
	
	/*  OUTPUTS */
	// store current state
	output q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, q_G1011get, q_G1011, q_Bad, q_Opening;
	reg [10:0] state;	
	
	output q_I q_1G, q_2G, q_3G, 
	
	assign {q_I, q_G1get, q_G1, q_G10get, q_G10, q_G101get, q_G101, q_G1011get, q_G1011, q_Bad, q_Opening} = state;
	
	// aliasing states with one-hot state encoding
	localparam
	   QI = 11'b10000000000,
	   QG1GET = 11'b01000000000,
	   QG1 = 11'b00100000000,
	   QG10GET = 11'b00010000000,
	   QG10 = 11'b00001000000,
	   QG101GET = 11'b00000100000,
	   QG101 = 11'b00000010000,
	   QG1011GET = 11'b00000001000,
	   QG1011 = 11'b00000000100,
	   QB = 11'b00000000010,
	   QO = 11'b00000000001;
    
    // unlock output
	output Unlock;
	
	// Timer synchronization
	reg [3:0] Timerout_count;
	wire Timerout;
	assign Timerout = Timerout_count[0] * Timerout_count[1] * Timerout_count[2] * Timerout_count[3];
    
    // NSL AND SM
    always @ (posedge Clk, posedge reset)
	begin
	   if(reset) begin
			state <= QI;
			Timerout_count <= 4'bXXXX;
	    end else begin
           case(state)
               QI: 
                    if(U&&!Z) 
                        state <= QG1GET;
               QG1GET:
                    if(!U) 
                        state <= QG1;
               QG1: 
                    if(!U&&Z) 
                        state <= QG10GET;
                    else if(U==1)
                        state <= QB;
               QG10GET: 
                    if(!Z) 
                        state <= QG10;
               QG10: 
                    if(U&&!Z) 
                        state <= QG101GET;
                    else if(Z==1)
                        state <= QB;
               QG101GET: 
                    if(!U) 
                        state <= QG101;
               QG101:
                    if(U&&!Z) 
                        state <= QG1011GET;
                    else if(Z==1)
                        state <= QB;
               QG1011GET: 
                    if(!U) 
                        state <= QG1011;
               QG1011: state <= QO;
               QB: if(!U&&!Z) state <= QI;
               QO: if(Timerout) state <= QI;
			   default: state <= QI;
            endcase
        end
	end
	
	// Incrementing the timer
	always @ (posedge Clk)
	begin
	   if(!q_Opening)
			Timerout_count <= 0;
	   else
	        Timerout_count <= Timerout_count + 1;
	end
endmodule
