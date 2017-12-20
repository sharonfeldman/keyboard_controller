// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module VGA_WRITE
	// List of port declarations
	(
	CLK         ,
	RST_N       ,
	NEW_KEY     ,
	END_OF_LINE ,
	BACKSPACE   ,
	EMPTY       ,
	FULL        ,
	READY_RES   ,
	ASCII_CODE  ,
	ASCII_RES   ,
	ASCII_OUT   ,
	COLOR       ,
	COMMAND
	);


	//-------------------------------------------------------------------------------------------
	// Module Interface
	//-------------------------------------------------------------------------------------------

	input            CLK;          // Clock signal
	input            RST_N;        // Asynchronous reset

	input            NEW_KEY;      // key is pressed
	input            END_OF_LINE;  // 'Enter' key is pressed
	input            BACKSPACE;    // 'BackSpace' key is pressed

	input            EMPTY;        // buffer is empty
	input            FULL;         // buffer is full
	input            READY_RES;    // calculation is fished

	input      [7:0] ASCII_CODE;   // ASCII code of pressed key
	input      [7:0] ASCII_RES;    // ASCII code of result

	output     [7:0] ASCII_OUT;    // ASCII code of printed symbols
	output reg [7:0] COLOR;        // Color of symbol
	output reg [1:0] COMMAND;      // Command code for VGA
	//    "00" - display symbol
	//    "01" - delete symbol
	//    "10" - new line
	//    "11" - null


	//-------------------------------------------------------------------------------------------
	// Internal nets and variables
	//-------------------------------------------------------------------------------------------

	reg ascii_select;       // Select ASCII code for displaying
	//    '0' - from keyboard
	//    '1' - from FSM

	reg [7:0] ascii_temp;   // Temp signal for define symbol color

	//-------------------------------------------------------------------------------------------
	// Module behavior
	//-------------------------------------------------------------------------------------------

	always @(posedge CLK or negedge RST_N) begin // pr_behavior

		if (!RST_N) begin                         // asynchronous reset
				ascii_temp <= 8'b00000000;
				COMMAND    <= 2'b11;
				ascii_select <= 1'b0;
		end

		else if (READY_RES && ascii_select) begin // print result

				if (ASCII_RES == 8'b00000000) begin       // result output finished
						ascii_temp <= 8'b00000000;
						COMMAND    <= 2'b10;
						ascii_select <= 1'b0;
				end

				else begin                                // result output
						ascii_temp <= ASCII_RES;
						COMMAND    <= 2'b00;
				end

		end

		else if (NEW_KEY && !ascii_select) begin  // data entry

				if (BACKSPACE && !EMPTY) begin         // delete symbol
						ascii_temp <= 8'b00000000;
						COMMAND    <= 2'b01;
				end

				else if (!END_OF_LINE &&
					!FULL        &&
					!BACKSPACE        ) begin     // print symbol
						ascii_temp <= ASCII_CODE;
						COMMAND    <= 2'b00;
				end

				else if (END_OF_LINE) begin            // Lock data input
						ascii_select <= 1'b1;
				end

				else begin
						ascii_temp <= 8'b00000000;
						COMMAND    <= 2'b11;
				end

		end

		else begin                                // no action
				ascii_temp <= 8'b00000000;
				COMMAND    <= 2'b11;
		end

	end


	always @(ascii_temp) begin // color generate
		case (ascii_temp)

			// Numbers
			`P_ASCII_ONE,
				`P_ASCII_TWO,
				`P_ASCII_THREE,
				`P_ASCII_FOUR,
				`P_ASCII_FIVE,
				`P_ASCII_SIX,
				`P_ASCII_SEVEN,
				`P_ASCII_EIGHT,
				`P_ASCII_NINE,
				`P_ASCII_ZERO,
				`P_ASCII_COMMA,
			`P_ASCII_POINT       : COLOR = 8'b00011100; // Green

			// Letters
			`P_ASCII_A,
				`P_ASCII_B,
				`P_ASCII_C,
				`P_ASCII_D,
				`P_ASCII_E,
				`P_ASCII_F,
				`P_ASCII_G,
				`P_ASCII_H,
				`P_ASCII_I,
				`P_ASCII_J,
				`P_ASCII_K,
				`P_ASCII_L,
				`P_ASCII_M,
				`P_ASCII_N,
				`P_ASCII_O,
				`P_ASCII_P,
				`P_ASCII_Q,
				`P_ASCII_R,
				`P_ASCII_S,
				`P_ASCII_T,
				`P_ASCII_U,
				`P_ASCII_V,
				`P_ASCII_W,
				`P_ASCII_X,
				`P_ASCII_Y,
				`P_ASCII_Z,
			`P_ASCII_QUOTES      : COLOR = 8'b11100000; // Red

			// Operators
			`P_ASCII_PLUS,
				`P_ASCII_MINUR,
				`P_ASCII_MULTIPLE,
				`P_ASCII_SLASH,
				`P_ASCII_EQUAL,
				`P_ASCII_LBRACKET,
			`P_ASCII_RBRACKET    : COLOR = 8'b00000011; // Blue

			default              : COLOR = 8'b11111111; // White
		endcase
	end

	assign ASCII_OUT = ascii_temp;

endmodule // VGA_WRITE
