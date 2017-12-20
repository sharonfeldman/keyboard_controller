// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module SYMBOL2ASCII
	// Module parameter port list
	#(
	parameter P_SYMBOL_WIDTH_S2A   = `P_SYMBOL_CODE_WIDTH
	)

	// List of port declarations
	(
	SYMBOL_CODE,
	ASCII_CODE
	);


	//-------------------------------------------------------------------------------------------
	// Module Interface
	//-------------------------------------------------------------------------------------------

	input      [P_SYMBOL_WIDTH_S2A-1:0]  SYMBOL_CODE; // Code of symbol from Calculator controller
	output reg [7:0]                     ASCII_CODE;  // ASCII code for VGA module


	//-------------------------------------------------------------------------------------------
	// Module behavior
	//-------------------------------------------------------------------------------------------

	always @(SYMBOL_CODE) begin // pr_encoder

		case (SYMBOL_CODE)

			`P_SYMBOL_ZERO     : ASCII_CODE = `P_ASCII_ZERO     ; // "0"
			`P_SYMBOL_ONE      : ASCII_CODE = `P_ASCII_ONE      ; // "1"
			`P_SYMBOL_TWO      : ASCII_CODE = `P_ASCII_TWO      ; // "2"
			`P_SYMBOL_THREE    : ASCII_CODE = `P_ASCII_THREE    ; // "3"
			`P_SYMBOL_FOUR     : ASCII_CODE = `P_ASCII_FOUR     ; // "4"
			`P_SYMBOL_FIVE     : ASCII_CODE = `P_ASCII_FIVE     ; // "5"
			`P_SYMBOL_SIX      : ASCII_CODE = `P_ASCII_SIX      ; // "6"
			`P_SYMBOL_SEVEN    : ASCII_CODE = `P_ASCII_SEVEN    ; // "7"
			`P_SYMBOL_EIGHT    : ASCII_CODE = `P_ASCII_EIGHT    ; // "8"
			`P_SYMBOL_NINE     : ASCII_CODE = `P_ASCII_NINE     ; // "9"

			`P_SYMBOL_A        : ASCII_CODE = `P_ASCII_A        ; // "A"
			`P_SYMBOL_B        : ASCII_CODE = `P_ASCII_B        ; // "B"
			`P_SYMBOL_C        : ASCII_CODE = `P_ASCII_C        ; // "C"
			`P_SYMBOL_D        : ASCII_CODE = `P_ASCII_D        ; // "D"
			`P_SYMBOL_E        : ASCII_CODE = `P_ASCII_E        ; // "E"
			`P_SYMBOL_F        : ASCII_CODE = `P_ASCII_F        ; // "F"
			`P_SYMBOL_G        : ASCII_CODE = `P_ASCII_G        ; // "G"
			`P_SYMBOL_H        : ASCII_CODE = `P_ASCII_H        ; // "H"
			`P_SYMBOL_I        : ASCII_CODE = `P_ASCII_I        ; // "I"
			`P_SYMBOL_J        : ASCII_CODE = `P_ASCII_J        ; // "J"
			`P_SYMBOL_K        : ASCII_CODE = `P_ASCII_K        ; // "K"
			`P_SYMBOL_L        : ASCII_CODE = `P_ASCII_L        ; // "L"
			`P_SYMBOL_M        : ASCII_CODE = `P_ASCII_M        ; // "M"
			`P_SYMBOL_N        : ASCII_CODE = `P_ASCII_N        ; // "N"
			`P_SYMBOL_O        : ASCII_CODE = `P_ASCII_O        ; // "O"
			`P_SYMBOL_P        : ASCII_CODE = `P_ASCII_P        ; // "P"
			`P_SYMBOL_Q        : ASCII_CODE = `P_ASCII_Q        ; // "Q"
			`P_SYMBOL_R        : ASCII_CODE = `P_ASCII_R        ; // "R"
			`P_SYMBOL_S        : ASCII_CODE = `P_ASCII_S        ; // "S"
			`P_SYMBOL_T        : ASCII_CODE = `P_ASCII_T        ; // "T"
			`P_SYMBOL_U        : ASCII_CODE = `P_ASCII_U        ; // "U"
			`P_SYMBOL_V        : ASCII_CODE = `P_ASCII_V        ; // "V"
			`P_SYMBOL_W        : ASCII_CODE = `P_ASCII_W        ; // "W"
			`P_SYMBOL_X        : ASCII_CODE = `P_ASCII_X        ; // "X"
			`P_SYMBOL_Y        : ASCII_CODE = `P_ASCII_Y        ; // "Y"
			`P_SYMBOL_Z        : ASCII_CODE = `P_ASCII_Z        ; // "Z"

			`P_SYMBOL_PLUS     : ASCII_CODE = `P_ASCII_PLUS     ; // "+"
			`P_SYMBOL_MINUS    : ASCII_CODE = `P_ASCII_MINUR    ; // "-"
			`P_SYMBOL_MULTIPLE : ASCII_CODE = `P_ASCII_MULTIPLE ; // "*"
			`P_SYMBOL_SLASH    : ASCII_CODE = `P_ASCII_SLASH    ; // "/"

			`P_SYMBOL_EQUAL    : ASCII_CODE = `P_ASCII_EQUAL    ; // "="

			`P_SYMBOL_COMMA    : ASCII_CODE = `P_ASCII_COMMA    ; // ","
			`P_SYMBOL_POINT    : ASCII_CODE = `P_ASCII_POINT    ; // "."

			`P_SYMBOL_SPACE    : ASCII_CODE = `P_ASCII_SPACE    ; // space
			`P_SYMBOL_QUOTES   : ASCII_CODE = `P_ASCII_QUOTES   ; // " " "
			`P_SYMBOL_ENTER    : ASCII_CODE = 8'b00000000       ; // enter

			default            : ASCII_CODE = 8'bxxxxxxxx       ;

		endcase

	end // pr_encoder


endmodule // SYMBOL2ASCII
