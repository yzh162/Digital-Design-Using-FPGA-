
module LCD(CLK, LCD_FPGA_DB,LCD_FPGA_E,LCD_FPGA_RS,LCD_FPGA_RW,RESET, new_input, score, level, supermode);

    input            		CLK;
    input                 	RESET;
	input					new_input;
	input		[9:0]		score;
	input		[1:0]		level;
	input		[1:0]		supermode;
    
	output     	[3:0]      	LCD_FPGA_DB;
    output reg            	LCD_FPGA_RW;
    output 		          	LCD_FPGA_E, LCD_FPGA_RS;
			 
    reg 	 	[7:0]      	CS;   
    reg       	[7:0]      	Data;
    reg                   	Strb, RS;
	reg						show_0;
	reg 			[2:0]			counter;


	wire					Busy;
	
	wire 		[3:0]		dig4, dig3, dig2, dig1;
	

    LCD_write L1( .Clk(CLK), .Strb(Strb), .Reset(RESET), .D_in(Data), .D_out(LCD_FPGA_DB), 
	              .E(LCD_FPGA_E), .Busy(Busy), .RS_out(LCD_FPGA_RS), .RS(RS));

	B2BCD bcd(score, dig4, dig3, dig2, dig1);
				  
				  
    always @(posedge CLK) begin: LCDCycle
	    if(RESET) begin	
			CS <= 0;
			disable LCDCycle;
		end


	    LCD_FPGA_RW <= 0;           // Always write.
	    Data <= 0;
	    Strb <= 0;
	    
        case(CS)
	        0: 	begin	
						if(new_input) begin
							show_0 <= 0;
							CS <= 1;
							RS <= 0;
						end
				end
	        1:  begin
				    Data <= 8'b0010_1000; // Configure LCD in 2 line mode
				    Strb <= 1;
				    CS <= 2;
			    end
	        2:	begin
					if(Busy) CS <= 2;
				    else CS <= 3;
			    end
	        3:  begin
				    Data <= 8'b0000_1111;   // 8'h0F is Cursor ON, display ON, blink ON 
				    Strb <= 1;
				    CS <= 4;
			    end
	        4:  begin
				    if(Busy) CS <= 4;
				    else CS <= 5;
			    end
	        5:  begin
         			Data <= 8'b0000_0001;   // Clear display. Cursor home
			        Strb <= 1;
				    CS <= 6;
			    end
            6:  begin
				    if(Busy) CS <= 6;
					else CS <= 7;
			    end
	        7:  begin
				    Data <= 8'b0000_0110;   // No shift, increment
				    Strb <= 1;
				    CS <= 8;
			    end
	        8:	begin
					if(Busy) CS <= 8;
					else begin
						CS <= 9;
						RS <= 1;
					end
					end
			
			// "S"
			9:	begin
					Strb <= 1;
					Data <= "S";
					CS <= 10;
				end
			10: begin
				    if(Busy) CS <= 10;
					else CS <= 11;
					counter <= 1;
			    end
			11: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 12;
				end
			12: begin
					Strb <= 1;
					Data <= "S";
					CS <= 13;
				end
			13: begin
				    if(Busy) CS <= 13;
					else CS <= 149;
					counter <= 1;
			    end
			149: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 14;
					
				end
			// "c"
			14:	begin
					Strb <= 1;
					Data <= "c";
					CS <= 15;
					end
			15: begin
				    if(Busy) CS <= 15;
					else CS <= 16;
					counter <= 1;
			    end
			16: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 18;
				end
				 
			// "o"
			18:	begin
					Strb <= 1;
					Data <= "o";
					CS <= 19;
					end
			19: begin
				    if(Busy) CS <= 19;
					else CS <= 20;
					counter <= 1;
			    end
			20: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 22;
				end

			// "r"	
			22:	begin
					Strb <= 1;
					Data <= "r";
					CS <= 23;
					end
			23: begin
				    if(Busy) CS <= 23;
					else CS <= 24;
					counter <= 1;
			    end
			24: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 26;
				end

			// "e"
			26:	begin
					Strb <= 1;
					Data <= "e";
					CS <= 27;
					end
			27: begin
				    if(Busy) CS <= 27;
					else CS <= 28;
					counter <= 1;
			    end
			28: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 30;
				end

			// "="
			30:	begin
					Strb <= 1;
					Data <= "=";
					CS <= 31;
					end
			31: begin
				    if(Busy) CS <= 31;
					else CS <= 32;
			    end
			32: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 34;
				end
			
			// score dig4
			34:	begin
					if(dig4 == 0) CS <= 38;
					else begin
						show_0 <= 1;
						Strb <= 1;
						case(dig4)
							0:	begin Data <= "0"; 	end
							1:	begin Data <= "1";	end
							2:	begin Data <= "2";	end
							3:	begin Data <= "3";	end
							4:	begin Data <= "4";	end
							5:	begin Data <= "5";	end
							6:	begin Data <= "6";	end
							7:	begin Data <= "7";	end
							8:	begin Data <= "8";	end
							9:	begin Data <= "9";	end
						endcase
						CS <= 35;
					end
				end
			35:	begin
				    if(Busy) CS <= 35;
					else CS <= 36;
					counter <= 1;
			    end
			36: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 38;
				end
			
			// score dig3
			38:	begin
					if((dig3 == 0) && (show_0 == 0)) CS <= 42;
					else begin
						show_0 <= 1;
						Strb <= 1;
						case(dig3)
							0:	begin Data <= "0"; 	end
							1:	begin Data <= "1";	end
							2:	begin Data <= "2";	end
							3:	begin Data <= "3";	end
							4:	begin Data <= "4";	end
							5:	begin Data <= "5";	end
							6:	begin Data <= "6";	end
							7:	begin Data <= "7";	end
							8:	begin Data <= "8";	end
							9:	begin Data <= "9";	end
						endcase
						CS <= 39;
					end
				end
			39:	begin
				    if(Busy) CS <= 39;
					else CS <= 40;
					counter <= 1;
			    end
			40: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 42;
				end
				
			// score dig2
			42:	begin
					if((dig2 == 0) && (show_0 == 0)) CS <= 46;
					else begin
						show_0 <= 1;
						Strb <= 1;
						case(dig2)
							0:	begin Data <= "0"; 	end
							1:	begin Data <= "1";	end
							2:	begin Data <= "2";	end
							3:	begin Data <= "3";	end
							4:	begin Data <= "4";	end
							5:	begin Data <= "5";	end
							6:	begin Data <= "6";	end
							7:	begin Data <= "7";	end
							8:	begin Data <= "8";	end
							9:	begin Data <= "9";	end
						endcase
						CS <= 43;
					end
				end
			43:	begin
				    if(Busy) CS <= 43;
					else CS <= 44;
					counter <= 1;
			    end
			44: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 46;
				end
			
			// score dig1
			46:	begin
					Strb <= 1;
					case(dig1)
						0:	begin Data <= "0"; 	end
						1:	begin Data <= "1";	end
						2:	begin Data <= "2";	end
						3:	begin Data <= "3";	end
						4:	begin Data <= "4";	end
						5:	begin Data <= "5";	end
						6:	begin Data <= "6";	end
						7:	begin Data <= "7";	end
						8:	begin Data <= "8";	end
						9:	begin Data <= "9";	end
					endcase
					CS <= 47;
				end
			47:	begin
				    if(Busy) CS <= 47;
					else CS <= 48;
					counter <= 1;
			    end
			48: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 50;
				end
			
				
			// New line
			50:	begin
					RS <= 0;
					CS <= 51;
				end
			51: begin
					Data <= 8'hC0;         // Issue command to go to next line (8'hC0) 
				    Strb <= 1;
					CS <= 52;
				end
			52:	begin
					if(Busy) CS <= 52;
					else begin
						CS <= 148;
						RS <= 1;
					end
				end
			
			148:begin
					if(level == 3) CS <= 86;
					else CS <= 53;
				end
			
			// "L"
			53:	begin
					Strb <= 1;
					Data <= "L";
					CS <= 54;
					end
			54: begin
				    if(Busy) CS <= 54;
					else CS <= 55;
					counter <= 1;
			    end
			55: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 57;
				end
			
			// "e"
			57:	begin
					Strb <= 1;
					Data <= "e";
					CS <= 58;
					end
			58: begin
				    if(Busy) CS <= 58;
					else CS <= 59;
					counter <= 1;
			    end
			59: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 61;
				end
			
			// "v"
			61:	begin
					Strb <= 1;
					Data <= "v";
					CS <= 62;
					end
			62: begin
				    if(Busy) CS <= 62;
					else CS <= 63;
					counter <= 1;
			    end
			63: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 65;
				end
		
			// "e"
			65:	begin
					Strb <= 1;
					Data <= "e";
					CS <= 66;
					end
			66: begin
				    if(Busy) CS <= 66;
					else CS <= 67;
					counter <= 1;
			    end
			67: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 69;
				end
			
			// "l"
			69:	begin
					Strb <= 1;
					Data <= "l";
					CS <= 70;
					end
			70: begin
				    if(Busy) CS <= 70;
					else CS <= 71;
					counter <= 1;
			    end
			71: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 150;
				end

			//" "
			150:	begin
					Strb <= 1;
					Data <= " ";
					CS <= 151;
					end
			151: begin
				    if(Busy) CS <= 151;
					else CS <= 152;
					counter <= 1;
			    end
			152: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 73;
				end

			// level number
			73:	begin
					case(level)
						0:	begin CS <= 74; end
						1:	begin CS <= 78;	end
						2:	begin CS <= 82;	end
						3:	begin CS <= 86;	end
					endcase
				end
			// level 1
			74:	begin
					Strb <= 1;
					Data <= "1";
					CS <= 75;
					end
			75: begin
				    if(Busy) CS <= 75;
					else CS <= 76;
					counter <= 1;
			    end
			76: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 122;
				end
			
			// level 2
			78:	begin
					Strb <= 1;
					Data <= "2";
					CS <= 79;
					end
			79: begin
				    if(Busy) CS <= 79;
					else CS <= 80;
					counter <= 1;
			    end
			80: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 122;
				end
			
			// level 3
			82:	begin
					Strb <= 1;
					Data <= "3";
					CS <= 83;
					end
			83: begin
				    if(Busy) CS <= 83;
					else CS <= 84;
					counter <= 1;
			    end
			84: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 122;
				end
			
			
			// game over
			// "G"
			86:	begin
					Strb <= 1;
					Data <= "G";
					CS <= 87;
					end
			87: begin
				    if(Busy) CS <= 87;
					else CS <= 88;
					counter <= 1;
			    end
			88: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 90;
				end
			
			// "a"
			90:	begin
					Strb <= 1;
					Data <= "a";
					CS <= 91;
					end
			91: begin
				    if(Busy) CS <= 91;
					else CS <= 92;
					counter <= 1;
			    end
			92: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 94;
				end
			
			// "m"
			94:	begin
					Strb <= 1;
					Data <= "m";
					CS <= 95;
					end
			95: begin
				    if(Busy) CS <= 95;
					else CS <= 96;
					counter <= 1;
			    end
			96: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 98;
				end
			
			// "e"
			98:	begin
					Strb <= 1;
					Data <= "e";
					CS <= 99;
					end
			99: begin
				    if(Busy) CS <= 99;
					else CS <= 100;
					counter <= 1;
			    end
			100:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 102;
				end
				
			// " "
			102:begin
					Strb <= 1;
					Data <= " ";
					CS <= 103;
					end
			103:begin
				    if(Busy) CS <= 103;
					else CS <= 104;
					counter <=  1;
			    end
			104: begin
					counter <= counter + 1;
					if(counter == 0) CS <= 106;
				end
			
			// "O"
			106:begin
					Strb <= 1;
					Data <= "O";
					CS <= 107;
					end
			107:begin
				    if(Busy) CS <= 107;
					else CS <= 108;
					counter <= 1;
			    end
			108:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 110;
				end
			
			// "v"
			110:begin
					Strb <= 1;
					Data <= "v";
					CS <= 111;
					end
			111:begin
				    if(Busy) CS <= 111;
					else CS <= 112;
					counter <= 1;
			    end
			112:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 114;
				end
			
			// "e"
			114:begin
					Strb <= 1;
					Data <= "e";
					CS <= 115;
					end
			115:begin
				    if(Busy) CS <= 115;
					else CS <= 116;
					counter <= 1;
			    end
			116:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 118;
				end
			
			// "r"
			118:begin
					Strb <= 1;
					Data <= "r";
					CS <= 119;
					end
			119:begin
				    if(Busy) CS <= 119;
					else CS <= 120;
					counter <= 1;
			    end
			120:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 147;
				end
			
			
			// Judge if display "SUPER"
			122:begin
					if(supermode == 3) CS <= 123;
					else CS <= 147;
				end
			
			// Display "SUPER"
			// " "
			123:begin
					Strb <= 1;
					Data <= " ";
					CS <= 124;
					end
			124:begin
				    if(Busy) CS <= 124;
					else CS <= 125;
					counter <= 1;
			    end
			125:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 127;
				end
			
			// "S"
			127:begin
					Strb <= 1;
					Data <= "S";
					CS <= 128;
					end
			128:begin
				    if(Busy) CS <= 128;
					else CS <= 129;
					counter <= 1;
			    end
			129:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 131;
				end
			
			// "U"
			131:begin
					Strb <= 1;
					Data <= "U";
					CS <= 132;
					end
			132:begin
				    if(Busy) CS <= 132;
					else CS <= 133;
					counter <= 1;
			    end
			133:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 135;
				end
			
			// "P"
			135:begin
					Strb <= 1;
					Data <= "P";
					CS <= 136;
					end
			136:begin
				    if(Busy) CS <= 136;
					else CS <= 137;
					counter <= 0;
			    end
			137:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 139;
				end
			
			// "E"
			139:begin
					Strb <= 1;
					Data <= "E";
					CS <= 140;
					end
			140:begin
				    if(Busy) CS <= 140;
					else CS <= 141;
					counter <= 1;
			    end
			141:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 143;
				end
			
			// "R"
			143:begin
					Strb <= 1;
					Data <= "R";
					CS <= 144;
				end
			144:begin
				    if(Busy) CS <= 144;
					else CS <= 145;
					counter <= 1;
			    end
			145:begin
					counter <= counter + 1;
					if(counter == 0) CS <= 147;
				end
			
			
			147:begin
//					if(delay == 0) CS <= 0;			// if the content on LCD changes fast enough, then we don't have to lock here
//					else CS <= 147;
					CS <= 0;
				end
        endcase
    end
 
endmodule