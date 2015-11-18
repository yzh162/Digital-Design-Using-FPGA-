`timescale 1ns / 1ps
module ScanRom(ScanValue, ScanCode);
    output reg [7:0]   ScanValue;
	 input      [7:0]   ScanCode;

    always @(ScanCode) begin
       case (ScanCode)
		    8'h45  : ScanValue = "0";
		    8'h16  : ScanValue = "1";
		    8'h1E  : ScanValue = "2";
		    8'h26  : ScanValue = "3";
		    8'h25  : ScanValue = "4";
		    8'h2E  : ScanValue = "5";
		    8'h36  : ScanValue = "6";
		    8'h3D  : ScanValue = "7";
		    8'h3E  : ScanValue = "8";
		    8'h46  : ScanValue = "9";

		    8'h55  : ScanValue = "+";
		    8'h7C  : ScanValue = "*";
		    8'h41  : ScanValue = "<";
		    8'h49  : ScanValue = ">";
		    8'h5A  : ScanValue = "=";
		    8'h76  : ScanValue = "E";

			 default: ScanValue = 8'hFF;
		 endcase
	 end
endmodule




