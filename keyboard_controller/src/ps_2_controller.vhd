-- (c) Aldec, Inc.
-- All rights reserved.
--
-- Last modified: $Date: 2011-10-18 14:13:06 +0200 (Tue, 18 Oct 2011) $
-- $Revision: 185465 $

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PS_2_CONTROLLER is
	port (
		clk_50mhz    : in  STD_LOGIC;
		reset        : in  STD_LOGIC;
		data         : in  STD_LOGIC;
		PS2clk       : in  STD_LOGIC;
		scan_code    : out STD_LOGIC_VECTOR(7 downto 0);
		key_released : out STD_LOGIC;
		ready        : out STD_LOGIC
	);
end PS_2_CONTROLLER;

architecture RTL of PS_2_CONTROLLER is

	type t_state is ( IDLE, DATA_TRANSMIT, PARITY, STOP );

	constant release_key       : STD_LOGIC_VECTOR(7 downto 0) := "11110000";

	signal state               : t_state;
	signal next_state          : t_state;
	signal bit_counter         : STD_LOGIC_VECTOR(2 downto 0) := ( others => '0' );
	signal received_data       : STD_LOGIC_VECTOR(7 downto 0) := ( others => '0' );
	signal send_data           : STD_LOGIC := '0';
	signal done                : STD_LOGIC := '0';

	signal need_count          : STD_LOGIC := '0';

	signal last_clock          : STD_LOGIC := '0';
	signal curr_clock          : STD_LOGIC := '0';
	signal test_val            : STD_LOGIC := '0';
	signal ps2_edge            : STD_LOGIC := '0';
	signal curr_val_count      : STD_LOGIC_VECTOR(2 downto 0);
	signal set_release_data    : STD_LOGIC := '0';
	signal clear_release_data  : STD_LOGIC := '0';
	signal release_data        : STD_LOGIC;

begin

	-- detect falling edge
	pr_detect_falling_edge: process (clk_50mhz) is
	begin
		if ( clk_50mhz'event and clk_50mhz = '1' ) then
			if ( ( last_clock = '1' ) and ( curr_clock = '0' ) ) then
				ps2_edge <= '1';
			else
				ps2_edge <= '0';
			end if;
		end if;
	end process pr_detect_falling_edge;

	-- get value of clock
	pr_get_val_clock: process (clk_50mhz) is
	begin
		if ( clk_50mhz'event and clk_50mhz = '1' ) then
			test_val <= PS2clk;
		end if;
	end process pr_get_val_clock;

	-- get last clock
	pr_get_last_clock:   process (clk_50mhz) is
	begin
		if ( clk_50mhz'event and clk_50mhz = '1' ) then
			if ( test_val = PS2clk ) then
				if ( curr_val_count = B"111" ) then
					last_clock <= curr_clock;
					curr_clock <= test_val;
				else
					curr_val_count <= curr_val_count + '1';
				end if;
			else
				curr_val_count <= ( others => '0' );
			end if;
		end if;
	end process pr_get_last_clock;

	-- main FSM process
	pr_main_FSM:   process (ps2_edge, reset) is
	begin
		if ( reset = '0' ) then
			state <= IDLE;
		elsif ( ps2_edge'event and ps2_edge = '1' ) then
			state <= next_state;
		end if;
	end process pr_main_FSM;

	-- states
	pr_states:  process (state, data, bit_counter)
	begin
		switch_states: case ( state ) is
			when IDLE            => if ( data = '0' ) then
			                            next_state <= DATA_TRANSMIT;
			                        else
			                            next_state <= IDLE;
			                        end if;
			when DATA_TRANSMIT   => if ( bit_counter = "111" ) then
			                            next_state <= PARITY;
			                        else
			                            next_state <= DATA_TRANSMIT;
			                        end if;
			when PARITY          => next_state <= STOP;
			when STOP            => next_state <= IDLE;
			when others          => next_state <= IDLE;
		end case switch_states;
	end process pr_states;

	-- catch received data
	pr_catch_received_data: process (ps2_edge) is
	begin
		if ( ps2_edge'event and ps2_edge = '1' ) then
			if ( state = DATA_TRANSMIT ) then
				received_data( TO_INTEGER( UNSIGNED(bit_counter) ) ) <= data;
			end if;
		end if;
	end process pr_catch_received_data;

	-- FSM outputs
	pr_FSM_outputs:   process (state, received_data) is
	begin
		--need_count <= '0';
		--send_data  <= '0';
		--set_release_data   <= '0';
		--clear_release_data <= '0';

		FSM_outputs :  case (state) is
			when IDLE           => if ( received_data = release_key ) then
			                          need_count <= '0';
			                          send_data  <= '0';
			                          set_release_data   <= '1';
			                          clear_release_data <= '0';
			                        --set_release_data <= '1';
			                      elsif ( received_data /= "11100000" ) then
			                          need_count <= '0';
			                          send_data  <= '1';
			                          set_release_data   <= '0';
			                          clear_release_data <= '1';
			                        --clear_release_data <= '1';
			                        --send_data <= '1';
			                      else
			                          need_count <= '0';
			                          send_data  <= '0';
			                          set_release_data   <= '0';
			                          clear_release_data <= '0';
			                        --clear_release <= '0';
			                        --send_data <= '0';
			                      end if;
			when DATA_TRANSMIT => need_count <= '1';
			                      send_data <= '0';
			                      set_release_data <= '0';
			                      clear_release_data <= '0';
			when PARITY        => null;
			when STOP          => if ( received_data = release_key ) then
			                          need_count <= '0';
			                          send_data  <= '0';
			                          set_release_data   <= '1';
			                          clear_release_data <= '0';
			                        --set_release_data <= '1';
			                      elsif ( received_data /= "11100000" ) then
			                          need_count <= '0';
			                          send_data  <= '1';
			                          set_release_data   <= '0';
			                          clear_release_data <= '1';
			                        --clear_release_data <= '1';
			                        --send_data <= '1';
			                      else
			                          need_count <= '0';
			                          send_data  <= '0';
			                          set_release_data   <= '0';
			                          clear_release_data <= '0';
			                        --clear_release <= '0';
			                        --send_data <= '0';
			                      end if;
			when others        => null;
		end case FSM_outputs;

	end process pr_FSM_outputs;

	-- set release data
	pr_set_release_data: process (ps2_edge) is
	begin
		if ( ps2_edge'event and ps2_edge = '1' ) then
			if ( set_release_data = '1' ) then
				release_data <= '1';
			elsif ( clear_release_data = '1' ) then
				release_data <= '0';
			end if;
		end if;
	end process pr_set_release_data;

	-- count bits
	pr_count_bits: process (ps2_edge) is
	begin
		if ( ps2_edge'event and ps2_edge = '1' ) then
			if ( need_count = '0' ) then
				bit_counter <= ( others => '0' );
			else
				bit_counter <= bit_counter + '1';
			end if;
		end if;
	end process pr_count_bits;

	-- send outputs
	pr_send_output:   process (clk_50mhz) is
	begin
		if ( clk_50mhz'event and clk_50mhz = '1' ) then
			if ( send_data = '1' ) then
				if ( done = '0' ) then
					key_released <= release_data;
					scan_code    <= received_data;
					ready <= '1';
					done  <= '1';
				else
					ready        <= '0';
					scan_code    <= ( others => '0' );
					key_released <= '0';
				end if;
			else
				ready <= '0';
				done  <= '0';
				scan_code    <= ( others => '0' );
				key_released <= '0';
			end if;
		end if;
	end process pr_send_output;

end RTL;
