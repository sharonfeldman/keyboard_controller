// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module ALU
	// Module parameter port list
	#(
	parameter P_DATA_WIDTH = `P_REGISTERS_WIDTH ,
	parameter P_COMM_SIZE  = `P_COMMAND_SIZE
	)

	// List of port declarations
	(
	CLK         ,
	RST_N       ,
	X_FOR_ALU   ,
	Y_FOR_ALU   ,
	Z_FOR_ALU   ,
	ALU_CONTROL ,
	ALU_START   ,
	X_FROM_ALU  ,
	Y_FROM_ALU  ,
	ALU_READY
	);


	//--------------------------------------------------------------------------------------------------------------------
	// Module Interface
	//--------------------------------------------------------------------------------------------------------------------

	input                            CLK;
	input                            RST_N;
	input       [P_DATA_WIDTH-1:0]   X_FOR_ALU;
	input       [P_DATA_WIDTH-1:0]   Y_FOR_ALU;
	input       [P_DATA_WIDTH-1:0]   Z_FOR_ALU;
	input       [P_COMM_SIZE-1:0]    ALU_CONTROL;
	input                            ALU_START;

	output reg  [P_DATA_WIDTH-1:0]   X_FROM_ALU;
	output reg  [P_DATA_WIDTH-1:0]   Y_FROM_ALU;
	output reg                       ALU_READY;


	//--------------------------------------------------------------------------------------------------------------------
	// Internal nets and variables
	//--------------------------------------------------------------------------------------------------------------------

	reg                        add_sub_sel;      // Select signal for ADDER_SUBTRACTOR
	                                             //    '1' - Addition
	                                             //    '0' - Subtraction

	reg                        add_sub_ce;       // Clock enable for ADDER_SUBTRACTOR module
	reg                        mul_ce;           // Clock enable for MULTIPLIER module
	reg                        div_ce;           // Clock enable for DIVIDER module
	reg                        cordic_ce;        // Clock enable for CORDIC module

	wire                       c_out;            // carry out of adder
	wire [P_DATA_WIDTH-1:0]    sum;              // sum
	wire [P_DATA_WIDTH*2-1:0]  prod;             // product
	wire [P_DATA_WIDTH-1:0]    quotient;         // quotient
	wire [P_DATA_WIDTH-1:0]    fractional;       // residue of division
	wire [P_DATA_WIDTH-1:0]    cos;              // cosine
	wire [P_DATA_WIDTH-1:0]    sin;              // sine

	wire                       done;             // ready signal from CORDIC

	reg  [5:0]                 clock_counter;    // clock counter to produce a result

	wire                       RST;              // reset for arith modules (active high)


	// covergroup declaration
	covergroup cg_alu @(posedge ALU_START);
	coverpoint ALU_CONTROL
	{
	bins ADD = {3'b000};
	bins SUB = {3'b001};
	bins MUL = {3'b010};
	bins DIV = {3'b011};
	bins SIN = {3'b100};
	bins COS = {3'b101};
	illegal_bins illegal_command = default;
	}
	endgroup

	// covergroup instantiation
	cg_alu alu = new();



	//--------------------------------------------------------------------------------------------------------------------
	// Module behavior
	//--------------------------------------------------------------------------------------------------------------------


	always @(posedge CLK or negedge RST_N) begin // operation_select
		if (!RST_N) begin // async_reset
				{add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'b00000;
		end // async_reset
		else if (ALU_START) begin
				case (ALU_CONTROL)
					3'b000  : {add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'b11000;  // addition
					3'b001  : {add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'b01000;  // subtraction
					3'b010  : {add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'b00100;  // multiplication
					3'b011  : {add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'b00010;  // division
					3'b100,
					3'b101  : {add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'b00001;  // sine or cosine
					default : {add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'bxxxxx;  // sine or cosine
				endcase
		end
		else begin
				{add_sub_sel, add_sub_ce, mul_ce, div_ce, cordic_ce} <= 5'b00000;
		end
	end // operation_select


	always @(posedge CLK or negedge RST_N) begin // result_select
		if (!RST_N) begin //: async_reset
				X_FROM_ALU <= {32{1'b0}};
				Y_FROM_ALU <= {32{1'b0}};
		end // async_reset
		else begin
				case (ALU_CONTROL)
					3'b000  : {Y_FROM_ALU, X_FROM_ALU} <= {{31{1'b0}}, c_out, sum};
					3'b001  : {Y_FROM_ALU, X_FROM_ALU} <= {{32{1'b0}}, sum};
					3'b010  : {Y_FROM_ALU, X_FROM_ALU} <= prod;
					3'b011  : {Y_FROM_ALU, X_FROM_ALU} <= {fractional, quotient};
					3'b100  : {Y_FROM_ALU, X_FROM_ALU} <= {sin, {32{1'b0}}};
					3'b101  : {Y_FROM_ALU, X_FROM_ALU} <= {{32{1'b0}}, cos};
					default : {Y_FROM_ALU, X_FROM_ALU} <= {64{1'bx}};
				endcase
		end
	end // result_select


	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin // async_reset
				clock_counter <= 6'b000000;
				ALU_READY <= 1'b0;
		end // async_reset
		else if (ALU_START) begin // wait_result
				if (ALU_CONTROL == 3'b011) begin // disivion
						if (clock_counter >= 6'd40) begin // result_ready
								ALU_READY <= 1'b1;
								clock_counter <= 6'b000000;
						end // result_ready
						else begin // result_not_ready_yet
								clock_counter <= clock_counter + 1'b1;
						end // result_not_ready_yet
				end // disivion
				else if (ALU_CONTROL == 3'b000 || ALU_CONTROL == 3'b001 || ALU_CONTROL == 3'b010) begin // other_operations
						if (clock_counter >= 6'd10) begin // result_ready
								ALU_READY <= 1'b1;
								clock_counter <= 6'b000000;
						end // result_ready
						else begin // result_not_ready_yet
								clock_counter <= clock_counter + 1'b1;
						end // result_not_ready_yet
				end // other_operations
				else begin // sinus or cosinus
						if (done) begin
								ALU_READY <= 1'b1;
						end
				end // sine or cosine
		end // wait_result
		else begin
				ALU_READY <= 1'b0;
		end
	end


	assign RST = ~ RST_N;


	//--------------------------------------------------------------------------------------------------------------------
	// Instances
	//--------------------------------------------------------------------------------------------------------------------

	ADDER_SUBTRACTOR
		ADDER_SUBTRACTOR (
		.A          (X_FOR_ALU),   // Bus [31 : 0]
		.B          (Y_FOR_ALU),   // Bus [31 : 0]
		.CLK        (CLK),
		.ADD        (add_sub_sel),
		.CE         (add_sub_ce),
		.SCLR       (RST),
		.C_OUT      (c_out),
		.S          (sum)          // Bus [31 : 0]
	);

	MULTIPLIER
		MULTIPLIER 	(
		.CLK        (CLK),
		.A          (X_FOR_ALU),   // Bus [31 : 0]
		.B          (Y_FOR_ALU),   // Bus [31 : 0]
		.CE         (mul_ce),
		.SCLR       (RST),
		.P          (prod)         // Bus [63 : 0]
	);

	DIVIDER
		DIVIDER (
		.CLK        (CLK),
		.CE			(div_ce),
		.SCLR       (RST),
		.DEVIDENT	(X_FOR_ALU),   // Bus [31 : 0]
		.DIVISOR	(Y_FOR_ALU),   // Bus [31 : 0]
		.QUOTIENT	(quotient),    // Bus [31 : 0]
		.FRACTIONAL	(fractional)   // Bus [31 : 0]
	);

	CORDIC
		CORDIC (
		.CLK        (CLK),
		.RST_N      (RST_N),
		.CE         (cordic_ce),
		.Z_IN       (Z_FOR_ALU),
		.DONE       (done),
		.COS        (cos),
		.SIN        (sin)
	);

endmodule // ALU
