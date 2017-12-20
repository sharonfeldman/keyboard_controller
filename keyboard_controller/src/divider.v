// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module DIVIDER (SCLR, CE, CLK, DEVIDENT, QUOTIENT, DIVISOR, FRACTIONAL);
	input SCLR;
	input CE;
	input CLK;
	input signed [31 : 0] DEVIDENT;
	output reg signed [31 : 0] QUOTIENT;
	input signed [31 : 0] DIVISOR;
	output reg signed [31 : 0] FRACTIONAL;

	always @(posedge CLK or posedge SCLR) begin
		if (SCLR) begin
				QUOTIENT <= 32'b0;
				FRACTIONAL <= 32'b0;
		end
		else if (CE) begin
				QUOTIENT <= DEVIDENT / DIVISOR;
				FRACTIONAL <= DEVIDENT % DIVISOR;
		end
	end

endmodule
