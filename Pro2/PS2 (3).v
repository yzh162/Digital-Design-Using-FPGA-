`timescale 1ns / 1ps

module PS2(USER_CLK,  CLK_27, LCD_FPGA_DB,LCD_FPGA_E,LCD_FPGA_RS,LCD_FPGA_RW,GPIO_SW_E, GPIO_SW_N, GPIO_LED,
           GPIO_SW_0,KEYBOARD_CLK, KEYBOARD_DATA, FPGA_SERIAL1_TX,
           PIEZO_SPEAKER);

	input 				CLK_27;
	input      			GPIO_SW_0;
	input 				GPIO_SW_E, GPIO_SW_N;
    input               USER_CLK;
	output 	 	[7:0]		GPIO_LED;
	output              FPGA_SERIAL1_TX;
	input               KEYBOARD_CLK, KEYBOARD_DATA;
	output reg        PIEZO_SPEAKER;
	wire			finish1;
	output            	LCD_FPGA_RW;
	output     [3:0]    LCD_FPGA_DB; 
	output 		        LCD_FPGA_E, LCD_FPGA_RS; 
	reg 	   [7:0]	PS2State;

	reg        [7:0]    TX_Data;
	reg                 TX_Request;	
	
	
	
	wire				Busy;
	wire 				LCDfinish;
	reg 				mark1,mark2;  //Busy1 is to judge if LCD is finish 
	reg 			soundfinish;
	
	reg        [7:0]    Lcd_data;

	reg		   [11:0]	ADD1;
	reg		   [11:0]	ADD2;
	reg		   [9:0]	ADD3;
	reg		   [9:0]	ADD4;
	reg		   [9:0]	ADD5;
	reg		   [9:0]	ADD6;
	reg		   [11:0]	ADD7;
	reg		   [11:0]	ADD8;
	reg		   [11:0]	ADD9;
	reg		   [11:0]	ADD10;

	reg		   [3:0]	Num1;
	reg		   [3:0]	Num2;
	reg		   [3:0]	Num3;
	reg		   [3:0]	Num4;
	reg		   [3:0]	Num5;
	reg		   [3:0]	Num6;
	reg		   [7:0]	Num7;
	reg		   [7:0]	Num8;
	reg		   [7:0]	operator;
	reg		   [7:0]	out1;
	reg		   [7:0]	out2;
	reg		   [7:0]	out3;
	reg		   [10:0]	out4;
	reg 			[26:0] shift;
	reg 			[43:0] shift1;
	reg 			[7:0] thousands1;
   reg 			[7:0] hundreds1;
   reg 			[7:0] tens1;
   reg 			[7:0] ones1;
   reg 			[7:0] h1;
   reg 			[7:0] l1;
   reg 			show;
   reg [24:0] counter;

	parameter N = 7000000;

   reg [3:0] mill;
   reg [3:0] tethou;
   reg [3:0] thousands;
   reg [3:0] hundreds;
   reg [3:0] tens;
   reg [3:0] ones;

	reg soundreq;
   reg    flag;
	reg		   [19:0]	otput1;
	reg        [31:0]   Ctr; 
	reg        [23:0]   BeatDuration;
   reg        [23:0]   BeatSpeed;
   reg        [3:0]    BeatCtr; 
	integer   i;

	reg                 KeyClk, KeyData;
	 
	wire       [7:0]    ScanValue;
	wire                CodeValid;

	wire RST;
	assign RST = GPIO_SW_0;
  											
   rs232	 Transmitter(USER_CLK, RST, FPGA_SERIAL1_TX, TX_Request, TX_Data, Busy);
	sound ss1(USER_CLK, PIEZO_SPEAKER1, soundreq ,finish1);																
	ps2kbd   Keyboard(KeyClk, KeyData, ScanValue, CodeValid);
	LCD Display(CLK_27, LCD_FPGA_DB,LCD_FPGA_E,LCD_FPGA_RS,LCD_FPGA_RW,RST,GPIO_SW_E, GPIO_SW_N,GPIO_LED, Lcd_data, LCDfinish ,show,mark1,mark2);


	always @(posedge USER_CLK) begin : MainClk
		KeyClk <= KEYBOARD_CLK;
		KeyData <= KEYBOARD_DATA;   				
		soundreq <= 0;
		soundfinish <= finish1;
		PIEZO_SPEAKER<=PIEZO_SPEAKER1;
		
		if(RST) begin       					  	
			PS2State <= 0;
		    TX_Request <= 0; 
			show<=0;		
			mark1<=0;
			mark2<=0;	
		end
		
		case (PS2State)	
			
			 0: begin  PS2State <= 1;    end
			
			 1: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=2;counter <=0;
							end
				end
			
			 2: begin   mark1<=0;mark2<=0;show <=0;counter <= 0;PS2State <=  3;    end
			 3: begin   PS2State <= 4; end
			 4: begin  PS2State <= 5;    end
			
			 5: begin      PS2State <= 6;         end
			
			 6: begin      PS2State <=  7;    end
			 
			 7: begin     if(soundfinish) begin PS2State <= 8;

									end  else begin
									soundreq<=0;
									end
									end
//==================================================================================================================================				
			 8:  begin if(~CodeValid) begin PS2State <= 8;end
					else begin
					case(ScanValue)
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9" : 
						begin
							PS2State <= 9;              // valid digit. write it
						end
						"E":begin                     
						PS2State<=97;
						end
						default:begin  soundreq <= 1;PS2State <= 8; end
					endcase
				end
				end

			9: begin Lcd_data <= ScanValue; PS2State <= LCDfinish ? 10 : 9; TX_Data <= ScanValue; TX_Request <= 1; Num1<=ScanValue-48;    end
			
			10: begin  TX_Request <= 0;   show <= 1; PS2State <=  11;   end
			
			11: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; show<=0;PS2State <= 12; 
						end
						end
			12: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=13;counter <=0;
							end
				end
//************************************************************************************************
			13: begin  if(~CodeValid) begin PS2State <= 13;end
				 else begin
					case(ScanValue)
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9" : 
						begin
							PS2State <= 14;              // valid digit. write it
						end
						"+" , "*" , "<" , ">" : 
						begin
							PS2State <= 24; ADD1= {4'b0000,4'b0000,Num1};   // valid digit. write it
						end
						"E":begin PS2State<=97;end
						default:begin soundreq <= 1;PS2State <= 13; end
					endcase
				end
			end
			
			14: begin      Lcd_data <= ScanValue; PS2State <= 15;  TX_Data <= ScanValue; TX_Request <= 1;  Num2<=ScanValue-48; end
			
			15: begin    TX_Request <= 0;   show <= 1; PS2State <=  16;   end
			16:  begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 18;show<=0;
						end
						end
//************************************************************************************************

			17:  if(~CodeValid) PS2State <= 17;
				 else begin
					case(ScanValue)
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9" : 
						begin
							PS2State <= 19;              // valid digit. write it
						end
						"+" , "*" , "<" , ">" : 
						begin
							PS2State <= 24; ADD1= {4'b0000,Num1,Num2};     // valid digit. write it
						end
						"E":begin PS2State<=97;end
						default:begin soundreq <= 1;PS2State <= 17; end
					endcase
				end
			18: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=17;counter <=0;
							end
				end
			
			19: begin    Lcd_data <= ScanValue; PS2State <= 20; TX_Data <= ScanValue; TX_Request <= 1;  Num3<=ScanValue-48;         end
			
			20: begin   TX_Request <= 0;    show <= 1; PS2State <=  21; ADD1= {Num1,Num2,Num3};    end
			21:  begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 23;show<=0;
						end
			end
//****************************OPERATOR******************************************************
			22:  if(~CodeValid) PS2State <= 22;
				 else begin
					case(ScanValue)
						"+" , "*" , "<" , ">" : 
						begin
							PS2State <= 24;              // valid digit. write it
						end
						"E":begin PS2State<=97;end
						default:begin soundreq <= 1;PS2State <= 22; end//sound?
					endcase
				end
			23: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=22;counter <=0;
							end
				end
			
			24: begin   Lcd_data <= ScanValue ;  PS2State <= 25 ; 
			TX_Data <= ScanValue; TX_Request <= 1; operator<= ScanValue;            end
			
			25: begin     TX_Request <= 0;  show <= 1; PS2State <= 26;         end
			26: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 28;show<=0;
						end
			end
//****************************ADD2 1**************************************************************
			27:  if(~CodeValid) PS2State <= 27;
				 else begin
					case(ScanValue)
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9" : 
						begin
							PS2State <= 29;              // valid digit. write it
						end
						"E":begin PS2State<=97;end
						default:begin soundreq <= 1;PS2State <= 27; end
					endcase
				end
			28:begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=27;counter <=0;
							end
				end
			
			29: begin    Lcd_data <= ScanValue; TX_Data <= ScanValue; TX_Request <= 1;  Num4 <=ScanValue-48;PS2State <=  30; show<=1; end
			
			30: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 32;show<=0;  TX_Request <= 0;    
						end
			end
//*******************************ADD2 2*****************************************************************			
			31:  if(~CodeValid) PS2State <= 31;
				 else begin
					case(ScanValue)
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9" : 
						begin
							PS2State <= 33;              // valid digit. write it
						end
						"=" : 
						begin
							PS2State <= 43; ADD2= {4'b0000,4'b0000,Num4};             // valid digit. write it
						end
						"E":begin PS2State<=97;end
						default:begin soundreq <= 1;PS2State <= 31; end
					endcase
				end
			32: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=31;counter <=0;
							end
				end
			
			33: begin Lcd_data <= ScanValue;TX_Data <= ScanValue;TX_Request<=1;Num5<=ScanValue-48;PS2State <= 34; end
			
			34: begin      show <= 1; PS2State <=  35;   TX_Request <= 0;       end
			35:  begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 37;show<=0;
						end
			end
//************************************************************************************************			
			36:  if(~CodeValid) PS2State <= 36;
				 else begin
					case(ScanValue)
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9" : 
						begin
							PS2State <= 38;              // valid digit. write it
						end
						"=" : 
						begin
							PS2State <= 43; ADD2= {4'b0000,Num4,Num5};       // valid digit. write it
						end
						"E":begin PS2State<=97;end
						default:begin soundreq <= 1;PS2State <=36; end
					endcase
				end
			37: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=36;counter <=0;
							end
				end
			
			38: begin    Lcd_data <= ScanValue; TX_Data <= ScanValue; TX_Request <= 1; Num6 <= ScanValue-48;   PS2State <= 39; end
			
			39: begin      TX_Request <= 0; show <= 1; PS2State <=  40;  ADD2= {Num4,Num5,Num6};        end
			40:  begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 42;show<=0;
						end
			end
//*********************************"==******************************************************			
			41:  if(~CodeValid) PS2State <= 41;
				 else begin
					case(ScanValue)
						"=" : 
						begin
							PS2State <= 43;              // valid digit. write it
						end
						"E":begin PS2State<=97;end
						default:begin soundreq <= 1; PS2State <= 41; end
					endcase
				end
			42: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=41;counter <=0;
							end
				end
			
			43: begin    Lcd_data <= 10 ;show <= 1; mark1 <=1; mark2 <=0;PS2State <=44 ; TX_Data <= ScanValue; TX_Request <= 1;  end
			
			44: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 45;show<=0; TX_Request <= 0;   
						end
			end

			
			45:begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=46;counter <=0;
							end
				end//already next  line
			46: begin
					mark2 <= 0;mark1 <=0;
		case(operator)
//.......................................................................................					
				"+":  
						begin 
							ADD5[9:0]= ADD1[11:8]*100+ADD1[7:4]*10+ADD1[3:0];
							ADD6[9:0]= ADD2[11:8]*100+ADD2[7:4]*10+ADD2[3:0];  
							out4=ADD6+ADD5;   // is the 11 bit number :0-10    
							
							shift[10:0] = out4;
							shift[26:11] = 0 ;  //11-26 :16

					for (i=0; i<=10; i=i+1) 
						begin
							if (shift[14:11] >= 5)
							shift[14:11] = shift[14:11] + 3;
 
							if (shift[18:15] >= 5)
							shift[18:15] = shift[18:15] + 3;
 
							if (shift[22:19] >= 5)
							shift[22:19] = shift[22:19] + 3;
			
							if (shift[26:23] >= 5)
							shift[26:23] = shift[26:23] + 3;	
 
							
							shift = shift << 1;		// Shift entire register left once
						end
							
							thousands = shift[26:23];	 // Push decimal numbers to output
							hundreds = shift[22:19];
							tens     = shift[18:15];
							ones     = shift[14:11];
			
							case(thousands)	
							4'b0000: 	thousands1="0" ;
							4'b0001:	thousands1="1" ; 
							endcase 
			
							case(hundreds)	
							4'b0000: 	hundreds1="0" ;
							4'b0001:	hundreds1="1" ; 
							4'b0010:	hundreds1="2" ;
							4'b0011:	hundreds1="3" ;					
							4'b0100:	hundreds1="4" ;
							4'b0101:	hundreds1="5" ;
							4'b0110:	hundreds1="6" ;
							4'b0111:	hundreds1="7" ;
							4'b1000:	hundreds1="8" ;
							4'b1001:	hundreds1="9" ;
						endcase 
			
							case(tens)	
							4'b0000:	tens1="0" ;
							4'b0001:	tens1="1" ; 
							4'b0010:	tens1="2" ;
							4'b0011:	tens1="3" ;					
							4'b0100:	tens1="4" ;
							4'b0101:	tens1="5" ;
							4'b0110:	tens1="6" ;
							4'b0111:	tens1="7" ;
							4'b1000:	tens1="8" ;
							4'b1001:	tens1="9" ;
							endcase 
			
						case(ones)	
							4'b0000:	ones1="0" ;
							4'b0001:	ones1="1" ; 
							4'b0010:	ones1="2" ;
							4'b0011:	ones1="3" ;					
							4'b0100:	ones1="4" ;
							4'b0101:	ones1="5" ;
							4'b0110:	ones1="6" ;
							4'b0111:	ones1="7" ;
							4'b1000:	ones1="8" ;
							4'b1001:	ones1="9" ;
						endcase 
	
					PS2State <=47;		
		end

//======================================="*"运算==========================================
				"*":
				begin

						ADD3[9:0]= ADD1[11:8]*100+ADD1[7:4]*10+ADD1[3:0];
						ADD4[9:0]= ADD2[11:8]*100+ADD2[7:4]*10+ADD2[3:0];  
						otput1 = ADD3*ADD4; 
							//The highest is 998001，total is 4*6=24 20digit
						
							shift1[19:0] = otput1;
							shift1[43:20] = 0 ;  //

					for (i=0; i<=19; i=i+1) 
						begin
							if (shift1[23:20] >= 5)
							shift1[23:20] = shift1[23:20] + 3;
 
							if (shift1[27:24] >= 5)
							shift1[27:24] = shift1[27:24] + 3;
 
							if (shift1[31:28] >= 5)
							shift1[31:28] = shift1[31:28] + 3;
			
							if (shift1[35:32] >= 5)
							shift1[35:32] = shift1[35:32] + 3;	

 							if (shift1[39:36] >= 5)
							shift1[39:36] = shift1[39:36] + 3;

							if (shift1[43:40] >= 5)
							shift1[43:40] = shift1[43:40] + 3;
							
							shift1 = shift1 << 1;		// Shift entire register left once
						end
							mill    	= shift1[43:40];
							tethou	= shift1[39:36];
							thousands = shift1[35:32];	 // Push decimal numbers to output
							hundreds = shift1[31:28];
							tens     = shift1[27:24];
							ones     = shift1[23:20];

							case(mill)	
							4'b0000: h1="0" ;
							4'b0001:	h1="1" ; 
							4'b0010:	h1="2" ;
							4'b0011:	h1="3" ;					
							4'b0100:	h1="4" ;
							4'b0101:	h1="5" ;
							4'b0110:	h1="6" ;
							4'b0111:	h1="7" ;
							4'b1000:	h1="8" ;
							4'b1001:	h1="9" ;							
							endcase 			

							case(tethou)	
							4'b0000: l1="0" ;
							4'b0001:	l1="1" ; 
							4'b0010:	l1="2" ;
							4'b0011:	l1="3" ;					
							4'b0100:	l1="4" ;
							4'b0101:	l1="5" ;
							4'b0110:	l1="6" ;
							4'b0111:	l1="7" ;
							4'b1000:	l1="8" ;
							4'b1001:	l1="9" ;							
							endcase 


							case(thousands)	
							4'b0000: thousands1="0" ;
							4'b0001:	thousands1="1" ; 
							4'b0010:	thousands1="2" ;
							4'b0011:	thousands1="3" ;					
							4'b0100:	thousands1="4" ;
							4'b0101:	thousands1="5" ;
							4'b0110:	thousands1="6" ;
							4'b0111:	thousands1="7" ;
							4'b1000:	thousands1="8" ;
							4'b1001:	thousands1="9" ;							
							endcase 
			
							case(hundreds)	
							4'b0000: hundreds1="0" ;
							4'b0001:	hundreds1="1" ; 
							4'b0010:	hundreds1="2" ;
							4'b0011:	hundreds1="3" ;					
							4'b0100:	hundreds1="4" ;
							4'b0101:	hundreds1="5" ;
							4'b0110:	hundreds1="6" ;
							4'b0111:	hundreds1="7" ;
							4'b1000:	hundreds1="8" ;
							4'b1001:	hundreds1="9" ;
						endcase 
			
							case(tens)	
							4'b0000: tens1="0" ;
							4'b0001:	tens1="1" ; 
							4'b0010:	tens1="2" ;
							4'b0011:	tens1="3" ;					
							4'b0100:	tens1="4" ;
							4'b0101:	tens1="5" ;
							4'b0110:	tens1="6" ;
							4'b0111:	tens1="7" ;
							4'b1000:	tens1="8" ;
							4'b1001:	tens1="9" ;
							endcase 
			
						case(ones)	
							4'b0000: ones1="0" ;
							4'b0001:	ones1="1" ; 
							4'b0010:	ones1="2" ;
							4'b0011:	ones1="3" ;					
							4'b0100:	ones1="4" ;
							4'b0101:	ones1="5" ;
							4'b0110:	ones1="6" ;
							4'b0111:	ones1="7" ;
							4'b1000:	ones1="8" ;
							4'b1001:	ones1="9" ;
						endcase 
	
					PS2State <=47;		
		end	
//======================================="<"运算==========================================
					"<":  
						begin
							if(ADD1[11:8] > ADD2[11:8])   // 输出false 44
								PS2State <= 81;
							else if (ADD1[11:8] < ADD2[11:8])  //输出true
								PS2State <= 69;
							else        
								   begin
								   if(ADD1[7:4] > ADD2[7:4])
							 			PS2State <= 81;
							 	   else if (ADD1[7:4] < ADD2[7:4])
							 	     	PS2State <= 69;
							 	   else
							 	        begin
							 	        if (ADD1[3:0] < ADD2[3:0])
							 	     		PS2State <= 69; 
							 	   		else 
							 	   			PS2State <= 81;
							 	   		end
								   end
						end
//======================================="<"运算==========================================
						">":  
						begin
							if(ADD1[11:8] < ADD2[11:8])   // 输出false
								PS2State <= 81;
							else if (ADD1[11:8] > ADD2[11:8])  //输出true
								PS2State <= 69;
							else      
								   begin  
								   if(ADD1[7:4] < ADD2[7:4])
							 			PS2State <= 81;
							 	   else if (ADD1[7:4] > ADD2[7:4])
							 	     	PS2State <= 69;
							 	   else
							 	   		begin
							 	        if (ADD1[3:0] > ADD2[3:0])
							 	     	PS2State <= 69; 
							 	   else 
							 	   		PS2State <= 81;
								   end
							end
						end
					default: PS2State <= 0;					
					endcase
				end
			47: begin    Lcd_data <= 61 ;   show <= 1; mark1 <=0; mark2 <=0;PS2State <=  48 ;     end
			
			48: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 49;show<=0;
						end
			end//.......................................................................................
					
			49:	begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=50;counter <=0;
							end
				end
			50: begin
					case(operator)
					"*":PS2State <= 51;
					"+":PS2State <= 57;
					default: PS2State <= 0;
					endcase
				end
//===========================    +++++++++++   ====================================				
			51: begin	if(h1 == "0") PS2State<= 54;
							else begin 
						TX_Data <= h1; Lcd_data <=h1;   show <= 1; PS2State <=  52 ;    TX_Request <= 1;   end end
						
			
			52: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 53;show<=0; TX_Request <= 0;    
						end
			end		
			53: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=54;counter <=0;
							end
				end


			54: begin  if((h1 == "0") && (l1 == "0"))   PS2State <=  57 ;
							else begin TX_Data <= l1;Lcd_data <= l1;show <= 1; PS2State <=  55 ;   TX_Request <= 1;end      end	
			55: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 56;show<=0; TX_Request <= 0;
						end
			end			
			56: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=57;counter <=0;
							end
				end


			57: begin  	if((h1 == "0") && (l1 == "0") && (thousands1 == "0")) PS2State<=60;
							else begin 
			TX_Data <= thousands1;Lcd_data <= thousands1; show <= 1; PS2State <= LCDfinish ? 57 : 58 ;  TX_Request <= 1; end     end
			58: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 59;show<=0; TX_Request <= 0;
						end
			end			
			59: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=60;counter <=0;
							end
				end


			60: begin   if((h1 == "0") && (l1 == "0") && (thousands1 == "0") &&(hundreds1 == "0")) PS2State <= 63;
							else begin TX_Data <= hundreds1; Lcd_data <= hundreds1; show <= 1; PS2State <=  61 ;   TX_Request <= 1;     end end 				
			61: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 62;show<=0; TX_Request <= 0;
						end
			end			
			62: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=63;counter <=0;
							end
				end


			63: begin 
			if((h1 == "0") && (l1 == "0") && (thousands1 == "0") && (hundreds1 == "0") && (tens1 == "0")) PS2State <= 66;
							else begin TX_Data <= tens1; Lcd_data <= tens1; show <= 1; PS2State <=  64 ;   TX_Request <= 1;    end end			
			64: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 65;show<=0; TX_Request <= 0;
						end
			end			
			65: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=66;counter <=0;
							end
				end


			66: begin TX_Data <= ones1;Lcd_data <= ones1; show <= 1; PS2State <=  67 ;     end
			67: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 68;show<=0;
						end
			end			
			68: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=96;counter <=0;
							end
				end

//===========================output"TRUE"====================================================================			
			69: begin  TX_Data <= "T";Lcd_data <= "T"; show <= 1; PS2State <=  70 ;     TX_Request <= 1;   end
			70: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 71;show<=0; TX_Request <= 0;
						end
			end			
			71: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=72;counter <=0;
							end
				end
			72: begin TX_Data <= "R"; Lcd_data <= "R"; show <= 1; PS2State <=  73;  TX_Request <= 1;       end
			73: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 74;show<=0; TX_Request <= 0;
						end
			end			
			74: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=75;counter <=0;
							end
				end
			75: begin TX_Data <= "U";Lcd_data <= "U" ; show <= 1; PS2State <=  76 ;   TX_Request <= 1;      end		
			76: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 77;show<=0; TX_Request <= 0;
						end
			end			
			77: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=78;counter <=0;
							end
				end
			78: begin TX_Data <= "E";Lcd_data <= "E"; show <= 1; PS2State <=  79 ;      TX_Request <= 1;   end	
			79: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 80;show<=0; TX_Request <= 0;
						end
			end			
			80: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=96;counter <=0;
							end
				end
				
//========================output"FALSE"==================================================================			
			81: begin TX_Data <= "F";Lcd_data <= "F"; show <= 1; PS2State <=  82 ;     TX_Request <= 1;    end	
			82: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 83;show<=0; TX_Request <= 0;
						end
			end		
			83: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=84;counter <=0;
							end
				end		
			84: begin TX_Data <= "A"; Lcd_data <= "A"; show <= 1; PS2State <=  85 ;     TX_Request <= 1;    end
			85: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 86;show<=0; TX_Request <= 0;
						end
			end			
			86: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=87;counter <=0;
							end
				end
			87: begin TX_Data <= "L";Lcd_data <= "L"; show <= 1; PS2State <=  88 ;     TX_Request <= 1;    end	
			88: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 89;show<=0; TX_Request <= 0;
						end
			end			
			89: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=90;counter <=0;
							end
				end
			90: begin TX_Data <= "S";Lcd_data <= "S"; show <= 1; PS2State <=  91 ;     TX_Request <= 1;    end
			91: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 92;show<=0; TX_Request <= 0;
						end
			end			
			92: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=93;counter <=0;
							end
				end
			93: begin Lcd_data <= "E"; show <= 1; PS2State <=  94 ;     TX_Request <= 1;    end
			94: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 95;show<=0; TX_Request <= 0;
						end
			end			
			95: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=96;counter <=0;
							end
				end


//**************************************************************************************************			
			96: begin if(~CodeValid) PS2State <= 96;
				 else begin
					case(ScanValue)
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9" :  
						begin
							PS2State <= 101;              // valid digit. write it
						end
						"E":begin PS2State <= 97;end
						default:begin soundreq <= 1; PS2State <= 96; end
					endcase
				end
				end
//*****************************************************************************************************
			97: begin	PS2State <= LCDfinish ? 98 : 97;  end
			98: begin   Lcd_data <= 10; show <= 1; mark1<=0;mark2<=1;PS2State <=  99 ; TX_Request <= 1;       end
			99: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 100;show<=0; TX_Request <= 0;
						end
			end		
			100: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=106;counter <=0;
							end
				end	

			101: begin	PS2State <= LCDfinish ? 102 : 101;  end
			102: begin  Lcd_data <= 10; show <= 1; mark1<=0;mark2<=1;PS2State <=  103 ; TX_Request <= 1;      end
			103: begin     counter <= counter + 1;
						if (counter > 5) begin 
						counter <= 0; PS2State <= 104;show<=0;  TX_Request <= 0;
						end
			end			
			104: begin counter <= counter+1;
							if(counter>N)
							begin PS2State <=105;counter <=0;
							end
				end
			105: begin   mark2 <=0;PS2State <=  9;  TX_Request <= 1;  end
			
			106: begin PS2State <=  0;    end
		default:	PS2State <= 0;
		endcase

	end	

endmodule
