// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module KEYBOARD_CONTROLLER
	#(
	parameter P_DATA_WIDTH   = `P_REGISTERS_WIDTH   ,
	parameter P_SYMBOL_WIDTH = `P_SYMBOL_CODE_WIDTH ,
	parameter P_ALU_COMMAND  = `P_COMMAND_SIZE
	)
	// List of port declarations
	(
	RST_N     ,
	DATA      ,
	CLK_50MHZ ,
	PS2CLK    ,
	ASCII_OUT ,
	COLOR     ,
	COMMAND
	);


	//-------------------------------------------------------------------------------------------
	// Module Interface
	//-------------------------------------------------------------------------------------------

	input        RST_N;        // Asynchronous reset (active low)
	input        DATA;         // Data from keyboard
	input        CLK_50MHZ;    // Clock signal 50MHz
	input        PS2CLK;

	output [7:0] ASCII_OUT;    // ASCII code of printed symbols
	output [7:0] COLOR;
	output [1:0] COMMAND;      // Command code for VGA
	//    "00" - display symbol
	//    "01" - delete symbol
	//    "10" - new line
	//    "11" - null


	//-------------------------------------------------------------------------------------------
	// Internal nets and variables
	//-------------------------------------------------------------------------------------------

	wire [7:0]                 SCAN_CODE;
	wire [7:0]                 ASCII_CODE;
	wire [7:0]                 ASCII_RES;
	wire [P_SYMBOL_WIDTH-1:0]  SYMBOL;

	wire                       press_release;
	wire                       key_ready;
	wire                       NEW_KEY;

	wire                       END_OF_LINE;
	wire                       BACKSPACE;
	wire                       EMPTY;
	wire                       FULL;
	wire                       INPUT_READY;
	wire                       NEXT_SYMBOL;
	wire                       READY_RES;

	wire [P_DATA_WIDTH-1:0]    X_FOR_ALU,
		Y_FOR_ALU,
		Z_FOR_ALU,
		X_FROM_ALU,
	Y_FROM_ALU;

	wire [P_ALU_COMMAND-1:0]   ALU_CONTROL;
	wire                       ALU_START,
	ALU_READY;



	//-------------------------------------------------------------------------------------------
	// Module behavior
	//-------------------------------------------------------------------------------------------

	assign NEW_KEY = ~press_release & key_ready;


	//-------------------------------------------------------------------------------------------
	// Instances
	//-------------------------------------------------------------------------------------------


	PS_2_CONTROLLER
		PS_2_CONTROLLER (
		.data          (DATA),
		.clk_50mhz     (CLK_50MHZ),
		.reset         (RST_N),
		.PS2clk        (PS2CLK),
		.scan_code     (SCAN_CODE),
		.key_released  (press_release),
		.ready         (key_ready)
	);


	SCAN2ASCII
		SCAN2ASCII (
		.SCAN_CODE     (SCAN_CODE),
		.ASCII_CODE    (ASCII_CODE)
	);


	SPEC_SYMB_DETECT
		SPEC_SYMB_DETECT (
		.SCAN_CODE     (SCAN_CODE),
		.END_OF_LINE   (END_OF_LINE),
		.BACKSPACE     (BACKSPACE)
	);


	INPUT_BUFFER
		INPUT_BUFFER (
		.CLK           (CLK_50MHZ),
		.RST_N         (RST_N),
		.NEXT_SYMBOL   (NEXT_SYMBOL),
		.NEW_KEY       (NEW_KEY),
		.SCAN_CODE     (SCAN_CODE),
		.END_OF_LINE   (END_OF_LINE),
		.BACKSPACE     (BACKSPACE),
		.EMPTY         (EMPTY),
		.FULL          (FULL),
		.INPUT_READY   (INPUT_READY),
		.SYMBOL        (SYMBOL)
	);

	CALCULATION_CONTROLLER
		CALCULATION_CONTROLLER (
		.CLK           (CLK_50MHZ),
		.RST_N         (RST_N),
		.INPUT_READY   (INPUT_READY),
		.SYMBOL        (SYMBOL),
		.X_FROM_ALU    (X_FROM_ALU),
		.Y_FROM_ALU    (Y_FROM_ALU),
		.ALU_READY     (ALU_READY),
		.NEXT_SYMBOL   (NEXT_SYMBOL),
		.X_FOR_ALU     (X_FOR_ALU),
		.Y_FOR_ALU     (Y_FOR_ALU),
		.Z_FOR_ALU     (Z_FOR_ALU),
		.ALU_CONTROL   (ALU_CONTROL),
		.ALU_START     (ALU_START),
		.READY_RES     (READY_RES),
		.ASCII_RES     (ASCII_RES)
	);

	ALU
		ALU (
		.CLK           (CLK_50MHZ),
		.RST_N         (RST_N),
		.X_FOR_ALU     (X_FOR_ALU),
		.Y_FOR_ALU     (Y_FOR_ALU),
		.Z_FOR_ALU     (Z_FOR_ALU),
		.ALU_CONTROL   (ALU_CONTROL),
		.ALU_START     (ALU_START),
		.X_FROM_ALU    (X_FROM_ALU),
		.Y_FROM_ALU    (Y_FROM_ALU),
		.ALU_READY     (ALU_READY)
	);


	VGA_WRITE
		VGA_WRITE (
		.CLK           (CLK_50MHZ),
		.RST_N         (RST_N),
		.NEW_KEY       (NEW_KEY),
		.END_OF_LINE   (END_OF_LINE),
		.BACKSPACE     (BACKSPACE),
		.EMPTY         (EMPTY),
		.FULL          (FULL),
		.READY_RES     (READY_RES),
		.ASCII_CODE    (ASCII_CODE),
		.ASCII_RES     (ASCII_RES),
		.ASCII_OUT     (ASCII_OUT),
		.COLOR         (COLOR),
		.COMMAND       (COMMAND)
	);


endmodule // KEYBOARD_CONTROLLER
