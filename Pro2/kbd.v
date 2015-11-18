module ps2kbd(KeyClk, KeyData, ScanValue, KbdCodeValid);
	 input                KeyClk, KeyData;
	 output     [7:0]     ScanValue;
	 output reg           KbdCodeValid;     // This goes to "1" when there is a new scan code

	 reg [7:0]            ScanCode, PreviousScanCode;
	 reg [3:0]            BitCtr;


   ScanRom S1 (ScanValue, ScanCode);

	 always @(negedge KeyClk) begin
       case (BitCtr)
		    // Start Bit has to be 0
		    0: begin
			       KbdCodeValid <= 0;
			       if(KeyData != 0) begin
					    ScanCode <= 0;
					    BitCtr <= 0;
					 end else BitCtr <= 1;    // Correct start bit
				 end
			 // Data bits - 8 of them
		    1, 2, 3, 4, 5, 6, 7, 8 : begin 
			                             ScanCode[BitCtr-1] <= KeyData;
												  BitCtr <= BitCtr + 1;
                           		  end
			 // Odd Parity bit
		    9: begin
			       if(~(^ScanCode) != KeyData) begin  // Trash data if odd parity doesn't match
					    ScanCode <= 0;
					    BitCtr <= 0; 
					 end else begin
					    BitCtr <= BitCtr + 1; // Parity bit is correct
						 if(PreviousScanCode == 8'hF0) begin // presume correct stop bit
					      KbdCodeValid <= 1;
					    end
					 end
				 end
			// Stop bit has to be 1
		    10: begin
		          if(KeyData != 1) begin
				       ScanCode <= 0;     // Invalid stop bit
						 PreviousScanCode <= 0;
						 BitCtr <= 0;
				    end
                PreviousScanCode <= ScanCode;
					 BitCtr <= 0;
					 KbdCodeValid <= 0; // Falling edge of CodeValid signals completed scan code
				  end // Case 10
		    default : begin
			              BitCtr <= 0;
							  KbdCodeValid <= 0;
						  end
		 endcase
	 end


endmodule
