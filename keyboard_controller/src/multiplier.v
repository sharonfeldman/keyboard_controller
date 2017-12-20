// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module MULTIPLIER (
	SCLR, CE, CLK, A, B, P
	);
	input SCLR;
	input CE;
	input CLK;
	input [31 : 0] A;
	input [31 : 0] B;
	output reg [63 : 0] P;

	always @(posedge CLK or posedge SCLR) begin
		if (SCLR)
		P <= 64'b0;
		else if (CE)
		P <= A * B;
	end

endmodule
