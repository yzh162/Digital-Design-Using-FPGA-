`timescale 1ns / 1ps
//Reset is GPIO_SW[0] connect with FPGA
//FPGA_SERIAL1_TX to output the data:scanvalue
//TX_Request is the signal to allow rs232 to transmit data
//TX_Data is Scanvalue 对应的显示屏上的数字


module rs232(USER_CLK, Reset, FPGA_SERIAL1_TX, TX_Request, TX_Data, Busy);
    input               USER_CLK;
    input               Reset;
    output reg          FPGA_SERIAL1_TX;    // 1 is stop bit and 0 is idle state and the middle is the data transmitter
    output reg          Busy;
    input               TX_Request;  //一个周期后,TX_Request=0
    input      [7:0]    TX_Data;
	 
    reg	       [9:0]    rs232ctr;
    reg                 rs232clk;
    reg        [3:0]    rs232state;


    always @(posedge USER_CLK) begin : RS232Clk
		  
		// Reset will take priority over other signals. 
		if(Reset) begin
			Busy <= 0;
			FPGA_SERIAL1_TX <= 1;
			rs232state <= 4'b0000;
			rs232clk = 0;
			rs232ctr = 0;
			disable RS232Clk;    // if Reset = 1, then always block will not work 
		end
		  
		// TX_Request signal requests the start of transmission. Set State = 1 {start bit}
		if(TX_Request) begin  // TX_Request is the start bit
			rs232state <= 4'b0001;
			Busy <= 1;        // When TX_Request is 1, then the line is busy. So disable the always block. 
							  // Wait for the TX_Request to go down to start transmitting
			disable RS232Clk;
		end

		rs232ctr = rs232ctr+1;    	 // 115200Hz is transmitt 115200 data per second
		if (rs232ctr == 868) begin   // 100MHz / 868 = 115,200 Hz
			rs232ctr = 0;
			rs232clk = 1;			 // produce a rs232clk signal
		end else begin
			rs232clk = 0;
		end	  
		  
		// Frequency of bit transitions is based on Serial clock frequency
		if(~rs232clk) disable RS232Clk;   // rs232clk=0, save time, if not acheive the 868, will not excute
		  
		  
		case(rs232state)
			// State 0001 : Transmit Start bit
			4'b0001: begin FPGA_SERIAL1_TX <= 0;          rs232state <= 4'b0010; end
			// State 0010 : Transmit bit 0
			4'b0010: begin FPGA_SERIAL1_TX <= TX_Data[0]; rs232state <= 4'b0011; end
			// State 0011 : Transmit bit 1
			4'b0011: begin FPGA_SERIAL1_TX <= TX_Data[1]; rs232state <= 4'b0100; end
			// State 0100 : Transmit bit 2
			4'b0100: begin FPGA_SERIAL1_TX <= TX_Data[2]; rs232state <= 4'b0101; end
			// State 0101 : Transmit bit 3
			4'b0101: begin FPGA_SERIAL1_TX <= TX_Data[3]; rs232state <= 4'b0110; end
			// State 0110 : Transmit bit 4
			4'b0110: begin FPGA_SERIAL1_TX <= TX_Data[4]; rs232state <= 4'b0111; end
			// State 0111 : Transmit bit 5
			4'b0111: begin FPGA_SERIAL1_TX <= TX_Data[5]; rs232state <= 4'b1000; end
			// State 1000 : Transmit bit 6
			4'b1000: begin FPGA_SERIAL1_TX <= TX_Data[6]; rs232state <= 4'b1001; end
			// State 1001 : Transmit bit 7
			4'b1001: begin FPGA_SERIAL1_TX <= TX_Data[7]; rs232state <= 4'b1010; end
			// State 1010 : Transmit stop bit
			4'b1010: begin FPGA_SERIAL1_TX <= 1;          rs232state <= 4'b1011; end
			// State 1011 : Stop bit is done, Pull down 'Busy' signal after this
			4'b1011: begin FPGA_SERIAL1_TX <= 1;          rs232state <= 4'b0000; end
			// State 0000 : Idle
			default: begin Busy <= 0; FPGA_SERIAL1_TX <= 1; end
		endcase
	end

endmodule
