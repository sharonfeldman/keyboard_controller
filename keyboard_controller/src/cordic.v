// (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
// $Revision: 185465 $

`include "settings.v"

module CORDIC (
	CLK   ,  // clock
	RST_N ,  // asynchronous reset (active low)
	CE    ,  // clock enable
	Z_IN  ,  // angle
	DONE  ,  // result is ready
	COS   ,  // cosine of input angle
	SIN      // sine of input angle
	);

	//--------------------------------------------------------------------------------------------------------------------------------------------------
	// Module Interface
	//--------------------------------------------------------------------------------------------------------------------------------------------------

	// control signals
	input            CLK;
	input            RST_N;
	input            CE;
	output reg       DONE;
	reg              sig_load;       // load new data
	reg        [1:0] sig_need_conv;  // conversion from II and III quadrants


	// input data
	input signed  [`P_DATA_WIDTH - 1 : 0] Z_IN;

	// results
	output reg signed [`P_DATA_WIDTH - 1 : 0] COS;
	output reg signed [`P_DATA_WIDTH - 1 : 0] SIN;


	//--------------------------------------------------------------------------------------------------------------------------------------------------
	// Internal nets and variables
	//--------------------------------------------------------------------------------------------------------------------------------------------------

	// data registers
	reg signed [`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : 0] x_reg;
	reg signed [`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : 0] y_reg;
	reg signed [`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : 0] z_reg;

	// counter for iterations
	reg [ `P_COUNTER - 1 : 0 ] sig_iter_count;


	// arctangent function (tan^-1(2^-i))
	function signed [`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : 0] arctan (input [`P_COUNTER - 1 : 0] iter_num);

	reg [31:0] sig_arctan_temp;

	begin

		case ( iter_num )
			`P_COUNTER'd0    : sig_arctan_temp = 32'b11001001000011111101101010100010;  // 0,78539816339744830961566084581988
			`P_COUNTER'd1    : sig_arctan_temp = 32'b01110110101100011001110000010110;  // 0,46364760900080611621425623146121
			`P_COUNTER'd2    : sig_arctan_temp = 32'b00111110101101101110101111110010;  // 0,24497866312686415417208248121128
			`P_COUNTER'd3    : sig_arctan_temp = 32'b00011111110101011011101010011011;  // 0,12435499454676143503135484916387
			`P_COUNTER'd4    : sig_arctan_temp = 32'b00001111111110101010110111011100;  // 0,062418809995957348473979112985505
			`P_COUNTER'd5    : sig_arctan_temp = 32'b00000111111111110101010101101111;  // 0,031239833430268276253711744892491
			`P_COUNTER'd6    : sig_arctan_temp = 32'b00000011111111111110101010101011;  // 0,01562372862047683080280152125657
			`P_COUNTER'd7    : sig_arctan_temp = 32'b00000001111111111111110101010101;  // 0,0078123410601011112964633918421993
			`P_COUNTER'd8    : sig_arctan_temp = 32'b00000000111111111111111110101011;  // 0,0039062301319669718276286653114244
			`P_COUNTER'd9    : sig_arctan_temp = 32'b00000000011111111111111111110101;  // 0,0019531225164788186851214826250767
			`P_COUNTER'd10   : sig_arctan_temp = 32'b00000000001111111111111111111111;  // 0,00097656218955931943040343019971729
			`P_COUNTER'd11   : sig_arctan_temp = 32'b00000000001000000000000000000000;  // 0,00048828121119489827546923962564485
			`P_COUNTER'd12   : sig_arctan_temp = 32'b00000000000100000000000000000000;  // 0,00024414062014936176401672294325966
			`P_COUNTER'd13   : sig_arctan_temp = 32'b00000000000010000000000000000000;  // 0,00012207031189367020423905864611796
			`P_COUNTER'd14   : sig_arctan_temp = 32'b00000000000001000000000000000000;  // 0,000061035156174208775021662569173829
			`P_COUNTER'd15   : sig_arctan_temp = 32'b00000000000000100000000000000000;  // 0,000030517578115526096861825953438536
			`P_COUNTER'd16   : sig_arctan_temp = 32'b00000000000000010000000000000000;  // 0,000015258789061315762107231935812698
			`P_COUNTER'd17   : sig_arctan_temp = 32'b00000000000000001000000000000000;  // 0,0000076293945311019702633884823401051
			`P_COUNTER'd18   : sig_arctan_temp = 32'b00000000000000000100000000000000;  // 0,000003814697265606496282923075616373
			`P_COUNTER'd19   : sig_arctan_temp = 32'b00000000000000000010000000000000;  // 0,0000019073486328101870353653693059172
			`P_COUNTER'd20   : sig_arctan_temp = 32'b00000000000000000001000000000000;  // 0,00000095367431640596087942067068992311
			`P_COUNTER'd21   : sig_arctan_temp = 32'b00000000000000000000100000000000;  // 0,00000047683715820308885992758382144925
			`P_COUNTER'd22   : sig_arctan_temp = 32'b00000000000000000000010000000000;  // 0,00000023841857910155798249094797721893
			`P_COUNTER'd23   : sig_arctan_temp = 32'b00000000000000000000001000000000;  // 0,00000011920928955078068531136849713792
			`P_COUNTER'd24   : sig_arctan_temp = 32'b00000000000000000000000100000000;  // 0,000000059604644775390554413921062141789
			`P_COUNTER'd25   : sig_arctan_temp = 32'b00000000000000000000000010000000;  // 0,00000002980232238769530367674013276771
			`P_COUNTER'd26   : sig_arctan_temp = 32'b00000000000000000000000001000000;  // 0,000000014901161193847655147092516595963
			`P_COUNTER'd27   : sig_arctan_temp = 32'b00000000000000000000000000100000;  // 0,0000000074505805969238279871365645744954
			`P_COUNTER'd28   : sig_arctan_temp = 32'b00000000000000000000000000010000;  // 0,0000000037252902984619140452670705718119
			`P_COUNTER'd29   : sig_arctan_temp = 32'b00000000000000000000000000001000;  // 0,0000000018626451492309570290958838214765
			`P_COUNTER'd30   : sig_arctan_temp = 32'b00000000000000000000000000000100;  // 0,00000000093132257461547851535573547768456
			`P_COUNTER'd31   : sig_arctan_temp = 32'b00000000000000000000000000000010;  // 0,00000000046566128730773925777884193471057
			default          : sig_arctan_temp = {32{1'bx}};
		endcase

		arctan = {{`P_POINT_POS{1'b0}} , sig_arctan_temp [31 : 32 - ( `P_DATA_WIDTH - `P_POINT_POS + `P_REG_EXTENSION )]};

	end

	endfunction // arctan



	//--------------------------------------------------------------------------------------------------------------------------------------------------
	// Module behavior
	//--------------------------------------------------------------------------------------------------------------------------------------------------

	always @( posedge CLK or negedge RST_N ) begin : behavior_PROC

		if ( !RST_N ) begin : async_reset
				x_reg <= {`P_DATA_WIDTH+`P_REG_EXTENSION{1'b0}};
				y_reg <= {`P_DATA_WIDTH+`P_REG_EXTENSION{1'b0}};
				z_reg <= {`P_DATA_WIDTH+`P_REG_EXTENSION{1'b0}};

				COS <= {`P_DATA_WIDTH{1'b0}};
				SIN <= {`P_DATA_WIDTH{1'b0}};

				sig_iter_count <= {`P_COUNTER{1'b0}};
				sig_load       <= 1'b1;
				DONE           <= 1'b0;
				sig_need_conv  <= 2'b00;

		end	// async_reset

		else if (CE) begin

				if ( sig_load ) begin : registers_load

						x_reg <= {`P_DATA_WIDTH'b000_10011011011100111111011111001, {`P_REG_EXTENSION{1'b0}}};
						y_reg <= {`P_DATA_WIDTH'b000_00000000000000000000000000000, {`P_REG_EXTENSION{1'b0}}};

						if ( ( Z_IN[`P_DATA_WIDTH - 2 : 0] > `P_BOUND_ANGLE_POS) && (Z_IN[`P_DATA_WIDTH - 1 ] == 1'b0) ) begin
								z_reg <= { (Z_IN - `P_CONV_ANGLE) , {`P_REG_EXTENSION{1'b0}}};
								sig_need_conv <= 2'b10;
						end
						else if ( (Z_IN[`P_DATA_WIDTH - 2 : 0] < `P_BOUND_ANGLE_NEG) && (Z_IN[`P_DATA_WIDTH - 1] == 1'b1) ) begin
								z_reg <= { (Z_IN + `P_CONV_ANGLE) , {`P_REG_EXTENSION{1'b0}} };
								sig_need_conv <= 2'b11;
						end
						else begin
								z_reg <= { Z_IN , {`P_REG_EXTENSION{1'b0}} };
								sig_need_conv <= 2'b00;
						end

						sig_load       <= 1'b0;
						DONE         <= 1'b0;
						sig_iter_count <= {`P_COUNTER{1'b0}};

				end	// registers_load

				else if ( sig_iter_count <= (`P_ITERATION - 1'b1) ) begin : calc

						if ( z_reg[`P_DATA_WIDTH + `P_REG_EXTENSION - 1] == 1'b0 ) begin	// sigma = 1

								x_reg <= x_reg - ( y_reg >>> sig_iter_count );
								y_reg <= y_reg + ( x_reg >>> sig_iter_count );
								z_reg <= z_reg - arctan(sig_iter_count);

						end

						else begin	// sigma = -1

								x_reg <= x_reg + ( y_reg >>> sig_iter_count );
								y_reg <= y_reg - ( x_reg >>> sig_iter_count );
								z_reg <= z_reg + arctan(sig_iter_count);

						end

						sig_iter_count <= sig_iter_count + 1'b1;  // next iteration

				end // calc

				else begin : read_result

						case (sig_need_conv)
							2'b00   :   begin
									COS <= x_reg[`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : `P_REG_EXTENSION];
									SIN <= y_reg[`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : `P_REG_EXTENSION];
								end
							2'b10   :   begin
									COS <= ( ~ y_reg[`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : `P_REG_EXTENSION] ) + 1'b1;
									SIN <=     x_reg[`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : `P_REG_EXTENSION];
								end
							2'b11   :   begin
									COS <=     y_reg[`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : `P_REG_EXTENSION];
									SIN <= ( ~ x_reg[`P_DATA_WIDTH + `P_REG_EXTENSION - 1 : `P_REG_EXTENSION] ) + 1'b1;
								end
							default :   begin
									COS <= { `P_DATA_WIDTH{1'bx} };
									SIN <= { `P_DATA_WIDTH{1'bx} };
								end
						endcase

						DONE <= 1'b1;

				end // read result

		end

		else begin

				sig_load <= 1'b1;
				DONE     <= 1'b0;

		end

	end // behavior_PROC


endmodule // cordic
