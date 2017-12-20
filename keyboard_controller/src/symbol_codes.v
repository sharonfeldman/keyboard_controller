// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`define  P_SYMBOL_CODE_WIDTH  3'd7    // width of symbol code
                                      // 000_xxxx - number
                                      //
                                      // 001_xxxx - Other symbols
                                      // 001_0000 - point
                                      // 001_0001 - comma
                                      // 001_0010 - left bracket
                                      // 001_0011 - right bracket
                                      // 001_0100 - space
                                      // 001_0101 - equal
                                      // 001_0110 - quotes
                                      // 001_0111 - enter
                                      //
                                      // 01_xxxxx - letter
                                      //
                                      // 10_00xxx - operators
                                      //
                                      // 10_000_00 - adding
                                      // 10_000_01 - subtraction
                                      // 10_000_10 - multiplication
                                      // 10_000_11 - division
                                      //
                                      // 10_00100 - sine
                                      // 10_00101 - cosine

// NUMBERS

`define  P_SYMBOL_ONE        7'b000_0001
`define  P_SYMBOL_TWO        7'b000_0010
`define  P_SYMBOL_THREE      7'b000_0011
`define  P_SYMBOL_FOUR       7'b000_0100
`define  P_SYMBOL_FIVE       7'b000_0101
`define  P_SYMBOL_SIX        7'b000_0110
`define  P_SYMBOL_SEVEN      7'b000_0111
`define  P_SYMBOL_EIGHT      7'b000_1000
`define  P_SYMBOL_NINE       7'b000_1001
`define  P_SYMBOL_ZERO       7'b000_0000

// LETTERS
`define  P_SYMBOL_A          7'b01_00000
`define  P_SYMBOL_B          7'b01_00001
`define  P_SYMBOL_C          7'b01_00010
`define  P_SYMBOL_D          7'b01_00011
`define  P_SYMBOL_E          7'b01_00100
`define  P_SYMBOL_F          7'b01_00101
`define  P_SYMBOL_G          7'b01_00110
`define  P_SYMBOL_H          7'b01_00111
`define  P_SYMBOL_I          7'b01_01000
`define  P_SYMBOL_J          7'b01_01001
`define  P_SYMBOL_K          7'b01_01010
`define  P_SYMBOL_M          7'b01_01011
`define  P_SYMBOL_L          7'b01_01100
`define  P_SYMBOL_N          7'b01_01101
`define  P_SYMBOL_O          7'b01_01110
`define  P_SYMBOL_Q          7'b01_01111
`define  P_SYMBOL_P          7'b01_10000
`define  P_SYMBOL_R          7'b01_10001
`define  P_SYMBOL_S          7'b01_10010
`define  P_SYMBOL_T          7'b01_10011
`define  P_SYMBOL_U          7'b01_10100
`define  P_SYMBOL_V          7'b01_10101
`define  P_SYMBOL_W          7'b01_10110
`define  P_SYMBOL_X          7'b01_10111
`define  P_SYMBOL_Y          7'b01_11000
`define  P_SYMBOL_Z          7'b01_11001

// OPERATIONS
`define  P_SYMBOL_PLUS       7'b10_000_00
`define  P_SYMBOL_MINUS      7'b10_000_01
`define  P_SYMBOL_MULTIPLE   7'b10_000_10
`define  P_SYMBOL_SLASH      7'b10_000_11

// OTHER SYMBOLS
`define  P_SYMBOL_POINT      7'b001_0000
`define  P_SYMBOL_COMMA      7'b001_0001
`define  P_SYMBOL_LBRACKET   7'b001_0010
`define  P_SYMBOL_RBRACKET   7'b001_0011

`define  P_SYMBOL_SPACE      7'b001_0100
`define  P_SYMBOL_EQUAL      7'b001_0101
`define  P_SYMBOL_QUOTES     7'b001_0110
`define  P_SYMBOL_ENTER      7'b001_0111
