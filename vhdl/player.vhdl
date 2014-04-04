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

entity player is Port (
	clk : in std_logic;
	clk_ena : in std_logic;
	reset : in std_logic;
	motck_ena : in std_logic;
	hm_trigger : in std_logic;
	hm_value : in std_logic_vector(3 downto 0);
	reset_strobe : in std_logic;
	pixel : out std_logic;
	data : in std_logic_vector(7 downto 0);
	nusiz : in std_logic_vector(5 downto 0);
	reflect : in std_logic;
	missile_reset : out std_logic
);
end player;

architecture Behavioral of player is

signal data_delay : std_logic_vector(7 downto 0);
signal counter, counter_next : std_logic_vector(5 downto 0);
signal pixel_counter, pixel_counter_next : std_logic_vector(3 downto 0);
signal clk_div4, clk_div4_next : std_logic_vector(1 downto 0);
signal clk_div4_ena : std_logic;
signal clk_stuffing, clk_stuffing_next : std_logic;
signal hmove_counter, hmove_counter_next : std_logic_vector(3 downto 0); 
signal plr_size : std_logic_vector(2 downto 0);
signal scan_out, reflected_scan_out : std_logic;
signal reset_strobe_edge  : std_logic;
signal reset_strobe_delay, reset_strobe_delay_next : std_logic_vector(3 downto 0);
signal start, start_edge : std_logic;
signal start_delay, start_delay_next : std_logic_vector(3 downto 0);
signal hm_temp_reg, hm_temp_reg_next : std_logic_vector(3 downto 0);
signal skip_main_copy, skip_main_copy_next : std_logic;
signal main_copy, main_copy_next : std_logic;

begin

	reset_strobe_delay_next <= reset_strobe_delay(2 downto 0) & reset_strobe; 
	
	process (reset, clk, clk_ena)
	begin
		if (reset = '1') then
			counter <= (others => '0');
			pixel_counter <= (others => '0');
			hmove_counter <= (others => '0');
			clk_div4 <= (others => '0');

		elsif (clk'event and clk = '1') then
			if (clk_ena = '1') then		-- regs updated every pixel clock (2 "lo-res" pixels)
				clk_div4 <= clk_div4_next;
				start_delay <= start_delay_next;
				clk_stuffing <= clk_stuffing_next;
				reset_strobe_delay <= reset_strobe_delay_next;
				counter <= counter_next;
				hmove_counter <= hmove_counter_next;
				pixel_counter <= pixel_counter_next;
				hm_temp_reg <= hm_temp_reg_next;
				skip_main_copy <= skip_main_copy_next;
				data_delay <= data;
				main_copy <= main_copy_next;
			end if;
		end if;
	end process;
	
	clk_div4_ena <= '1' when clk_div4 = "11" else '0';
	
	process (counter, reset_strobe)
	begin
		counter_next <= counter;
		start_delay_next <= start_delay;
		clk_div4_next <= clk_div4;
		skip_main_copy_next <= skip_main_copy;
		
		if (reset_strobe_edge = '1') then
			counter_next <= conv_std_logic_vector(0, 6);--conv_std_logic_vector(39, 6);
			clk_div4_next <= "00";
			skip_main_copy_next <= '1';
		else
			if (clk_ena = '1' and (motck_ena = '1' or clk_stuffing = '1')) then
				clk_div4_next <= clk_div4 + 1;
				start_delay_next <= start_delay(2 downto 0) & start;
				
				if (clk_div4_ena = '1') then
					counter_next <= counter + 1;	
					if (counter = conv_std_logic_vector(39, 6)) then
						skip_main_copy_next <= '0';
						counter_next <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;
	
	plr_size <= nusiz(2 downto 0);
	
	start_edge <= '1' when start_delay(0) = '1' and start_delay(1) = '0' else '0';
	reset_strobe_edge <= '1' when reset_strobe_delay(1) = '1' and reset_strobe_delay(2) = '0' else '0';
	
	process (pixel_counter, counter) 
	begin
		pixel_counter_next <= pixel_counter;
		main_copy_next <= main_copy;
			
		start <= '0';
		
		if (start_edge = '1') then
			pixel_counter_next <= "0000";
		end if;
		
		if (motck_ena = '1' or clk_stuffing = '1') then
			if ((counter = "000000" and skip_main_copy = '0') or
				 (counter = "000100" and (plr_size = "001" or plr_size = "011")) or
				 (counter = "001000" and (plr_size = "011" or plr_size = "010" or plr_size = "110")) or
				 (counter = "010000" and (plr_size = "100" or plr_size = "110"))) then
				start <= '1';
				if (counter = "000000") then
					main_copy_next <= '1';
				else	
					main_copy_next <= '0';
				end if;
			end if;		

			if (pixel_counter < 9) then
				if (plr_size = "111" and clk_div4 = "11") then
					pixel_counter_next <= pixel_counter + 1;
				elsif (plr_size = "101" and (clk_div4 = "01" or clk_div4 = "11")) then
					pixel_counter_next <= pixel_counter + 1;
				elsif (plr_size /= "111" and plr_size /= "101") then 
					pixel_counter_next <= pixel_counter + 1;
				end if;
			end if;
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
	
	missile_reset <= '1' when pixel_counter = "0100" and main_copy = '1' else '0';
						
	scan_out <= 
				'0' when pixel_counter = "0000" else
				data_delay(7) when pixel_counter = "0001" else
				data_delay(6) when pixel_counter = "0010" else
				data_delay(5) when pixel_counter = "0011" else
				data_delay(4) when pixel_counter = "0100" else
				data_delay(3) when pixel_counter = "0101" else
				data_delay(2) when pixel_counter = "0110" else
				data_delay(1) when pixel_counter = "0111" else
				data_delay(0) when pixel_counter = "1000" else
				'0';
				
	reflected_scan_out <= 
				'0' when pixel_counter = "0000" else
				data_delay(0) when pixel_counter = "0001" else
				data_delay(1) when pixel_counter = "0010" else
				data_delay(2) when pixel_counter = "0011" else
				data_delay(3) when pixel_counter = "0100" else
				data_delay(4) when pixel_counter = "0101" else
				data_delay(5) when pixel_counter = "0110" else
				data_delay(6) when pixel_counter = "0111" else
				data_delay(7) when pixel_counter = "1000" else
				'0';	

	pixel <= scan_out when reflect = '0' else reflected_scan_out;
	
end Behavioral;