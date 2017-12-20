// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

// TIME SCALE
`timescale 1ns/1ps

`include "./scan_codes.v"
`include "./ascii_codes.v"
`include "./symbol_codes.v"

`define  P_SYMBOLS_NUMBER     7'd80   // defines the buffer size (depth)
`define  P_logSYMBOLS_NUMBER  3'd7    // buffer counter

`define  P_REGISTERS_WIDTH    6'd32   // width of the internal registers

`define  P_OPER_NUM           3'd6    // number of operations performed by the device
                                      //  0_00 - addition
                                      //  0_01 - subtraction
                                      //  0_10 - multiplication
                                      //  0_11 - division
                                      //
                                      //  1_00 - sine
                                      //  1_01 - cosine

`define  P_logOPER_NUM        2'd3    // width of operation code

`define  P_COMMAND_SIZE       2'd3    // the number of characters in the literal command
`define  P_logCOMMAND_SIZE    2'd2    // width of the literal command


// PARAMETERS FOR CORDIC MODULE

// data bus width
`define P_DATA_WIDTH     32

// number of iterations
`define P_ITERATION      6'd32

// counter for iterations
`define P_COUNTER        6

// extension of registers to keep the accuracy
`define P_REG_EXTENSION  3

// determines the position of the decimal point in the data
// (one sign bit + the number of bits to represent the integer part)
`define P_POINT_POS      3

// Values for angles
// 90 degrees for convent
`define P_CONV_ANGLE      `P_DATA_WIDTH'b001_10010010000111111011010101000

// 1.74 rad for condition
`define P_BOUND_ANGLE_POS 31'b01_10111101011100001010001111011
`define P_BOUND_ANGLE_NEG 31'b10_01001100100011110101110000101
