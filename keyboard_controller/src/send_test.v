// (c) Aldec, Inc.
// All rights REServed.
//
// Last modified: $Date: 2011-12-23 15:26:07 +0100 (Fri, 23 Dec 2011) $
// $Revision: 191259 $

`include "scan_codes.v"
`include "settings.v"

module SEND_TEST ( CLK_TEST, RST_N, RES, FILE, DATA, PS2CLK);
	input CLK_TEST;
	input RST_N;
	input [7:0] RES;
	input int FILE;
	output reg DATA;
	output reg PS2CLK;

	bit [7:0] scan_code;
	string test;
	int code;
	bit ready;

	// gets symbol scan code
	function [7:0] sym2scan (string sym);
		reg [7:0] scan;

		case (sym)
			// NUMBERS
			"1" : scan =   `P_SCAN_ONE ;
			"2" : scan =   `P_SCAN_TWO ;
			"3" : scan =   `P_SCAN_THREE;
			"4" : scan =   `P_SCAN_FOUR;
			"5" : scan =   `P_SCAN_FIVE;
			"6" : scan =   `P_SCAN_SIX;
			"7" : scan =   `P_SCAN_SEVEN;
			"8" : scan =   `P_SCAN_EIGHT;
			"9" : scan =   `P_SCAN_NINE;
			"0" : scan =   `P_SCAN_ZERO;
			// LETTERS
			"A" : scan =   `P_SCAN_A;
			"B" : scan =   `P_SCAN_B;
			"C" : scan =   `P_SCAN_C;
			"D" : scan =   `P_SCAN_D;
			"E" : scan =   `P_SCAN_E;
			"F" : scan =   `P_SCAN_F;
			"G" : scan =   `P_SCAN_G;
			"H" : scan =   `P_SCAN_H;
			"I" : scan =   `P_SCAN_I;
			"J" : scan =   `P_SCAN_J;
			"K" : scan =   `P_SCAN_K;
			"L" : scan =   `P_SCAN_L;
			"M" : scan =   `P_SCAN_M;
			"N" : scan =   `P_SCAN_N;
			"O" : scan =   `P_SCAN_O;
			"P" : scan =   `P_SCAN_P;
			"Q" : scan =   `P_SCAN_Q;
			"R" : scan =   `P_SCAN_R;
			"S" : scan =   `P_SCAN_S;
			"T" : scan =   `P_SCAN_T;
			"U" : scan =   `P_SCAN_U;
			"V" : scan =   `P_SCAN_V;
			"W" : scan =   `P_SCAN_W;
			"X" : scan =   `P_SCAN_X;
			"Y" : scan =   `P_SCAN_Y;
			"Z" : scan =   `P_SCAN_Z;
			// OPERATIONS
			"/" : scan =   `P_SCAN_SLASH;
			"*" : scan =   `P_SCAN_MULTIPLE_N;
			"-" : scan =   `P_SCAN_MINUS_N;
			"+" : scan =   `P_SCAN_PLUS_N;
			"." : scan =   `P_SCAN_POINT_N;
			"(" : scan =   `P_SCAN_LBRACKET;
			")" : scan =   `P_SCAN_RBRACKET;
			// NON-PRINTABLE CHARACTERS
			"ENTER" : scan = `P_SCAN_ENTER;
			"BKSC"  : scan = `P_SCAN_BACKSPACE;
		endcase

		return scan;
	endfunction

	initial
	begin
		code = $fgets(test, FILE);
		$display( "test : %s", test );
		ready = 1'b1;
	end

	always @(RES) begin
		if (RES == 8'h3D) begin
				repeat (100) @(posedge CLK_TEST);
				code = $fgets( test, FILE );
				if (code)
					ready = 1'b1;
				else
					$finish;
				$display( "test : %s", test );
		end
	end

	// generates sequence of single test DATA
	always @(posedge ready) begin
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
		for ( int i = 0; i < (test.len()-1); ++i ) begin
				// start bit
				DATA = @(posedge CLK_TEST) 'b0;
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
				// symbol bits
				scan_code = sym2scan(test.substr(i,i));
				for ( int j = 0; j < 8; ++j ) begin
						DATA = @(posedge CLK_TEST) scan_code[j];
						PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
						PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
					end
				// parity bit
				DATA = @(posedge CLK_TEST) ^scan_code;
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
				// stop bit
				DATA = @(posedge CLK_TEST) 'b1;
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
			end

		scan_code = sym2scan("ENTER");
		// start bit
		DATA = @(posedge CLK_TEST) 'b0;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
		for ( int j = 0; j < 8; ++j ) begin
				DATA = @(posedge CLK_TEST) scan_code[j];
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
				PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
			end
		// parity bit
		DATA = @(posedge CLK_TEST) ^scan_code;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
		// stop bit
		DATA = @(posedge CLK_TEST) 'b1;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b1;
		ready = 1'b0;
		PS2CLK = repeat (8) @(posedge CLK_TEST) 'b0;
	end

endmodule
