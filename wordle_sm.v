`timescale 1ns / 1ps

module wordle_sm(Clk, reset, U, Z, q_I, q_1G, q_2G, q_3G, q_4G, q_5G, q_6G, q_Done, Unlock);
    /*  INPUTS */
	// Clock & Reset
	input Clk, reset;
	input U, Z;
	
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
