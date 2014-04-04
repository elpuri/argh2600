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

entity ball is Port (
	clk : in std_logic;
	clk_ena : in std_logic;
	reset : in std_logic;
	motck_ena : in std_logic;
	hm_trigger : in std_logic;
	hm_value : in std_logic_vector(3 downto 0);
	reset_strobe : in std_logic;
	pixel : out std_logic;
	size : in std_logic_vector(1 downto 0);
	enable : in std_logic
);
end ball;

architecture Behavioral of ball is

signal counter, counter_next : std_logic_vector(5 downto 0);
signal clk_div4, clk_div4_next : std_logic_vector(1 downto 0);
signal output, output_next : std_logic;
signal hmove_counter, hmove_counter_next, hm_temp_reg, hm_temp_reg_next : std_logic_vector(3 downto 0);
signal reset_strobe_edge : std_logic;
signal reset_strobe_delay : std_logic_vector(4 downto 0);
signal clk_stuffing, clk_stuffing_next : std_logic;

begin
	process(reset, clk, clk_ena)
	begin
		if (reset = '1') then
			counter <= (others => '0');
			hmove_counter <= (others => '0');
			clk_div4 <= (others => '0');
		elsif (clk'event and clk = '1' and clk_ena = '1') then
			counter <= counter_next;
			clk_div4 <= clk_div4_next;
			output <= output_next;
			hm_temp_reg <= hm_temp_reg_next;
			hmove_counter <= hmove_counter_next;
			reset_strobe_delay <= reset_strobe_delay(3 downto 0) & reset_strobe;
			clk_stuffing <= clk_stuffing_next;
		end if;
	end process;
	
	reset_strobe_edge <= '1' when reset_strobe_delay(4) = '0' and reset_strobe_delay(3) = '1' else '0';
	
	process(counter)
	begin
		clk_div4_next <= clk_div4;
		counter_next <= counter;
		output_next <= output;
		
		if (motck_ena = '1' or clk_stuffing = '1') then
			clk_div4_next <= clk_div4 + 1;
			if (clk_div4 = "11") then
				counter_next <= counter + 1;
				if (counter = conv_std_logic_vector(39, 6)) then
					counter_next <= (others => '0');
					output_next <= '1';
				end if;
			end if;
		end if;
		
		if (reset_strobe_edge = '1') then
			counter_next <= (others => '0');
			clk_div4_next <= "00";
		end if;
	
		if (size = "00" and counter = "000000" and clk_div4 = "00") then
			output_next <= '0';
		elsif (size = "01" and counter = "000000" and clk_div4 = "01") then
			output_next <= '0';
		elsif (size = "10" and counter = "000000" and clk_div4 = "11") then
			output_next <= '0';
		elsif (counter = "000001" and clk_div4 = "11") then
			output_next <= '0';		
		end if;
	end process;
	
	
	process (hmove_counter, hm_trigger, hm_value)
	begin
		-- hm_temp_reg is a hack to avoid triggering the logic when hm_value is changed
		hm_temp_reg_next <= hm_temp_reg;
		
		if (hm_trigger = '1' and clk_stuffing = '0') then
			hm_temp_reg_next <= hm_value;
			hmove_counter_next <= "1000";
			clk_stuffing_next <= '0';
		elsif (hmove_counter = hm_temp_reg) then
			hmove_counter_next <= hmove_counter;
			clk_stuffing_next <= '0';
		else
			hmove_counter_next <= hmove_counter + 1;
			clk_stuffing_next <= '1';
		end if;
	end process;
	
	pixel <= output and enable;
	
end Behavioral;