module RGB2Y ( 
input [ 7:0] iR,
input [ 7:0] iG,
input [ 7:0] iB,
input clk,
output  [7:0] Y_Channel


);// 
 
reg [17:0] Y21;
reg [17:0] Y22;
reg [17:0] Y2;
// Y = R *  //.299   = 256 * 0.299 = 77 // + G *  // .587  = 256 * .587  = 150 //+ B *  //.114  =  256 *  .114  = 29

reg [7:0] rR;
reg [7:0] rG;
reg [7:0] rB;

 
wire [7:0] Y3;
reg [14:0] Y4;
wire [9:0] Y5;
reg [7:0] Y6; 
assign Y3 = Y2[15:8];
assign Y5 = Y4[14:5];
assign Y_Channel[7:0] = Y6[7:0];



	 
always @(posedge clk )
	begin 
	
	//---RGB2Y--- 
	
	rR <= iR;
	rG <= iG;
	rB <= iB;
	
  Y21 <= (rR * 77 +  rG *150);
  Y22 <= rB*29;

  Y2<=Y21 + Y22;
	

		Y4 <=  (Y3*92);
		if (Y5 < 200)
			begin
				Y6<= 0;
			end
		else
			begin
				if (Y5>455)
					begin
						Y6 <= 255;
					end
				else
					begin
						Y6 <= Y5-200;
					end
			end
end 
	 	 
endmodule 
	 