// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module INPUT_BUFFER
	// Module parameter port list
	#(
	parameter P_SYMB_NUM    = `P_SYMBOLS_NUMBER    ,
	parameter P_logSYMB_NUM = `P_logSYMBOLS_NUMBER ,
	parameter P_BUF_WIDTH   = `P_SYMBOL_CODE_WIDTH
	)

	// List of port declarations
	(
	CLK         ,
	RST_N       ,
	NEXT_SYMBOL ,
	NEW_KEY     ,
	SCAN_CODE   ,
	END_OF_LINE ,
	BACKSPACE   ,
	EMPTY       ,
	FULL        ,
	INPUT_READY ,
	SYMBOL
	);


	//----------------------------------------------------------------------------------------------------
	// Module Interface
	//----------------------------------------------------------------------------------------------------

	input                         CLK;           // Clock signal
	input                         RST_N;         // Asynchronous reset

	input      [7:0]              SCAN_CODE;     // scan code from PS/2 interface
	input                         NEW_KEY;       // key is pressed

	input                         END_OF_LINE;   // 'Enter' key was pressed
	input                         BACKSPACE;     // 'BackSpace' key was pressed

	input                         NEXT_SYMBOL;   // Calculation Controller is ready to read new symbol

	output                        EMPTY;         // buffer is empty
	output                        FULL;          // buffer is full

	output reg                    INPUT_READY;   // data entry is finished

	output reg [P_BUF_WIDTH-1:0]  SYMBOL;        // code of next symbol

	//----------------------------------------------------------------------------------------------------
	// Internal nets and variables
	//----------------------------------------------------------------------------------------------------

	reg  [P_BUF_WIDTH-1:0]   symbols_storage [P_SYMB_NUM-1:0];  // storage of symbols

	wire [P_BUF_WIDTH-1:0]  SYMBOL_CODE;                        // code of next symbol

	reg  [P_logSYMB_NUM-1:0] buffer_counter;                    // counter
	reg  [P_logSYMB_NUM-1:0] output_counter;                    // counter


	parameter P_EMPTY_COUNTER = {P_logSYMB_NUM{1'b0}};

	integer iterator; // for clear buffer


	// covergroup declaration
	covergroup cg_input_buffer_states @(NEXT_SYMBOL, NEW_KEY);
	EMPTY : coverpoint EMPTY
	{
	type_option.weight = 0;
	}
	FULL :coverpoint FULL
	{
	type_option.weight = 0;
	}

	EMPTYxFULL: cross EMPTY, FULL
	{
	illegal_bins illegal = binsof (EMPTY) intersect {1} && binsof (FULL) intersect {1};
	}
	endgroup

	// covergroup instantiation
	cg_input_buffer_states input_buffer_states = new();


	//----------------------------------------------------------------------------------------------------
	// Module behavior
	//----------------------------------------------------------------------------------------------------


	always @(posedge CLK or negedge RST_N) begin // pr_behavior

		if (!RST_N) begin // async_rst

				for ( iterator = 0 ; iterator < P_SYMB_NUM ; iterator = iterator + 1 ) begin // clear_buf
						symbols_storage[iterator] <= {P_BUF_WIDTH{1'b0}};
					end // clear_buf

				// clear counter
				buffer_counter  <= P_EMPTY_COUNTER;
				output_counter  <= P_EMPTY_COUNTER;

				SYMBOL          <= {P_BUF_WIDTH{1'b0}};
				INPUT_READY     <= 1'b0;

		end // async_rst

		else if (NEXT_SYMBOL) begin // give_next_symbol

				if (output_counter < buffer_counter) begin // give_symbol
						SYMBOL <= symbols_storage[output_counter];
						output_counter <= output_counter + 1'b1;
				end // give_symbol

				else begin // transfer_ended
						SYMBOL <= `P_SYMBOL_ENTER;
						buffer_counter <= P_EMPTY_COUNTER;
						output_counter <= P_EMPTY_COUNTER;
						INPUT_READY  <= 1'b0;
				end // transfer_ended

		end // give_next_symbol

		else if (NEW_KEY) begin // press_key

				if (END_OF_LINE) begin // data_entry_finish
						INPUT_READY  <= 1'b1;
				end // data_entry_finish

				else if (BACKSPACE && buffer_counter > P_EMPTY_COUNTER) begin // delete_symbol
						symbols_storage[buffer_counter-1] <= {P_BUF_WIDTH{1'b0}};
						buffer_counter <= buffer_counter - 1'b1;
				end // delete_symbol

				else if ( buffer_counter < P_SYMB_NUM && !BACKSPACE) begin // keep_new_symb
						symbols_storage[buffer_counter] <= SYMBOL_CODE;
						buffer_counter <= buffer_counter + 1'b1;
				end // keep_new_symb

		end // press_key

	end // pr_behavior



	//----------------------------------------------------------------------------------------------------

	// EMPTY and FULL flags logic

	assign EMPTY = (buffer_counter ==  P_EMPTY_COUNTER ) ? 1'b1 : 1'b0;
	assign FULL  = (buffer_counter >=  P_SYMB_NUM      ) ? 1'b1 : 1'b0;


	//----------------------------------------------------------------------------------------------------
	// Instances
	//----------------------------------------------------------------------------------------------------

	SCAN2SYMBOL #(
		.P_SYMBOL_WIDTH_S2S (P_BUF_WIDTH)
		)
		SCAN2SYMBOL
		(
		.SCAN_CODE   (SCAN_CODE  ) ,
		.SYMBOL_CODE (SYMBOL_CODE)
	);

endmodule // INPUT_BUFFER
