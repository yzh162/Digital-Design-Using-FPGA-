module sound(USER_CLK, PIEZO_SPEAKER, reque ,finish);
input USER_CLK;
input reque;
output  reg PIEZO_SPEAKER;

reg [27:0] timectr;
parameter NN = 200000000;
parameter ll = 134;
output reg finish;

always @(negedge USER_CLK) begin : mlk
	if(reque) begin
		finish <= 0;
		timectr <= 0;
		disable mlk;
		end
	if(~finish)begin
		if(timectr >= NN) begin
			finish <=1;
			timectr <= 0;
		end else begin
			PIEZO_SPEAKER <= timectr[24];
			timectr <= timectr + ll;
			end
		end
 end
 endmodule
 