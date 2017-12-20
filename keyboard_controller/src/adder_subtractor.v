// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module ADDER_SUBTRACTOR (
	SCLR, CE, CLK, ADD, A, B, C_OUT, S
	);
	input SCLR;
	input CE;
	input CLK;
	input ADD;
	input [31 : 0] A;
	input [31 : 0] B;
	output C_OUT;
	output [31 : 0] S;

	reg [32:0] RES;

	always @(posedge CLK or posedge SCLR) begin
		if (SCLR)
		RES <= 33'B0;
		else if (CE) begin
				case (ADD)
					1'B0 : RES <= A - B;
					1'B1 : RES <= A + B;
					default : RES <= 33'Bx;
				endcase
		end
	end

	assign {C_OUT,S} = RES;

endmodule
