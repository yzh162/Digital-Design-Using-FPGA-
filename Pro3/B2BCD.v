// Transfer a binary number to BCD
module B2BCD(binary, dig4, dig3, dig2 ,dig1);
	input		[10:0]	binary;
	output	reg	[3:0]	dig4, dig3, dig2, dig1;
	
	reg		[10:0]	bin;
	reg		[15:0]	tmp;
	
	always @(binary)	begin
		bin = binary;
		tmp = 0;
		repeat(10)
			begin
				tmp[0] = bin[10];
				if (tmp[3:0] > 4)	tmp[3:0] = tmp[3:0]+3;
				if (tmp[7:4] > 4)	tmp[7:4] = tmp[7:4]+3;
				if (tmp[11:8] > 4)	tmp[11:8] = tmp[11:8]+3;
				if (tmp[15:12] > 4)	tmp[15:12] = tmp[15:12]+3;
				tmp = tmp << 1;
				bin = bin << 1;
			end
		tmp[0] = bin[10];
		dig4 <= tmp[15:12];
		dig3 <= tmp[11:8];
		dig2 <= tmp[7:4];
		dig1 <= tmp[3:0];
	end
endmodule 