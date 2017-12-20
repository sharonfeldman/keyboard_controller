// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $


`include "settings.v"

module CALCULATION_CONTROLLER
	// Module parameter port list
	#(
	parameter P_SYMB_WIDTH = `P_SYMBOL_CODE_WIDTH ,
	parameter P_DATA_WIDTH = `P_REGISTERS_WIDTH   ,
	parameter P_OPER_WIDTH = `P_logOPER_NUM       ,
	parameter P_COMM_SIZE  = `P_COMMAND_SIZE      ,
	parameter P_COMM_WIDTH = `P_logCOMMAND_SIZE
	)

	// List of port declarations
	(
	CLK         ,
	RST_N       ,
	INPUT_READY ,
	SYMBOL      ,
	X_FROM_ALU  ,
	Y_FROM_ALU  ,
	ALU_READY   ,
	NEXT_SYMBOL ,
	X_FOR_ALU   ,
	Y_FOR_ALU   ,
	Z_FOR_ALU   ,
	ALU_CONTROL ,
	ALU_START   ,
	READY_RES   ,
	ASCII_RES
	);


	//--------------------------------------------------------------------------------------------------------------------------------------------------
	// Module Interface
	//--------------------------------------------------------------------------------------------------------------------------------------------------

	input                            CLK;           // Clock signal
	input                            RST_N;         // Asynchronous reset (active low)
	input                            INPUT_READY;   // Data input finished
	input       [P_SYMB_WIDTH-1:0]   SYMBOL;        // Code of symbol

	input       [P_DATA_WIDTH-1:0]   X_FROM_ALU;    // Data from ALU
	input       [P_DATA_WIDTH-1:0]   Y_FROM_ALU;    // Data from ALU
	input                            ALU_READY;     // ALU finished calculation


	output reg                       NEXT_SYMBOL;   // Conversion finished, need next symbol

	output reg  [P_DATA_WIDTH-1:0]   X_FOR_ALU;     // Data for ALU
	output reg  [P_DATA_WIDTH-1:0]   Y_FOR_ALU;     // Data for ALU
	output reg  [P_DATA_WIDTH-1:0]   Z_FOR_ALU;     // Data for ALU

	output reg  [P_OPER_WIDTH-1:0]   ALU_CONTROL;   // Operation select
	                                                //    "000" - addition
	                                                //    "001" - subtraction
	                                                //    "010" - multiplication
	                                                //    "011" - division
	                                                //    "100" - sine
	                                                //    "101" - cosine

	output reg                       ALU_START;     // Start calculation

	output reg                       READY_RES;     // Result is converted
	output      [7:0]                ASCII_RES;     // ASCII code of result


	//--------------------------------------------------------------------------------------------------------------------------------------------------
	// Internal nets and variables
	//--------------------------------------------------------------------------------------------------------------------------------------------------

	// Data registers
	reg [P_DATA_WIDTH-1:0]   Xreg;
	reg [P_DATA_WIDTH-1:0]   Yreg;
	reg [P_OPER_WIDTH-1:0]   OPERreg;
	reg [P_DATA_WIDTH*2-1:0] RESreg;

	// Additional signals
	reg x_int;      // integer part of operand X is calculated now
	reg x_fract;    // fractional part of operand X is calculated now
	reg y_int;      // integer part of operand Y is calculated now
	reg y_fract;    // fractional part of operand Y is calculated now
	reg letter;     // letter command is analyzed now

	reg neg_oper;   // operand for trigomonectrical function is negative
	reg neg_result; // result from CORDIC is negative

	reg error;      // error flag

	integer i, j, k;  // for clearing memory

	// Temp registers
	reg [P_DATA_WIDTH-1:0] Areg;
	reg [P_DATA_WIDTH-1:0] Breg;

	reg [P_SYMB_WIDTH-1:0] symbols_buffer [23:0];            // storage for symbols of result
	reg [P_SYMB_WIDTH-1:0] symbol_temp;                      // symbol of result
	reg [P_SYMB_WIDTH-1:0] command_buffer [P_COMM_SIZE-1:0]; // buffer for letter command
	reg [P_SYMB_WIDTH-1:0] error_buffer [28:0];              // error message storage

	// Counters

	reg [4:0]               counter_fract_acc;   // counter for define accuracy of fractional part
	reg [4:0]               counter_int;         // calculate number of symbols in integer part of result
	reg [3:0]               counter_fract;       // calculate number of symbols in fractional part of result
	reg [4:0]               bits_counter;        // calculate bits of fractional part of result
	reg [P_COMM_WIDTH-1:0]  counter_command;     // counter of symbols in letter command
	reg [7:0]               counter_digits;      // counter of the number of digits in operand
	reg [4:0]               counter_error;       // counter for error storage

	// States of FSM
	typedef enum //bit [5:0]
	{
	S0,
	S1,
	S2,
	S3,
	S4,
	S5,
	S6,
	S7,
	S8,
	S9,
	S10,
	S11,
	S12,
	S13,
	S14,
	S15,
	S16,
	S17,
	S18,
	S19,
	S20,
	S21,
	S22,
	S23,
	S24,
	S25,
	S26,
	S27,
	S28,
	S29,
	S30,
	S31,
	S32,
	S33,
	S34,
	S35,
	S36,
	S37,
	S38,
	S39,
	S40,
	S41,
	S42,
	S43,
	S44,
	S45,
	S46,
	S47,
	S48,
	S49,
	S50,
	S61,
	S62,
	S63
	} t_state;

	t_state current_state;     // current state of FSM
	t_state next_state;        // next state of FSM


	// covergroup declaration
	covergroup cg_calc_fsm @(current_state);
	coverpoint current_state;
	endgroup

	// covergroup instantiation
	cg_calc_fsm calc_fsm = new();


	//--------------------------------------------------------------------------------------------------------------------------------------------------
	// Module behavior
	//--------------------------------------------------------------------------------------------------------------------------------------------------

	always @(posedge CLK or negedge RST_N) begin // switching process
		if (!RST_N) begin                        // asynchronous reset
				current_state <= S0;
		end
		else begin                               // switching to the next state
				current_state <= next_state;
		end
	end


	always @(*) begin // pr_fsm_states

		case (current_state)

			S0  : if (INPUT_READY)
				next_state = S1;
				else
			next_state = S0;

			S1  : next_state = S2;

			S2  : if (SYMBOL[P_SYMB_WIDTH-1:P_SYMB_WIDTH-3] == 3'b000) begin           // digit is received
						if ({x_int, x_fract, y_int, y_fract, letter} == 5'b00000)      // it is a first symbol
						next_state = S3;
						else if (x_int || x_fract || y_int || y_fract)                 // digit is expected
						next_state = S4;
						else                                                           // digit isn't expected - ERROR
						next_state = S63;
				end
				else if (SYMBOL == `P_SYMBOL_POINT || SYMBOL == `P_SYMBOL_COMMA) begin // point or comma is received
						if (counter_digits != 8'd0) begin                              // before point digits present
								if (x_int)                                             // it is point in the first operand
								next_state = S8;
								else if (y_int)                                        // it is point in the second operand
								next_state = S9;
								else                                                   // point is on the unexpected place
								next_state = S63;
						end
						else                                                           // digit isn't expected - there isn't digits before it
						next_state = S63;
				end
				else if (SYMBOL[P_SYMB_WIDTH-1:P_SYMB_WIDTH-5] == 5'b10000) begin      // arith operation is received
						if (!letter) begin                                             // arith operation is expected
								if (x_int)                                             // save integer part of first operand
								next_state = S11;
								else if (x_fract)                                      // convert and save fractional part of first operand
								next_state = S12;
								else                                                   // arith operation isn't expected
								next_state = S63;
						end
						else if (letter && x_int && counter_digits == 8'd0 && SYMBOL[1:0] == 2'b01 && !neg_oper)
						next_state = S50;
						else                                                           // arith operation isn't expected
						next_state = S63;
				end
				else if (SYMBOL[P_SYMB_WIDTH-1:P_SYMB_WIDTH-2] == 2'b01) begin         // letter is received
						if ({x_int, x_fract, y_int, y_fract, letter} == 5'b00000)      // it is the first symbol
						next_state = S24;
						else if ({x_int, x_fract, y_int, y_fract, letter} == 5'b00001) // letter is expected
						next_state = S25;
						else                                                           // letter isn't expected
						next_state = S63;
				end
				else if (SYMBOL == `P_SYMBOL_LBRACKET) begin                           // "(" is received
						if (letter)
						next_state = S26;                                              // before "(" command present
						else
						next_state = S63;                                              // "(" isn't expected
				end
				else if (SYMBOL == `P_SYMBOL_RBRACKET) begin                           // ")" is received
						if (letter) begin                                              // ")" is expected
								if (x_int && counter_digits != 8'd0)                   // save integer part
								next_state = S11;
								else if (x_fract)                                      // convert and save fractional part
								next_state = S13;
								else                                                   // operand is null
								next_state = S63;
						end
						else                                                           // ")" isn't expected
						next_state = S63;
				end
				else if (SYMBOL == `P_SYMBOL_ENTER) begin                              // enter is received
						if (letter)
						next_state = S28;
						else if (y_int && counter_digits != 5'd0)
						next_state = S23;
						else if (y_fract)
						next_state = S13;
						else                                                           // the entered expression is not correct
						next_state = S63;
				end
				else if (SYMBOL == `P_SYMBOL_SPACE) begin
						next_state = S1;
				end
				else begin
						next_state = S63;
			end

			S3  : next_state = S4;

			S4  : if (ALU_READY)
				next_state = S5;
				else
			next_state = S4;

			S5  : next_state = S6;

			S6  : if (ALU_READY)
				next_state = S7;
				else
			next_state = S6;

			S7  : next_state = S1;

			S8  : next_state = S10;

			S9  : next_state = S10;

			S10 : next_state = S1;

			S11 : next_state = S10;

			S12 : next_state = S13;

			S13 : if (counter_digits > 3'd0 && counter_digits < 3'd5) // fractional part isn't null
				next_state = S14;
				else if (counter_digits == 3'd5)                      // fractional part is ready
				next_state = S16;
				else                                                  // fractional part is null or it has too match digits
			next_state = S63;

			S14 : if (ALU_READY)
				next_state = S15;
				else
			next_state = S14;

			S15 : next_state = S13;

			S16 : if (ALU_READY)
				next_state = S17;
				else
			next_state = S16;

			S17 : if (Areg < 32'd100000)
				next_state = S18;
				else
			next_state = S19;

			S18 : if (counter_fract_acc > 5'b00000)
				next_state = S16;
				else if (x_fract)
				next_state = S21;
				else
			next_state = S22;

			S19 : if (ALU_READY)
				next_state = S20;
				else
			next_state = S19;

			S20 : if (counter_fract_acc > 5'b00000)
				next_state = S16;
				else if (x_fract)
				next_state = S21;
				else
			next_state = S22;

			S21 : next_state = S10;

			S22 : next_state = S27;

			S23 : next_state = S27;

			S24 : next_state = S25;

			S25 : next_state = S1;

			S26 : if (error)
				next_state = S63;
				else
			next_state = S1;

			S27 : if (ALU_READY)
				next_state = S29;
				else
			next_state = S27;

			S28 : if (ALU_READY)
				next_state = S29;
				else
			next_state = S28;

			S29 : next_state = S30;

			S30 : if ( RESreg[63:32] != 32'd0)
				next_state = S31;
				else
			next_state = S34;

			S31 : next_state = S32;

			S32 : if (ALU_READY)
				next_state = S33;
				else
			next_state = S32;

			S33 : if (X_FROM_ALU != 32'd0)
				next_state = S32;
				else
			next_state = S35;

			S34 : next_state = S35;

			S35 : if (RESreg[31:0] != 32'd0)
				next_state = S36;
				else
			next_state = S45;

			S36 : next_state = S37;

			S37 : if (ALU_READY)
				next_state = S38;
				else
			next_state = S37;

			S38 : if (RESreg[31-bits_counter])
				next_state = S39;
				else
			next_state = S41;

			S39 : if (ALU_READY)
				next_state = S40;
				else
			next_state = S39;

			S40 : if (bits_counter < 5'd16)
				next_state = S37;
				else
			next_state = S43;

			S41 : next_state = S42;

			S42 : if (bits_counter < 5'd16)
				next_state = S37;
				else
			next_state = S43;

			S43 : if (ALU_READY)
				next_state = S44;
				else
			next_state = S43;

			S44 : if (counter_fract <= 4'd9)
				next_state = S43;
				else
			next_state = S45;

			S45 : next_state = S46;

			S46 : if (counter_int >= 4'd11)
				next_state = S45;
				else if (counter_fract == 4'd10)
				next_state = S47;
				else
			next_state = S49;

			S47 : next_state = S48;

			S48 : if (counter_fract >= 4'd5)
				next_state = S47;
				else
			next_state = S49;

			S49 : next_state = S0;

			S50 : next_state = S1;

			S63 : next_state = S62;

			S62 : next_state = S61;

			S61 : if (counter_error < 5'd29)
				next_state = S63;
				else
			next_state = S0;

			default : next_state = S0;

		endcase

	end // pr_fsm_states


	always @(negedge CLK) begin // pr_fsm_outputs

		case (current_state)

			// Initial / Reset
			S0  : begin
					NEXT_SYMBOL       <= 1'b0;
					ALU_START         <= 1'b0;
					X_FOR_ALU         <= {32{1'b0}};
					Y_FOR_ALU         <= {32{1'b0}};
					Z_FOR_ALU         <= {32{1'b0}};
					ALU_CONTROL       <= {P_COMM_SIZE{1'b0}};
					READY_RES         <= 1'b0;
					Xreg              <= {32{1'b0}};
					Yreg              <= {32{1'b0}};
					OPERreg           <= {P_COMM_SIZE{1'b0}};
					RESreg            <= {64{1'b0}};
					Areg              <= {32{1'b0}};
					Breg              <= {32{1'b0}};
					x_int             <= 1'b0;
					x_fract           <= 1'b0;
					y_int             <= 1'b0;
					y_fract           <= 1'b0;
					letter            <= 1'b0;
					neg_oper          <= 1'b0;
					neg_result        <= 1'b0;
					error             <= 1'b0;
					counter_fract_acc <= 5'b00000;
					bits_counter      <= 5'b00000;
					counter_int       <= 5'd11;
					counter_fract     <= 4'd5;
					counter_command   <= {P_COMM_WIDTH{1'b0}};
					counter_digits    <= 8'd0;
					counter_error     <= 5'b00000;
					symbol_temp       <= {P_SYMB_WIDTH{1'b0}};

					for (i = 0 ; i < 24 ; i = i + 1)
					symbols_buffer[i] <= {P_SYMB_WIDTH{1'b0}};

					for (j = 0 ; j < P_COMM_SIZE ; j = j + 1)
					command_buffer[j] <= {P_SYMB_WIDTH{1'b0}};

					for (k = 0 ; k < 29 ; k = k + 1)
					error_buffer[k] <= {P_SYMB_WIDTH{1'b0}};

				end

			// Request a next symbol
			S1  : begin
					NEXT_SYMBOL <= 1'b1;
				end

			// Next symbol is obtained
			S2  : begin
					NEXT_SYMBOL <= 1'b0;
				end

			// First digit is obtained (integer part of first operand)
			S3  : begin
					x_int <= 1'b1;
				end

			// Conversion of the obtained number (Areg = Areg * 10 + SYMBOL)
			S4  : begin
					X_FOR_ALU   <= Areg;
					Y_FOR_ALU   <= 32'd10;
					ALU_CONTROL <= 3'b010;
					ALU_START   <= 1'b1;
				end

			S5  : begin
					Areg           <= X_FROM_ALU;
					ALU_START      <= 1'b0;
					counter_digits <= counter_digits + 1'b1;
				end

			S6  : begin
					X_FOR_ALU   <= Areg;
					Y_FOR_ALU   <= {{25{1'b0}},SYMBOL};
					ALU_CONTROL <= 3'b000;
					ALU_START   <= 1'b1;
				end

			S7  : begin
					Areg      <= X_FROM_ALU;
					ALU_START <= 1'b0;
				end

			// Integer part of the first operand is obtained
			// The obtained symbol is a point in the first operand
			S8  : begin
					x_int          <= 1'b0;
					x_fract        <= 1'b1;
					Xreg[31:16]    <= Areg[15:0];
					counter_digits <= 8'd0;
				end

			// Integer part of the second operand is obtained
			// The obtained symbol is a point in the point operand
			S9  : begin
					y_int          <= 1'b0;
					y_fract        <= 1'b1;
					Yreg[31:16]    <= Areg[15:0];
					counter_digits <= 8'd0;
				end

			// Clearing temp registers
			S10 : begin
					Areg <= {32{1'b0}};
					Breg <= {32{1'b0}};
				end

			// Arithmetic operation is obtained
			// First operand doesn't have fractional part
			S11 : begin
					x_int          <= 1'b0;
					y_int          <= 1'b1;
					Xreg[31:16]    <= Areg[15:0];
					OPERreg        <= SYMBOL[2:0];
					counter_digits <= 8'd0;
				end

			// Save arithmetic operation
			S12 : begin
					OPERreg <= SYMBOL[2:0];
				end

			// Installation of the counter to calculate the fractional part with a defined accuracy
			S13 : begin
					counter_fract_acc <= 5'd16;
				end

			// Complement fractional number of zeros to five decimal places
			S14 : begin
					X_FOR_ALU   <= Areg;
					Y_FOR_ALU   <= 32'd10;
					ALU_CONTROL <= 3'b010;
					ALU_START   <= 1'b1;
				end

			S15 : begin
					Areg           <= X_FROM_ALU;
					ALU_START      <= 1'b0;
					counter_digits <= counter_digits + 1'b1;
				end

			// Bitwise calculation of fractional part of number
			S16 : begin
					X_FOR_ALU      <= Areg;
					Y_FOR_ALU      <= 32'd2;
					ALU_CONTROL    <= 3'b010;
					ALU_START      <= 1'b1;
					counter_digits <= 8'd0;
				end

			S17 : begin
					Areg              <= X_FROM_ALU;
					ALU_START         <= 1'b0;
					counter_fract_acc <= counter_fract_acc - 1'b1;
				end

			S18 : begin
					Breg[counter_fract_acc] <= 1'b0;
				end

			S19 : begin
					Breg[counter_fract_acc] <= 1'b1;
					X_FOR_ALU   <= Areg;
					Y_FOR_ALU   <= 32'd100000;
					ALU_CONTROL <= 3'b001;
					ALU_START   <= 1'b1;
				end

			S20 : begin
					Areg      <= X_FROM_ALU;
					ALU_START <= 1'b0;
				end

			// Saving the fractional part of the first operand
			S21 : begin
					Xreg[15:0] <= Breg[15:0];
					x_fract    <= 1'b0;
					y_int      <= 1'b1;
				end

			// Saving the fractional part of the second operand
			S22 : begin
					Yreg[15:0] <= Breg[15:0];
					y_fract    <= 1'b0;
				end

			// Saving the integer part of the second operand
			S23 : begin
					y_int       <= 1'b0;
					Yreg[31:16] <= Areg[15:0];
				end

			// First symbol is an operation
			S24 : begin
					letter <= 1'b1;
				end

			// Saving symbol of the command
			S25 : begin
					command_buffer[counter_command] <= SYMBOL;
					counter_command <= counter_command + 1'b1;
				end

			// Defining and saving command
			S26 : begin
					x_int <= 1'b1;
					case ({command_buffer[0], command_buffer[1], command_buffer[2]})
						{`P_SYMBOL_S, `P_SYMBOL_I, `P_SYMBOL_N} : OPERreg <= 3'b100;
						{`P_SYMBOL_C, `P_SYMBOL_O, `P_SYMBOL_S} : OPERreg <= 3'b101;
						default                                 : error   <= 1'b1;
					endcase
				end

			// Arithmetic operation
			S27 : begin
					X_FOR_ALU   <= Xreg;
					Y_FOR_ALU   <= Yreg;
					ALU_CONTROL <= OPERreg;
					ALU_START   <= 1'b1;
				end

			// Trigonometrical command
			S28 : begin
					if (neg_oper)
					Z_FOR_ALU <= {(~ Xreg[18:0]) + 1'b1 , {13{1'b0}}};
					else
					Z_FOR_ALU <= { Xreg[18:0] , {13{1'b0}}};
					ALU_CONTROL <= OPERreg;
					ALU_START   <= 1'b1;
				end

			// Saving result
			S29 : begin
					ALU_START     <= 1'b0;
					case (OPERreg)
						3'b000 : RESreg <= {Y_FROM_ALU[15:0], X_FROM_ALU, {16{1'b0}}};
						3'b001 : RESreg <= {Y_FROM_ALU[15:0], X_FROM_ALU, {16{1'b0}}};
						3'b010 : RESreg <= {Y_FROM_ALU, X_FROM_ALU};
						3'b011 : RESreg <= {X_FROM_ALU, {32{1'b0}}};
						3'b100 : begin
								if (Y_FROM_ALU[P_DATA_WIDTH-1]) begin
										RESreg <= {{29{1'b0}}, (~(Y_FROM_ALU - 1'b1)), {3{1'b0}}};
										neg_result <= 1'b1;
								end
								else
								RESreg <= {{29{1'b0}}, Y_FROM_ALU, {3{1'b0}}};
							end
						3'b101 : begin
								if (X_FROM_ALU[P_DATA_WIDTH-1]) begin
										RESreg <= {{29{1'b0}}, (~(X_FROM_ALU - 1'b1)), {3{1'b0}}};
										neg_result <= 1'b1;
								end
								else
								RESreg <= {{29{1'b0}}, X_FROM_ALU, {3{1'b0}}};
							end
						default : RESreg <= {64{1'b0}};
					endcase
				end

			// Delay for one clock
			S30 : begin
				end

			// Conversion integer part of the result
			S31 : begin
					Areg <= RESreg[63:32];
				end

			S32 : begin
					X_FOR_ALU   <= Areg;
					Y_FOR_ALU   <= 32'd10;
					ALU_CONTROL <= 3'b011;
					ALU_START   <= 1'b1;
				end

			S33 : begin
					Areg        <= X_FROM_ALU;
					ALU_START   <= 1'b0;
					counter_int <= counter_int + 1'b1;
					symbols_buffer[counter_int] <= Y_FROM_ALU[P_SYMB_WIDTH-1:0];
				end

			S34 : begin
					symbols_buffer[counter_int] <= {P_SYMB_WIDTH{1'b0}};
					counter_int <= counter_int + 1'b1;
				end

			S35 : begin
					Areg <= {32{1'b0}};
					if (neg_result) begin
							symbols_buffer[counter_int]   <= `P_SYMBOL_MINUS; // minus
							symbols_buffer[counter_int+1] <= `P_SYMBOL_SPACE; // space
							symbols_buffer[counter_int+2] <= `P_SYMBOL_EQUAL; // =
							symbols_buffer[counter_int+3] <= `P_SYMBOL_SPACE; // space
							counter_int <= counter_int + 2'b11;
					end
					else begin
							symbols_buffer[counter_int]   <= `P_SYMBOL_SPACE; // space
							symbols_buffer[counter_int+1] <= `P_SYMBOL_EQUAL; // =
							symbols_buffer[counter_int+2] <= `P_SYMBOL_SPACE; // space
							counter_int <= counter_int + 2'b10;
					end
				end

			// Conversion fractional part of the result
			S36 : begin
					Breg <= 32'd100000;
					symbols_buffer[10] <= `P_SYMBOL_POINT;
				end

			S37 : begin
					X_FOR_ALU   <= Breg;
					Y_FOR_ALU   <= 32'd2;
					ALU_CONTROL <= 3'b011;
					ALU_START   <= 1'b1;
				end

			S38 : begin
					Breg      <= X_FROM_ALU;
					ALU_START <= 1'b0;
				end

			S39 : begin
					X_FOR_ALU   <= Areg;
					Y_FOR_ALU   <= Breg;
					ALU_CONTROL <= 3'b000;
					ALU_START   <= 1'b1;
				end

			S40 : begin
					Areg         <= X_FROM_ALU;
					ALU_START    <= 1'b0;
					bits_counter <= bits_counter + 1'b1;
				end

			S41 : begin
					bits_counter <= bits_counter + 1'b1;
				end

			S42 : begin
				end

			S43 : begin
					X_FOR_ALU   <= Areg;
					Y_FOR_ALU   <= 32'd10;
					ALU_CONTROL <= 3'b011;
					ALU_START   <= 1'b1;
				end

			S44 : begin
					Areg           <= X_FROM_ALU;
					ALU_START      <= 1'b0;
					counter_fract  <= counter_fract + 1'b1;
					symbols_buffer[counter_fract] <=  Y_FROM_ALU[P_SYMB_WIDTH-1:0];
				end

			// Transfer symbols of the result at VGA write module
			S45 : begin
					READY_RES   <= 1'b1;
					symbol_temp <= symbols_buffer[counter_int];
					counter_int <= counter_int - 1'b1;
				end

			S46 : begin
					READY_RES <= 1'b0;
				end

			S47 : begin
					READY_RES     <= 1'b1;
					symbol_temp   <= symbols_buffer[counter_fract];
					counter_fract <= counter_fract - 1'b1;
				end

			S48 : begin
					READY_RES <= 1'b0;
				end

			S49 : begin
					READY_RES   <= 1'b1;
					symbol_temp <= `P_SYMBOL_ENTER;
				end

			S50 : begin
					neg_oper <= 1'b1;
				end

			// Print ERROR
			S63 : begin
					if (error) begin
							error_buffer[0]  <= `P_SYMBOL_SPACE;
							error_buffer[1]  <= `P_SYMBOL_E;
							error_buffer[2]  <= `P_SYMBOL_R;
							error_buffer[3]  <= `P_SYMBOL_R;
							error_buffer[4]  <= `P_SYMBOL_O;
							error_buffer[5]  <= `P_SYMBOL_R;
							error_buffer[6]  <= `P_SYMBOL_SLASH;
							error_buffer[7]  <= `P_SYMBOL_SPACE;
							error_buffer[8]  <= `P_SYMBOL_U;
							error_buffer[9]  <= `P_SYMBOL_N;
							error_buffer[10] <= `P_SYMBOL_K;
							error_buffer[11] <= `P_SYMBOL_N;
							error_buffer[12] <= `P_SYMBOL_O;
							error_buffer[13] <= `P_SYMBOL_W;
							error_buffer[14] <= `P_SYMBOL_N;
							error_buffer[15] <= `P_SYMBOL_SPACE;
							error_buffer[16] <= `P_SYMBOL_C;
							error_buffer[17] <= `P_SYMBOL_O;
							error_buffer[18] <= `P_SYMBOL_M;
							error_buffer[19] <= `P_SYMBOL_M;
							error_buffer[20] <= `P_SYMBOL_A;
							error_buffer[21] <= `P_SYMBOL_N;
							error_buffer[22] <= `P_SYMBOL_D;
							error_buffer[23] <= `P_SYMBOL_ENTER;
					end
					else if (SYMBOL != `P_SYMBOL_ENTER) begin
							error_buffer[0]  <= `P_SYMBOL_SPACE;
							error_buffer[1]  <= `P_SYMBOL_E;
							error_buffer[2]  <= `P_SYMBOL_R;
							error_buffer[3]  <= `P_SYMBOL_R;
							error_buffer[4]  <= `P_SYMBOL_O;
							error_buffer[5]  <= `P_SYMBOL_R;
							error_buffer[6]  <= `P_SYMBOL_SLASH;
							error_buffer[7]  <= `P_SYMBOL_SPACE;
							error_buffer[8]  <= `P_SYMBOL_U;
							error_buffer[9]  <= `P_SYMBOL_N;
							error_buffer[10] <= `P_SYMBOL_E;
							error_buffer[11] <= `P_SYMBOL_X;
							error_buffer[12] <= `P_SYMBOL_P;
							error_buffer[13] <= `P_SYMBOL_E;
							error_buffer[14] <= `P_SYMBOL_C;
							error_buffer[15] <= `P_SYMBOL_T;
							error_buffer[16] <= `P_SYMBOL_E;
							error_buffer[17] <= `P_SYMBOL_D;
							error_buffer[18] <= `P_SYMBOL_SPACE;
							error_buffer[19] <= `P_SYMBOL_T;
							error_buffer[20] <= `P_SYMBOL_O;
							error_buffer[21] <= `P_SYMBOL_K;
							error_buffer[22] <= `P_SYMBOL_E;
							error_buffer[23] <= `P_SYMBOL_N;
							error_buffer[24] <= `P_SYMBOL_SPACE;
							error_buffer[25] <= `P_SYMBOL_QUOTES;
							error_buffer[26] <= SYMBOL;
							error_buffer[27] <= `P_SYMBOL_QUOTES;
							error_buffer[28] <= `P_SYMBOL_ENTER;
					end
					else begin
							error_buffer[0]  <= `P_SYMBOL_SPACE;
							error_buffer[1]  <= `P_SYMBOL_E;
							error_buffer[2]  <= `P_SYMBOL_R;
							error_buffer[3]  <= `P_SYMBOL_R;
							error_buffer[4]  <= `P_SYMBOL_O;
							error_buffer[5]  <= `P_SYMBOL_R;
							error_buffer[6]  <= `P_SYMBOL_SLASH;
							error_buffer[7]  <= `P_SYMBOL_SPACE;
							error_buffer[8]  <= `P_SYMBOL_E;
							error_buffer[9]  <= `P_SYMBOL_X;
							error_buffer[10] <= `P_SYMBOL_P;
							error_buffer[11] <= `P_SYMBOL_R;
							error_buffer[12] <= `P_SYMBOL_E;
							error_buffer[13] <= `P_SYMBOL_S;
							error_buffer[14] <= `P_SYMBOL_S;
							error_buffer[15] <= `P_SYMBOL_I;
							error_buffer[16] <= `P_SYMBOL_O;
							error_buffer[17] <= `P_SYMBOL_N;
							error_buffer[18] <= `P_SYMBOL_SPACE;
							error_buffer[19] <= `P_SYMBOL_N;
							error_buffer[20] <= `P_SYMBOL_O;
							error_buffer[21] <= `P_SYMBOL_T;
							error_buffer[22] <= `P_SYMBOL_SPACE;
							error_buffer[23] <= `P_SYMBOL_F;
							error_buffer[24] <= `P_SYMBOL_U;
							error_buffer[25] <= `P_SYMBOL_L;
							error_buffer[26] <= `P_SYMBOL_L;
							error_buffer[27] <= `P_SYMBOL_ENTER;
					end
				end

			S62 : begin
					READY_RES     <= 1'b1;
					symbol_temp   <= error_buffer[counter_error];
					counter_error <= counter_error + 1'b1;
				end

			S61 : begin
					READY_RES <= 1'b0;
				end

			default : begin
				end

		endcase

	end // pr_fsm_outputs


	//--------------------------------------------------------------------------------------------------------------------------------------------------
	// Instances
	//--------------------------------------------------------------------------------------------------------------------------------------------------

	// Module converting symbol code to ASCII code
	SYMBOL2ASCII SYMBOL2ASCII (
		.SYMBOL_CODE (symbol_temp),
		.ASCII_CODE  (ASCII_RES)
	);


endmodule // CALCULATION_CONTROLLER
