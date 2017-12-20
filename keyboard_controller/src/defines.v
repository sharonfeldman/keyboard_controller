// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`ifndef DEFINES
`define DEFINES

`timescale 1ns/1ps

// GENERAL defines
`define CODE_WIDTH     8	// width of ASCII code
`define COMM_WIDTH     2	// width of command bus (add, delete, enter)
`define VGA_ADDR_WIDTH 18	// width of address bus (for page of 1024*1024)
`define VGA_DATA_WIDTH 16	// width of data bus (2 pixels, 2*8 = 16 bits)
`define ADDR_END   `VGA_ADDR_WIDTH'd245567  // last  output vga address to be written
`define ADDR_START `VGA_ADDR_WIDTH'd0       // first output vga address to be written
`define VGA_LEFT       9'd0    // left   most position of vga memory
`define VGA_RIGHT      9'd319  // right  most position of vga memory
`define VGA_TOP        9'd0    // top    most position of vga memory
`define VGA_BOT        9'd479  // bottom most position of vga memory

// operations
`define ADD         `COMM_WIDTH'b00         // add new symbol
`define DEL         `COMM_WIDTH'b01         // delete last symbol
`define ENT         `COMM_WIDTH'b10         // go to new line
`define NOP         `COMM_WIDTH'b11         // no operation

// RAM defines
`define RAM_ADDR_WIDTH 12	// width of address bus of the RAM
`define RAM_ADDR_LOW   7	// width of low  part of address bus
`define RAM_ADDR_HIGH  5	// width of high part of address bus
`define LEFT_POS    `RAM_ADDR_LOW'd0        // left   most position
`define RIGHT_POS   `RAM_ADDR_LOW'd79       // right  most position
`define TOP_POS     `RAM_ADDR_HIGH'd0       // top    most position
`define BOT_POS     `RAM_ADDR_HIGH'd29      // bottom most position
`define LOW_X      {`RAM_ADDR_LOW{1'bx}}    // x for low  address part
`define HIGH_X     {`RAM_ADDR_HIGH{1'bx}}   // x for high address part

// ROM defines
`define ROM_ADDR_WIDTH 14	// width of address bus of the ROM
`define ROM_ADDR_LOW   2	// width of low  part of ROM address bus
`define ROM_ADDR_HIGH  4    // width of high part of ROM address
`define ROM_DATA_WIDTH 2	// width of output ROM data bus

// COLOR defines
`define COLOR_1 8'b00011100	// background color (R3G3B2) [GREEN]
`define COLOR_0 8'b00000000 // font color (R3G3B2) [BLACK]

`endif
