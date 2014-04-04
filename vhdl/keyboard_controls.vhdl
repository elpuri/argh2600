-- Copyright (c) 2014, Juha Turunen
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met: 
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer. 
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution. 
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity keyboard_controls is Port (
	reset : in std_logic;
	clk : in std_logic;

	ps2_clk : in std_logic;
	ps2_data : in std_logic;
	
	p1_left : out std_logic;
	p1_right : out std_logic;
	p1_up : out std_logic;
	p1_down : out std_logic;
	p1_fire : out std_logic;
	
	p2_left : out std_logic;
	p2_right : out std_logic;
	p2_up : out std_logic;
	p2_down : out std_logic;
	p2_fire : out std_logic;
	
	game_select : out std_logic;
	game_reset : out std_logic
);
end keyboard_controls;

architecture Behavioral of keyboard_controls is

signal p1_left_reg, p1_left_reg_next, p1_right_reg, p1_right_reg_next, 
		 p1_up_reg, p1_up_reg_next, p1_down_reg, p1_down_reg_next, p1_fire_reg, p1_fire_reg_next,
		 p2_left_reg, p2_left_reg_next, p2_right_reg, p2_right_reg_next, 
		 p2_up_reg, p2_up_reg_next, p2_down_reg, p2_down_reg_next, p2_fire_reg, p2_fire_reg_next,
		 game_reset_reg, game_reset_reg_next,
		 game_select_reg, game_select_reg_next : std_logic;
		 
signal keyboard_tick : std_logic;
signal keyboard_data : std_logic_vector(7 downto 0);

signal extended_code, extended_code_next, break_code, break_code_next : std_logic;

begin
	process(clk)
	begin
		if (clk'event and clk = '1') then
			p1_left_reg <= p1_left_reg_next;
			p1_right_reg <= p1_right_reg_next;
			p1_up_reg <= p1_up_reg_next;
			p1_down_reg <= p1_down_reg_next;
			p1_fire_reg <= p1_fire_reg_next;

			p2_left_reg <= p2_left_reg_next;
			p2_right_reg <= p2_right_reg_next;
			p2_up_reg <= p2_up_reg_next;
			p2_down_reg <= p2_down_reg_next;
			p2_fire_reg <= p2_fire_reg_next;

			game_reset_reg <= game_reset_reg_next;
			game_select_reg <= game_select_reg_next;
			
			extended_code <= extended_code_next;
			break_code <= break_code_next;
		end if;
	end process;

	game_select <= game_select_reg;
	game_reset <= game_reset_reg;
	p1_left <= p1_left_reg;
	p1_right <= p1_right_reg;
	p1_up <= p1_up_reg;
	p1_down <= p1_down_reg;
	p1_fire <= p1_fire_reg;
	p2_left <= p2_left_reg;
	p2_right <= p2_right_reg;
	p2_up <= p2_up_reg;
	p2_down <= p2_down_reg;
	p2_fire <= p2_fire_reg;
	
	process (keyboard_tick, keyboard_data)
	begin
		break_code_next <= break_code;
		extended_code_next <= extended_code;
		p1_left_reg_next <= p1_left_reg;
		p1_right_reg_next <= p1_right_reg;
		p1_up_reg_next <= p1_up_reg;
		p1_down_reg_next <= p1_down_reg;
		p1_fire_reg_next <= p1_fire_reg;
		p2_left_reg_next <= p2_left_reg;
		p2_right_reg_next <= p2_right_reg;
		p2_up_reg_next <= p2_up_reg;
		p2_down_reg_next <= p2_down_reg;
		p2_fire_reg_next <= p2_fire_reg;
		game_reset_reg_next <= game_reset_reg;
		game_select_reg_next <= game_select_reg;
		
		if (keyboard_tick = '1') then
			if (keyboard_data = x"f0") then
				break_code_next <= '1';
			elsif (keyboard_data = x"e0") then
				extended_code_next <= '1';
			else		-- real key code
				break_code_next <= '0';
				extended_code_next <= '0';
				case keyboard_data is 
					-- player 1
					when x"6b" =>
						if (extended_code = '1') then
							p1_left_reg_next <= not break_code;
						end if;
						
					when x"74" =>
						if (extended_code = '1') then
							p1_right_reg_next <= not break_code;
						end if;

					when x"75" =>
						if (extended_code = '1') then
							p1_up_reg_next <= not break_code;
						end if;

					when x"72" =>
						if (extended_code = '1') then
							p1_down_reg_next <= not break_code;
						end if;
						
					when x"29" =>
						if (extended_code = '0') then
							p1_fire_reg_next <= not break_code;
						end if;
						
						
					-- player 2
					when x"1c" =>		-- A
						if (extended_code = '0') then
							p2_left_reg_next <= not break_code;
						end if;
						
					when x"23" =>		-- D
						if (extended_code = '0') then
							p2_right_reg_next <= not break_code;
						end if;

					when x"1d" =>		-- W
						if (extended_code = '0') then
							p2_up_reg_next <= not break_code;
						end if;

					when x"1b" =>		-- S	
						if (extended_code = '0') then
							p2_down_reg_next <= not break_code;
						end if;
						
					when x"34" | x"11" =>		-- G or left alt
						if (extended_code = '0') then
							p2_fire_reg_next <= not break_code;
						end if;	
						
					-- Global controls
					when x"76" =>		-- ESC
						if (extended_code = '0') then
							game_reset_reg_next <= not break_code;
						end if;	

					when x"05" =>		-- F1
						if (extended_code = '0') then
							game_select_reg_next <= not break_code;
						end if;	
					
					when others =>
				end case;
			end if;
		end if;
	end process;
	
	ps2_rx : entity work.ps2rx port map (
		clk => clk,
		ps2clk => ps2_clk,
		ps2data => ps2_data,
		data => keyboard_data,
		data_tick => keyboard_tick
	);
	
end Behavioral;