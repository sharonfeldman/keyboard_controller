// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module SCAN2ASCII
	// List of port declarations
	(
	SCAN_CODE  ,
	ASCII_CODE
	);

	//-------------------------------------------------------------------------------------------
	// Module Interface
	//-------------------------------------------------------------------------------------------

	input      [7:0] SCAN_CODE;  // scan code from PS/2 interface
	output reg [7:0] ASCII_CODE; // ascii_code for VGA writer



	//-------------------------------------------------------------------------------------------
	// Module behavior
	//-------------------------------------------------------------------------------------------

	always @(SCAN_CODE) begin // pr_decoder

		case (SCAN_CODE)

			// NUMBERS
			`P_SCAN_ONE,
			`P_SCAN_ONE_N   : ASCII_CODE = `P_ASCII_ONE   ; // "1"
			`P_SCAN_TWO,
			`P_SCAN_TWO_N   : ASCII_CODE = `P_ASCII_TWO   ; // "2"
			`P_SCAN_THREE,
			`P_SCAN_THREE_N : ASCII_CODE = `P_ASCII_THREE ; // "3"
			`P_SCAN_FOUR,
			`P_SCAN_FOUR_N  : ASCII_CODE = `P_ASCII_FOUR  ; // "4"
			`P_SCAN_FIVE,
			`P_SCAN_FIVE_N  : ASCII_CODE = `P_ASCII_FIVE  ; // "5"
			`P_SCAN_SIX,
			`P_SCAN_SIX_N   : ASCII_CODE = `P_ASCII_SIX   ; // "6"
			`P_SCAN_SEVEN,
			`P_SCAN_SEVEN_N : ASCII_CODE = `P_ASCII_SEVEN ; // "7"
			`P_SCAN_EIGHT,
			`P_SCAN_EIGHT_N : ASCII_CODE = `P_ASCII_EIGHT ; // "8"
			`P_SCAN_NINE,
			`P_SCAN_NINE_N  : ASCII_CODE = `P_ASCII_NINE  ; // "9"
			`P_SCAN_ZERO,
			`P_SCAN_ZERO_N  : ASCII_CODE = `P_ASCII_ZERO  ; // "0"

			// LETTERS
			`P_SCAN_A : ASCII_CODE = `P_ASCII_A; // "A"
			`P_SCAN_B : ASCII_CODE = `P_ASCII_B; // "B"
			`P_SCAN_C : ASCII_CODE = `P_ASCII_C; // "C"
			`P_SCAN_D : ASCII_CODE = `P_ASCII_D; // "D"
			`P_SCAN_E : ASCII_CODE = `P_ASCII_E; // "E"
			`P_SCAN_F : ASCII_CODE = `P_ASCII_F; // "F"
			`P_SCAN_G : ASCII_CODE = `P_ASCII_G; // "G"
			`P_SCAN_H : ASCII_CODE = `P_ASCII_H; // "H"
			`P_SCAN_I : ASCII_CODE = `P_ASCII_I; // "I"
			`P_SCAN_J : ASCII_CODE = `P_ASCII_J; // "J"
			`P_SCAN_K : ASCII_CODE = `P_ASCII_K; // "K"
			`P_SCAN_L : ASCII_CODE = `P_ASCII_L; // "L"
			`P_SCAN_M : ASCII_CODE = `P_ASCII_M; // "M"
			`P_SCAN_N : ASCII_CODE = `P_ASCII_N; // "N"
			`P_SCAN_O : ASCII_CODE = `P_ASCII_O; // "O"
			`P_SCAN_P : ASCII_CODE = `P_ASCII_P; // "P"
			`P_SCAN_Q : ASCII_CODE = `P_ASCII_Q; // "Q"
			`P_SCAN_R : ASCII_CODE = `P_ASCII_R; // "R"
			`P_SCAN_S : ASCII_CODE = `P_ASCII_S; // "S"
			`P_SCAN_T : ASCII_CODE = `P_ASCII_T; // "T"
			`P_SCAN_U : ASCII_CODE = `P_ASCII_U; // "U"
			`P_SCAN_V : ASCII_CODE = `P_ASCII_V; // "V"
			`P_SCAN_W : ASCII_CODE = `P_ASCII_W; // "W"
			`P_SCAN_X : ASCII_CODE = `P_ASCII_X; // "X"
			`P_SCAN_Y : ASCII_CODE = `P_ASCII_Y; // "Y"
			`P_SCAN_Z : ASCII_CODE = `P_ASCII_Z; // "Z"

			// OPERATIONS
			`P_SCAN_MINUS,
			`P_SCAN_MINUS_N    : ASCII_CODE = `P_ASCII_MINUR ;   // "-"
			`P_SCAN_EQUAL      : ASCII_CODE = `P_ASCII_EQUAL ;   // "="
			`P_SCAN_COMMA      : ASCII_CODE = `P_ASCII_COMMA ;   // ","
			`P_SCAN_POINT,
			`P_SCAN_POINT_N    : ASCII_CODE = `P_ASCII_POINT ;   // "."
			`P_SCAN_SLASH      : ASCII_CODE = `P_ASCII_SLASH ;   // "/"
			`P_SCAN_PLUS_N     : ASCII_CODE = `P_ASCII_PLUS  ;   // "+"
			`P_SCAN_MULTIPLE_N : ASCII_CODE = `P_ASCII_MULTIPLE; // "*"

			`P_SCAN_LBRACKET   : ASCII_CODE = `P_ASCII_LBRACKET; // (
			`P_SCAN_RBRACKET   : ASCII_CODE = `P_ASCII_RBRACKET; // )

			`P_SCAN_QUOTES     : ASCII_CODE = `P_ASCII_QUOTES  ; // "

			`P_SCAN_SPACE : ASCII_CODE = `P_ASCII_SPACE ; // space

			default : ASCII_CODE = {8{1'bx}};

		endcase

	end // pr_decoder

endmodule // SCAN2ASCII
