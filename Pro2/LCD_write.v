//Clock is 27Mhz 
module LCD_write(Clk, Strb, Reset, D_in, D_out, E, Busy, RS_out, RS);
	 
    output reg	         E;
    input			      Clk,Reset,Strb,RS;
    input      [7:0]    D_in;
    output reg	         Busy, RS_out;
    output reg [3:0]    D_out;

    parameter           DlyTime = 55000;   // 2ms delay @ 27MHz

    reg 	[16:0]         counter;
    reg 	[7:0]          Data;
    reg                 Enb, Dlbit;


    always @(posedge Clk) begin
		 if(Reset | !Enb)
		    counter <= 0;
		 else
		    counter <= counter + 1;
    end 


    always @ (negedge Clk) begin
	    if(Reset) begin
		     Data = 0;
			  Enb <= 0;
			  Dlbit <= 0;
			  D_out <= 0;
			  Busy <= 0;
		  end	else if(Strb) begin
			  Data = D_in[7:0];
			  Enb <= 1;
			  Busy <= 1;
			  if(RS) RS_out <= 1;
		  end
		
		  if(counter == 7'b100_0000) begin
			  Dlbit <= 1;
			  RS_out <= 0;
		  end	else if(counter == DlyTime) begin
			  Dlbit <= 0;
			  Enb <= 0;
			  Busy <= 0;
		  end

        if((Dlbit == 0)&&(Enb == 1)) begin
			  E <= counter[4];
		     if(counter[5] == 0)
			     D_out <= Data[7:4];
		     else
			     D_out <= Data[3:0];
		  end
   end
endmodule
