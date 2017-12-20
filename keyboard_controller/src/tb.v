// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module TB #(parameter string INPUT_FILENAME);

	reg        RST_N;        // Asynchronous reset (active low)
	reg        DATA;         // Data from keyboard
	reg        CLK_50MHZ;    // Clock signal 50MHz
	reg        PS2CLK;

	reg [7:0] ASCII_OUT;    // ASCII code of printed symbols
	reg [7:0] COLOR;
	reg [1:0] COMMAND;      // Command code for VGA
	                        //    "00" - display symbol
	                        //    "01" - delete symbol
	                        //    "10" - new line
	                       //    "11" - null

	int file;

	KEYBOARD_CONTROLLER UUT (RST_N,DATA,CLK_50MHZ,PS2CLK,ASCII_OUT,COLOR,COMMAND);

	CLK_GEN CLK_GEN_UUT (CLK_50MHZ);

	CLK_GEN #(50) CLK_GEN_TB (CLK_TEST);

	SEND_TEST SEND_TEST (CLK_TEST, RST_N, ASCII_OUT, file, DATA, PS2CLK);

	initial begin
			file = $fopen(INPUT_FILENAME, "r");
			RST_N = 0;
			#1;
			RST_N = 1;
			#1;
		end

endmodule

module CLK_GEN #(parameter P = 10)(CLK);
	output bit CLK = 1;
	always #P CLK = ~CLK;
endmodule
