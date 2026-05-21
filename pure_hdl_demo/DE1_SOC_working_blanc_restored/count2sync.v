module COUNT2SYNC(	

			    iRST_N,
          iCLK, 

					VGA_H_CONT,
				VGA_V_CONT,
          VGA_HS ,	
           VGA_VS 
);

`include "V/VGA_Param.h"

reg	[12:0]	H_Cont;
reg	[12:0]	V_Cont;
output reg				VGA_HS;
output reg				VGA_VS;
input [12:0] VGA_H_CONT;
input [12:0] VGA_V_CONT;
input iRST_N;
input iCLK;
parameter	X_DELAY =	19;
parameter	Y_DELAY =	12;

always@(posedge iCLK or negedge iRST_N)
begin

	if(!iRST_N)
	begin
		H_Cont = 0;
		V_Cont = 0;		
	end
	else
	begin
		H_Cont = (VGA_H_CONT + X_DELAY<H_SYNC_TOTAL)?VGA_H_CONT+X_DELAY:(VGA_H_CONT+X_DELAY-H_SYNC_TOTAL);
		V_Cont = (VGA_H_CONT + X_DELAY<H_SYNC_TOTAL)?(
		(VGA_V_CONT+Y_DELAY<V_SYNC_TOTAL)?(VGA_V_CONT+Y_DELAY):(VGA_V_CONT+Y_DELAY-V_SYNC_TOTAL)
		):
		( 
		(VGA_V_CONT+Y_DELAY+1<V_SYNC_TOTAL)?(VGA_V_CONT+Y_DELAY+1):(VGA_V_CONT+Y_DELAY+1-V_SYNC_TOTAL)
		);
	end

end


//	H_Sync Generator, Ref. 25.175 MHz Clock
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		//H_Cont		<=	0;
		VGA_HS	<=	0;
	end
	else
	begin
		//	H_Sync Counter
		//if( H_Cont < H_SYNC_TOTAL )
		//H_Cont	<=	H_Cont+1;
		//else
		//H_Cont	<=	0;
		//	H_Sync Generator
		if( (H_Cont < X_START) || (H_Cont> X_START+H_SYNC_ACT))
		VGA_HS	<=	0;
		else
		VGA_HS	<=	1;
	end
end

//	V_Sync Generator, Ref. H_Sync
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		//V_Cont		<=	0;
		VGA_VS	<=	0;
	end
	else
	begin
		//	When H_Sync Re-start
		if(H_Cont==0)
		begin
			//	V_Sync Counter
			//if( V_Cont < V_SYNC_TOTAL )
			//V_Cont	 <=	V_Cont+1;
			//else
			//V_Cont	<=	0;
			//	V_Sync Generator
			if( (V_Cont < Y_START) || (V_Cont> Y_START+V_SYNC_ACT))
			VGA_VS	<=	0;
			else
			VGA_VS	<=	1;
		end
	end
end

endmodule
