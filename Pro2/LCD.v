
module LCD(CLK_27, LCD_FPGA_DB,LCD_FPGA_E,LCD_FPGA_RS,LCD_FPGA_RW,RESET,GPIO_SW_E, GPIO_SW_N,GPIO_LED,     Lcd_data, LCDfinish ,show,mark1,mark2);

    input                 CLK_27;
    input                 RESET, GPIO_SW_E, GPIO_SW_N;
    output    [3:0]      LCD_FPGA_DB;
    output    reg         LCD_FPGA_RW;
    output 		          LCD_FPGA_E, LCD_FPGA_RS;
    output  reg [7:0]      GPIO_LED;
	 reg [4:0] state;
	 
	input [7:0] Lcd_data;
	output reg LCDfinish;
	input show;
	input mark1;
	input mark2;
	
	
	//if finish is high can set the show to 1, monitor finish if 0, then set show to 0 and wait the finish

    parameter Idle = 0,   LS1=1,   LS2=2,  LS3=3,   LS4=4,   LS5=5,   LS6=6,
              LS7=7,      LS8=8,   LS9=9,  LS10=10, LS11=11, LS12=12, LS13=13,
			     LS14=14,    LS15=15, LS16=16;
			 

    reg        [4:0]      CS, NS;    // Current state , next state
    reg                   Pon_Dly;
    wire                  Busy;
    reg        [7:0]      Data;
    reg                   Strb, RS;
    reg        [7:0]      LED;
    reg        [4:0]      Curpos;


    LCD_write L1( .Clk(CLK_27),   .Strb(Strb),  .Reset(RESET),        .D_in(Data), .D_out(LCD_FPGA_DB), 
	               .E(LCD_FPGA_E), .Busy(Busy),  .RS_out(LCD_FPGA_RS), .RS(RS) );

    always @(posedge CLK_27) begin//state change
	    if(RESET) begin
		    CS <= Idle;
			//LCDfinish <= 1;
	    end else begin 
		    CS <= NS;
	    end

    end


    always@(posedge CLK_27) begin//
	     if(GPIO_SW_E | GPIO_SW_N) begin// anyone of the button cause power on delay
		      Pon_Dly <= 1;
		  end else begin
		      Pon_Dly <= 0;
		  end
	     /*if(RESET) begin// reset
		      GPIO_LED <= 0;
			  //LCDfinish<=1;
	     end else begin
		      GPIO_LED[7:0] <= 8'b1111_1111;
	     end*/
	 
    end


    always @(*) begin//   CS,
	
	     RS <= 0;                    // RS=0 is Command Mode
	     LCD_FPGA_RW <= 0;           // Always write.
	     Data <= 0;
	     Strb <= 0;
	     //NS <= Idle;
        case(CS)
	        Idle:	begin
							state <= 0;
				         if(Pon_Dly) NS <= LS1; // P on means start
				         else NS <= Idle;
			         end
	         LS1:  begin
				         Data <= 8'b0010_1000; // Configure LCD in 2 line mode
				         Strb <= 1;
				         NS <= LS2;
							state <= 1;
			         end
	         LS2:  begin
                     NS <= LS3;
							state <=2;
			         end
	         LS3:  begin
							state <=3;
				         if(Busy)  begin 
					         NS <= LS3;
				         end	else
						      NS <= LS4;
			         end
	         LS4:  begin
				         Data <= 8'b0000_1111;   // 8'h0F is Cursor ON, display ON, blink ON 
				         Strb <= 1;
				         NS <= LS5;state <=4;
			         end
	         LS5:  begin state <=5;
				         if(Busy) begin
					         NS <= LS5;
				         end else
                        NS <= LS6;
			         end
	         LS6:  begin
         				Data <= 8'b0000_0001;   // Clear display. Cursor home
			         	Strb <= 1;
				         NS <= LS7;state <=6;
			         end
            LS7:  begin state <=7;
				         if(Busy) begin
					         NS <= LS7;
					      end else
                        NS <= LS8;
			         end
	         LS8:  begin
				         Data <= 8'b0000_0110;   // No shift, increment
				         Strb <= 1;
				         NS <= LS9;state <=8;
			         end
/*********************************************************************************************************************************************/					 
	         LS9:  begin  GPIO_LED[7:0] <= 8'b0000_0001;//                   first wait
                     if(Busy) begin
							   NS <= LS9;
							end else begin
                        NS <= LS10;
						LCDfinish<=1;
						end
			         end
					 
			LS10:  begin state <=10;
					GPIO_LED[7:0] <= 8'b0000_0011;   // prepare to send the receiving data
					if(show) begin
					NS <= LS11; LCDfinish <= 0;
					end else begin
					NS <= LS10; LCDfinish <=1;
					end
				   end
					 
	        LS11:  begin state <=11;GPIO_LED[7:0] <= 8'b0000_0111;//GPIO_LED[7:0] <= 8'b0000_0000;
						if(Lcd_data==10) begin 			// Up until now, we were in command mode xiexiexie
				         NS<= LS13;
						 end else begin
						 RS <= 1;                // RS=1 shifts to Data mode
				         Strb <= 1;
				         Data <= Lcd_data;       // Write next data byte
				         NS <= LS12;
						 end
			         end
	        LS12:  begin state <=12;GPIO_LED[7:0] <= 8'b0000_1111;
				         if(Busy) begin
							   NS <= LS12;
							end else begin
							   NS <= LS13;
							   LCDfinish<=1;
							   end
			         end
					 
			
					 
	        LS13:  begin  state <=13;GPIO_LED[7:0] <= 8'b0001_1111;//get new line			
						if(mark1)//change line
						begin 
							Data <= 8'hC0;Strb <= 1; 
							NS <= LS9;
						end else begin
							NS<=LS14;
						end
									 // When cursor is on line 1, position 16
				                     // Issue command to go to next line (8'hC0) 
                  end
				  
			LS14: begin state <=14;GPIO_LED[7:0] <= 8'b0011_1111;
							if(mark2)
							begin
								NS <= LS15;
								LCDfinish<=1;//finished
							end	else begin
								NS <= LS9;//not finished
					end	
					end					
				  
	       LS15:  begin  state <=15;GPIO_LED[7:0] <= 8'b0111_1111;
				        
						LCDfinish<=0;
						Data <= 8'b0000_0001;   // Clear display. Cursor home
			         	Strb <= 1;
						NS <= LS16;
						
						
			         end	

			LS16: begin	state <=16;GPIO_LED[7:0] <= 8'b1111_1111;
						 if(Busy) begin
							   NS <= LS16;
							end else begin
                        NS <= LS10;
						end
						end
			 default:  begin NS <= Idle;GPIO_LED[7:0] <= 8'b0000_0000; end
        endcase
    end
 
 
    /*always @(negedge CLK_27) begin
			if(RESET) begin
				Curpos <= 0; 
			end 
    end*/
 
 
    
 
endmodule
