`timescale 1ns / 1ps

module main(DVI, DVI_DE, DVI_H, DVI_V, DVI_XCLK_N, DVI_XCLK_P, USER_CLK,DVI_RESET_B, 
           MOUSE_CLK, MOUSE_DATA,PIEZO_SPEAKER, IIC_SCL_VIDEO, IIC_SDA_VIDEO, GPIO_SW_C,
		   LCD_FPGA_DB, LCD_FPGA_E, LCD_FPGA_RS, LCD_FPGA_RW,);
	
	input				USER_CLK;    // Main 100MHz clock
	input				GPIO_SW_C;
    
	
    output reg	[11:0]	DVI;
	output reg          DVI_DE, DVI_H, DVI_V, DVI_XCLK_N, DVI_XCLK_P;
	output				DVI_RESET_B;
	
	output reg	        PIEZO_SPEAKER;
	
	output 		        LCD_FPGA_E, LCD_FPGA_RS;
	output     	[3:0]   LCD_FPGA_DB;
    output            	LCD_FPGA_RW;
	 
	 
	inout	            MOUSE_CLK, MOUSE_DATA;
	 
	inout				IIC_SCL_VIDEO;
	inout				IIC_SDA_VIDEO;

	 

    parameter		TOTAL_H_PIXELS = 800;
    parameter   	TOTAL_V_ROWS = 521;

    parameter 		H_FRONT_PORCH_START = 0;
    parameter   	H_FRONT_PORCH_END = 15;
    parameter      	HSYNC_START = 16;
    parameter      	HSYNC_END = 111;
    parameter      	H_BACK_PORCH_START = 112;
    parameter      	H_BACK_PORCH_END = 159;
    parameter      	H_IMAGE_START = 160;
    parameter      	H_IMAGE_END = 799;

    parameter      	V_FRONT_PORCH_START = 0;
    parameter      	V_FRONT_PORCH_END = 9;
    parameter      	VSYNC_START = 10;
    parameter      	VSYNC_END = 11;
    parameter      	V_BACK_PORCH_START = 12;
    parameter      	V_BACK_PORCH_END = 40;
    parameter      	V_IMAGE_START = 41;
    parameter      	V_IMAGE_END = 520;

	
	
	reg		[3:0]	random;
	reg		[1:0]	addx = 1;
	reg		[1:0]	addy = 1;
	

	reg		[9:0]	racketHPos = 400;
	reg		[9:0]	racketVPos;
	reg				CLK_2, Rd_Strb;
	wire			M_ready;
	wire	[8:0]   MouseY;
	
	reg		[9:0]	score;
	reg				show_ball;
	reg		[1:0]	level = 0;
	reg		[20:0]	ball_speed;
	reg		[2:0]	ball_move_mode = 0;
	reg 	[9:0]   ballHPos;        // Horizontal ball position
	reg 	[9:0]   ballVPos;        // Vertical ball position
	reg		[1:0]	sound_mode = 0;
	reg				new_sound = 0;
	reg		[1:0]	super_count = 0;
	reg		[30:0]	level_counter = 0;
	reg				reset = 0;
	reg		[1:0]	reset_state;
	
    reg 	[9:0]	HCtr;        // Counter for horizontal pixels , including the blank, 0-799
    reg 	[9:0]   VCtr;        // Counter for vertical rows , including the blank, 0-520
	reg 	[9:0]   HPos;        // Horizontal pixel position
	reg 	[9:0]   VPos;        // Vertical pixel position
	reg		[1:0]   ClkDiv;      // To perform VGA/DVI functions in multiple clocks


	reg		[7:0]   DVIR, DVIG, DVIB;
	reg 	[11:0]  DVIMultiplex;
	
	reg		[20:0]	piezo_ctrl;
	reg		[3:0]	piezo_state;
	reg		[25:0]	piezo_duration;
	
	reg				lcd_input = 0;

	
	assign racketON = ((HPos - racketHPos >= 0) && (HPos - racketHPos <= 7)) && ((VPos - racketVPos >= 0) && (VPos - racketVPos <= 31));
	assign ballON = ((HPos - ballHPos >= 0) && (HPos - ballHPos <= 7)) && ((VPos - ballVPos >= 0) && (VPos - ballVPos <= 7));
	assign dead_area = ((HPos > 407) && (HPos < H_IMAGE_END)) || ((VPos > 399) && (VPos < V_IMAGE_END));
	

	iic_init SERCOM (.Clk     (USER_CLK),			
                     .Reset_n (GPIO_SW_C),
                     .Pixel_clk_greater_than_65Mhz (1'b0),
                     .SDA     (IIC_SDA_VIDEO),
                     .SCL     (IIC_SCL_VIDEO),
                     .Done    ());
							
	// PS2 mouse module     Reset - active high
	ps2_mouse_interface Mouse(	.clk(CLK_2), .reset(GPIO_SW_C), .ps2_clk(MOUSE_CLK),  .ps2_data(MOUSE_DATA),
								.left_button(), .right_button(), .x_increment(), .y_increment(MouseY),
								.data_ready(M_ready), .read(Rd_Strb), .error_no_ack());

	assign DVI_RESET_B = 1'b1;
	
	LCD lcd_display(USER_CLK, LCD_FPGA_DB, LCD_FPGA_E, LCD_FPGA_RS, LCD_FPGA_RW, GPIO_SW_C,
					lcd_input, score, level, super_count);
	
	
	
	// Generate random number
	always @(posedge USER_CLK) begin
		random <= random + 1;
		if(random >= 13) random <= 0;
	end
	
	
	// Racket and mouse
    always @(posedge USER_CLK) begin
	    if(GPIO_SW_C) begin 
			CLK_2 <= 0;
			Rd_Strb <= 0;
			racketVPos <= 200;
		end
		else begin
			CLK_2 <= ~CLK_2;
			
			if(M_ready) begin
				if(MouseY[8]) racketVPos <= racketVPos + 2; else racketVPos <= racketVPos - 2;
				if (racketVPos > 368) racketVPos <= 368;
				if (racketVPos <= 1) racketVPos <= 2;
			    Rd_Strb <= 1;
			end 
			else begin
				Rd_Strb <= 0;
			end
		end
	end 
	 
	 
	// Ball movement
	always @(posedge USER_CLK) begin: BallCycle
		if(GPIO_SW_C) begin
			ballHPos <= 201;
			ballVPos <= 0;
			ball_move_mode <= 0;
			level <= 0;
			ball_speed <= 1;
			score <= 0;
			sound_mode <= 0;
			super_count <= 0;
			show_ball <= 1;
			level_counter <= 0;
			lcd_input <= 0;
			reset <= 1;
			reset_state <= 0;
			disable BallCycle;
		end
		
		if(reset == 1) begin
			case(reset_state)
				0: begin
						lcd_input <= 1;
						reset_state <= 1;
					end
				1: begin
						lcd_input <= 0;
						reset <= 0;
					end
			endcase
		end
			
		
		ball_speed <= ball_speed + 1;
		level_counter <= level_counter + 1;
		
		case(level)
			0:	begin
					if(ball_speed >= 1200000)
						ball_speed <= 0;
					if(level_counter >= 2100000000) begin
						level_counter <= 0;
						level <= 1;
						lcd_input <= 1;
					end
				end
			1:	begin
					lcd_input <= 0;
					if(ball_speed >= 900000)
						ball_speed <= 0;
					if(level_counter >= 2100000000) begin
						level_counter <= 0;
						level <= 2;
						lcd_input <= 1;
					end
				end
			2:	begin
					lcd_input <= 0;
					if(ball_speed >= 600000)
						ball_speed <= 0;
					if(level_counter >= 2100000000) begin
						level_counter <= 0;
						level <= 3;
						lcd_input <= 1;
					end
				end
			3:	begin
					lcd_input <= 0;
					show_ball <= 0;
					disable BallCycle;
				end
		endcase
			
		if(ball_speed == 0) begin
			case(ball_move_mode)
				0:	begin		// Move right down
						ballHPos <= ballHPos + addx;
						ballVPos <= ballVPos + addy;
						if(ballVPos >= 392) ballVPos <= 392;
						if(ballHPos >= 392) ballHPos <= 392;
						
						if(ballHPos == 392) begin	// Hit right edge
							if((ballVPos + 7 > racketVPos) && (ballVPos < racketVPos + 31)) begin	// hit
								if(super_count == 2) sound_mode <= 3;
								else sound_mode <= 1;
								if(super_count != 3) super_count <= super_count + 1;
								case(level)
									0:	begin	score <= score + 1*((super_count == 3) ? 2:1); end
									1:	begin	score <= score + 2*((super_count == 3) ? 2:1); end
									2:	begin	score <= score + 4*((super_count == 3) ? 2:1); end
								endcase
							end
							else begin	// miss
								sound_mode <= 2;
								super_count <= 0;
							end
							
							lcd_input <= 1;
							new_sound <= 1;
							if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
							if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];
							ball_move_mode <= 1;
						end	
						if(ballVPos == 392) begin		// hit bottom edge
							if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
							if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];							
							ball_move_mode <= 2;
						end
					end
					
				1:	begin			// Move left down
						lcd_input <= 0;
						new_sound <= 0;
						ballHPos <= ballHPos - addy;
						ballVPos <= ballVPos + addx;
						if(ballHPos <= 3) ballHPos <= 3;
						if(ballVPos >= 392) ballVPos <= 392;
						
						if(ballVPos == 392) begin		// Hit bottom edge
							if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
							if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];
							ball_move_mode <= 2;
						end
						if(ballHPos == 3) begin			// Hit right edge
							if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
							if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];							
							ball_move_mode <= 3;
						end
					end
					
				2:	begin			// Move left up
						lcd_input <= 0;
						new_sound <= 0;
						ballHPos <= ballHPos - addx;
						ballVPos <= ballVPos - addy;
						if(ballVPos <= 3) ballVPos <= 3;
						if(ballHPos <= 3) ballHPos <= 3;
						
						if(ballHPos == 3) begin			// Hit left edge
							if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
							if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];
							ball_move_mode <= 3;
						end
						if(ballVPos == 3) begin			// Hit bottom edge
							if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
							if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];							
							ball_move_mode <= 0;
						end
					end
					
				3:	begin			// Move right up
						ballHPos <= ballHPos + addy;
						ballVPos <= ballVPos - addx;
						if(ballHPos >= 392) ballHPos <= 392;
						if(ballVPos <= 3) ballVPos <= 3;

						if(ballVPos == 3) begin			// Hit top edge				
								if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
								if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];
								ball_move_mode <= 0;
						end
						if(ballHPos == 392) begin		// Hit right edge
							if((ballVPos + 7 > racketVPos) && (ballVPos < racketVPos + 31)) begin	// hit
								if(super_count == 2) sound_mode <= 3;
								else sound_mode <= 1;
								if(super_count != 3) super_count <= super_count + 1;
								case(level)
									0:	begin	score <= score + 1*((super_count == 3) ? 2:1); end
									1:	begin	score <= score + 2*((super_count == 3) ? 2:1); end
									2:	begin	score <= score + 4*((super_count == 3) ? 2:1); end
								endcase
							end
							else begin	// miss
								sound_mode <= 2;
								super_count <= 0;
							end
							
							lcd_input <= 1;
							new_sound <= 1;
							if(random[2:1] == 0) addx <= 1; else addx <= random[2:1];
							if(random[1:0] == 0) addy <= 1; else addy <= random[1:0];
							ball_move_mode <= 1;
						end
					end
			endcase		
		end
	end
										
					
	// DVI display					 
    always @(posedge USER_CLK) begin: ClkCycle
	    // ClkDiv is a counter to perform certain DVI/VGA functions in multiple clocks
		ClkDiv <= ClkDiv+1;
		case(ClkDiv)
		    2'b00:	begin
						if(ballON == 1) begin
							if(show_ball == 1) begin
								DVIR = 255;
								DVIG = 255;
								DVIB = 255;
							end
							else begin
								DVIR = 0;
								DVIG = 0;
								DVIB = 0;
							end
						end					
						else begin
							if(racketON == 1) begin
								DVIR = 255;
								DVIG = 255;
								DVIB = 255;
							end
							else begin
								if(dead_area == 1) begin
									if(super_count == 3) begin
										DVIR = 0;
										DVIG = 0;
										DVIB = 255;
									end
									else begin
										DVIR = 0;
										DVIG = 0;
										DVIB = 0;
									end
								end
								else begin
									DVIR = 0;
									DVIG = 0;
									DVIB = 0;
								end
							end
						end
						DVI <= {DVIG[3:0],DVIB};
						disable ClkCycle;
			        end
			2'b01:	begin
						DVI_XCLK_N <= 0;
						DVI_XCLK_P <= 1;			         
						disable ClkCycle;			 
					end
			2'b10:	begin
						if(ballON == 1) begin
							if(show_ball == 1) begin
								DVIR = 255;
								DVIG = 255;
								DVIB = 255;
							end
							else begin
								DVIR = 0;
								DVIG = 0;
								DVIB = 0;
							end
						end					
						else begin
							if(racketON == 1) begin
								DVIR = 255;
								DVIG = 255;
								DVIB = 255;
							end
							else begin
								if(dead_area == 1) begin
									if(super_count == 3) begin
										DVIR = 0;
										DVIG = 0;
										DVIB = 255;
									end
									else begin
										DVIR = 0;
										DVIG = 0;
										DVIB = 0;
									end
								end
								else begin
									DVIR = 0;
									DVIG = 0;
									DVIB = 0;
								end
							end
						end
						DVI <= {DVIR,DVIG[7:4]};
					end
			2'b11:  begin
						DVI_XCLK_N <= 1;
						DVI_XCLK_P <= 0;
						disable ClkCycle;
					end
		endcase
		 
		 
	    // Update horizontal and vertical counters.
		if(HCtr < H_IMAGE_END) begin
		    HCtr <= HCtr + 1; 
			if(HCtr >= H_IMAGE_START) HPos <= HPos + 1;
		end
		else begin
			HCtr <= H_FRONT_PORCH_START;
			HPos <= 0;
			if(VCtr < V_IMAGE_END) begin
				VCtr <= VCtr + 1; 
				if(VCtr >= V_IMAGE_START) VPos <= VPos + 1;
			end
			else begin
				VCtr <= V_FRONT_PORCH_START;
				VPos <= 0;
			end
		end

		 
		 // No signal during front porch, Sync, and back porch
		if( ((HCtr >= H_FRONT_PORCH_START) && (HCtr <= H_BACK_PORCH_END)) || ((VCtr >= V_FRONT_PORCH_START) && (VCtr <= V_BACK_PORCH_END)) ) begin
			DVI_DE <= 0;
		end
		else begin
		    DVI_DE <= 1;
		end
				
		// Issue correct HSync and VSync signals (both Active Low by default)
		DVI_H <= ~((HCtr >= HSYNC_START) && (HCtr <= HSYNC_END));
		DVI_V <= ~((VCtr >= VSYNC_START) && (VCtr <= VSYNC_END));
	end  // ClkCycle
	 
	
	// PIEZO_SPEAKER
	always @(posedge USER_CLK) begin: PiezoCycle
		if(GPIO_SW_C) begin 
			piezo_ctrl <= 0;
			piezo_duration <= 0;
			piezo_state <= 0;
			disable PiezoCycle;
		end
		
		piezo_ctrl <= piezo_ctrl + 1;
		
		case(piezo_state)
			0:	begin
					if(new_sound == 0) piezo_state <= 0;
					else piezo_state <= 1;
				end
			1:	begin
					if(sound_mode == 1) piezo_state <= 2;	// hit
					if(sound_mode == 2) piezo_state <= 3;	// miss
					if(sound_mode == 3) piezo_state <= 4;	// super mode
					piezo_duration <= 0;
				end
			2:	begin	//hit
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 20000000) PIEZO_SPEAKER <= piezo_ctrl[18];
					else piezo_state <= 12;
				end
			3:	begin	//miss
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 50000000) PIEZO_SPEAKER <= piezo_ctrl[20];
					else piezo_state <= 12;
				end
			4:	begin	//super mode, beep 1
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 20000000) PIEZO_SPEAKER <= piezo_ctrl[18];
					else begin
						piezo_duration <= 0;
						piezo_state <= 5;
					end
				end
			5:	begin
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 10000000) PIEZO_SPEAKER <= 0;
					else begin
						piezo_duration <= 0;
						piezo_state <= 6;
					end
				end
			6:	begin	//super mode, beep 2
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 20000000) PIEZO_SPEAKER <= piezo_ctrl[18];
					else begin
						piezo_duration <= 0;
						piezo_state <= 7;
					end
				end
			7:	begin
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 10000000) PIEZO_SPEAKER <= 0;
					else begin
						piezo_duration <= 0;
						piezo_state <= 8;
					end
				end
			8:	begin	//super mode, beep 3
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 20000000) PIEZO_SPEAKER <= piezo_ctrl[18];
					else begin
						piezo_duration <= 0;
						piezo_state <= 9;
					end
				end
			9:	begin
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 10000000) PIEZO_SPEAKER <= 0;
					else begin
						piezo_duration <= 0;
						piezo_state <= 10;
					end
				end
			10:	begin	//super mode, beep 4
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 20000000) PIEZO_SPEAKER <= piezo_ctrl[18];
					else begin
						piezo_duration <= 0;
						piezo_state <= 11;
					end
				end
			11:	begin
					piezo_duration <= piezo_duration + 1;
					if(piezo_duration <= 10000000) PIEZO_SPEAKER <= 0;
					else begin
						piezo_duration <= 0;
						piezo_state <= 12;
					end
				end		
			12:	begin
					if(new_sound == 1) piezo_state <= 12;
					else piezo_state <= 0;
				end
		endcase	
	end

	
endmodule
