// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module SCAN2SYMBOL
	// Module parameter port list
	#(
	parameter P_SYMBOL_WIDTH_S2S   = `P_SYMBOL_CODE_WIDTH
	)

	// List of port declarations
	(
	SCAN_CODE  ,
	SYMBOL_CODE
	);


	//-------------------------------------------------------------------------------------------
	// Module Interface
	//-------------------------------------------------------------------------------------------

	input      [7:0]                    SCAN_CODE;     // scan code from PS/2 interface
	output reg [P_SYMBOL_WIDTH_S2S-1:0] SYMBOL_CODE;   // code of symbol


	//-------------------------------------------------------------------------------------------
	// Module behavior
	//-------------------------------------------------------------------------------------------

	always @(SCAN_CODE) begin // pr_encoder

		case (SCAN_CODE)

			`P_SCAN_ONE,
			`P_SCAN_ONE_N      : SYMBOL_CODE = `P_SYMBOL_ONE      ; // "1"
			`P_SCAN_TWO,
			`P_SCAN_TWO_N      : SYMBOL_CODE = `P_SYMBOL_TWO      ; // "2"
			`P_SCAN_THREE,
			`P_SCAN_THREE_N    : SYMBOL_CODE = `P_SYMBOL_THREE    ; // "3"
			`P_SCAN_FOUR,
			`P_SCAN_FOUR_N     : SYMBOL_CODE = `P_SYMBOL_FOUR     ; // "4"
			`P_SCAN_FIVE,
			`P_SCAN_FIVE_N     : SYMBOL_CODE = `P_SYMBOL_FIVE     ; // "5"
			`P_SCAN_SIX,
			`P_SCAN_SIX_N      : SYMBOL_CODE = `P_SYMBOL_SIX      ; // "6"
			`P_SCAN_SEVEN,
			`P_SCAN_SEVEN_N    : SYMBOL_CODE = `P_SYMBOL_SEVEN    ; // "7"
			`P_SCAN_EIGHT,
			`P_SCAN_EIGHT_N    : SYMBOL_CODE = `P_SYMBOL_EIGHT    ; // "8"
			`P_SCAN_NINE,
			`P_SCAN_NINE_N     : SYMBOL_CODE = `P_SYMBOL_NINE     ; // "9"
			`P_SCAN_ZERO,
			`P_SCAN_ZERO_N     : SYMBOL_CODE = `P_SYMBOL_ZERO     ; // "0"

			`P_SCAN_A          : SYMBOL_CODE = `P_SYMBOL_A        ; // "A"
			`P_SCAN_B          : SYMBOL_CODE = `P_SYMBOL_B        ; // "B"
			`P_SCAN_C          : SYMBOL_CODE = `P_SYMBOL_C        ; // "C"
			`P_SCAN_D          : SYMBOL_CODE = `P_SYMBOL_D        ; // "D"
			`P_SCAN_E          : SYMBOL_CODE = `P_SYMBOL_E        ; // "E"
			`P_SCAN_F          : SYMBOL_CODE = `P_SYMBOL_F        ; // "F"
			`P_SCAN_G          : SYMBOL_CODE = `P_SYMBOL_G        ; // "G"
			`P_SCAN_H          : SYMBOL_CODE = `P_SYMBOL_H        ; // "H"
			`P_SCAN_I          : SYMBOL_CODE = `P_SYMBOL_I        ; // "I"
			`P_SCAN_J          : SYMBOL_CODE = `P_SYMBOL_J        ; // "J"
			`P_SCAN_K          : SYMBOL_CODE = `P_SYMBOL_K        ; // "K"
			`P_SCAN_L          : SYMBOL_CODE = `P_SYMBOL_L        ; // "L"
			`P_SCAN_M          : SYMBOL_CODE = `P_SYMBOL_M        ; // "M"
			`P_SCAN_N          : SYMBOL_CODE = `P_SYMBOL_N        ; // "N"
			`P_SCAN_O          : SYMBOL_CODE = `P_SYMBOL_O        ; // "O"
			`P_SCAN_P          : SYMBOL_CODE = `P_SYMBOL_P        ; // "P"
			`P_SCAN_Q          : SYMBOL_CODE = `P_SYMBOL_Q        ; // "Q"
			`P_SCAN_R          : SYMBOL_CODE = `P_SYMBOL_R        ; // "R"
			`P_SCAN_S          : SYMBOL_CODE = `P_SYMBOL_S        ; // "S"
			`P_SCAN_T          : SYMBOL_CODE = `P_SYMBOL_T        ; // "T"
			`P_SCAN_U          : SYMBOL_CODE = `P_SYMBOL_U        ; // "U"
			`P_SCAN_V          : SYMBOL_CODE = `P_SYMBOL_V        ; // "V"
			`P_SCAN_W          : SYMBOL_CODE = `P_SYMBOL_W        ; // "W"
			`P_SCAN_X          : SYMBOL_CODE = `P_SYMBOL_X        ; // "X"
			`P_SCAN_Y          : SYMBOL_CODE = `P_SYMBOL_Y        ; // "Y"
			`P_SCAN_Z          : SYMBOL_CODE = `P_SYMBOL_Z        ; // "Z"

			`P_SCAN_PLUS_N     : SYMBOL_CODE = `P_SYMBOL_PLUS     ; // "+"
			`P_SCAN_MINUS,
			`P_SCAN_MINUS_N    : SYMBOL_CODE = `P_SYMBOL_MINUS    ; // "-"
			`P_SCAN_MULTIPLE_N : SYMBOL_CODE = `P_SYMBOL_MULTIPLE ; // "*"
			`P_SCAN_SLASH      : SYMBOL_CODE = `P_SYMBOL_SLASH    ; // "/"
			`P_SCAN_EQUAL      : SYMBOL_CODE = `P_SYMBOL_EQUAL    ; // "="

			`P_SCAN_POINT,
			`P_SCAN_POINT_N    : SYMBOL_CODE = `P_SYMBOL_POINT    ; // "."
			`P_SCAN_COMMA      : SYMBOL_CODE = `P_SYMBOL_COMMA    ; // ","

			`P_SCAN_LBRACKET   : SYMBOL_CODE = `P_SYMBOL_LBRACKET ; // "("
			`P_SCAN_RBRACKET   : SYMBOL_CODE = `P_SYMBOL_RBRACKET ; // ")"

			`P_SCAN_QUOTES     : SYMBOL_CODE = `P_SYMBOL_QUOTES   ; // "

			`P_SCAN_SPACE      : SYMBOL_CODE = `P_SYMBOL_SPACE    ; // space
			`P_SCAN_ENTER      : SYMBOL_CODE = `P_SYMBOL_ENTER    ; // enter

			default            : SYMBOL_CODE = {P_SYMBOL_WIDTH_S2S{1'bx}};

		endcase

	end // pr_encoder

endmodule // SCAN2SYMBOL
