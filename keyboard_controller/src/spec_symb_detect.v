// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module SPEC_SYMB_DETECT
	// List of port declarations
	(
	SCAN_CODE   ,
	END_OF_LINE ,
	BACKSPACE
	);


	//-------------------------------------------------------------------------------------------
	// Module Interface
	//-------------------------------------------------------------------------------------------

	input  [7:0] SCAN_CODE;    // scan code from PS/2 interface

	output       END_OF_LINE;  // active if 'Enter' key was pressed
	output       BACKSPACE  ;  // active if 'BackSpace' key was pressed

	//-------------------------------------------------------------------------------------------
	// Module behavior
	//-------------------------------------------------------------------------------------------

	assign END_OF_LINE = (SCAN_CODE == `P_SCAN_ENTER    ) ? 1'b1 : 1'b0;
	assign BACKSPACE   = (SCAN_CODE == `P_SCAN_BACKSPACE) ? 1'b1 : 1'b0;

endmodule // SPEC_SYMB_DETECT
