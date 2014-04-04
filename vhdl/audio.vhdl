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

entity audio is Port (
	reset : in std_logic;
	clk : in std_logic;
	clk_ena : in std_logic;
	volume : in std_logic_vector(3 downto 0);
	freq : in std_logic_vector(4 downto 0);
	mode : in std_logic_vector(3 downto 0);
	output : out std_logic_vector(3 downto 0)
);
end audio;
architecture Behavioral of audio is

signal w: std_logic;
signal f_counter, f_counter_next : std_logic_vector(4 downto 0); 
signal toggled, toggled_next : std_logic;

signal cnt3, cnt3_next : std_logic_vector(1 downto 0);
signal cnt3_ena : std_logic;

signal lfsr4, lfsr4_next : std_logic_vector(3 downto 0);
signal lfsr5, lfsr5_next : std_logic_vector(4 downto 0);
signal lfsr9, lfsr9_next : std_logic_vector(8 downto 0);
signal lfsr4_clk_ena : std_logic;
signal lfsr4_out, lfsr5_out, lfsr9_out : std_logic;
signal lfsr5_edge : std_logic;

signal div31_edge, div6_edge : std_logic;

begin
	process(clk)
	

	-- prescalers
	begin
		if (clk'event and clk = '1' and clk_ena = '1') then			
			if (f_counter = freq) then
				f_counter <= "00000";
				if (lfsr4_clk_ena = '1') then
					lfsr4 <= lfsr4_next;
				end if;
				lfsr5 <= lfsr5_next;
				lfsr9 <= lfsr9_next;
				toggled <= toggled_next;
				if (cnt3_ena = '1') then
					cnt3 <= cnt3_next;
				end if;
			else
				f_counter <= f_counter + 1;
			end if;
		end if;
	end process;
	
	lfsr5_edge <= '1' when (lfsr5(0) = '0' and lfsr5(1) = '1') or (lfsr5(0) = '1' and lfsr5(1) = '0') else '0';
	div31_edge <= '1' when lfsr5 = "11111" or lfsr5 = "10000" else '0';
	div6_edge <= '1' when cnt3 = "10" else '0';

	process (mode)
	begin
		lfsr4_clk_ena <= '1';
		toggled_next <= toggled;
		cnt3_ena <= '1';
		
		case mode is 
			when "0000" =>
				w <= '1';
			when "0001" =>
				w <= lfsr4_out;
			when "0010" =>
				w <= lfsr4_out;
				lfsr4_clk_ena <= div31_edge;
			when "0011" =>
				w <= lfsr4_out;
				lfsr4_clk_ena <= lfsr5_out;
			when "0100" =>
				w <= toggled;
				toggled_next <= not toggled;
			when "0101" =>
				w <= toggled;
				toggled_next <= not toggled;
			when "0110" =>
				w <= toggled;
				if (div31_edge = '1') then
					toggled_next <= not toggled;
				end if;
			when "0111" =>
				w <= lfsr5_out;
			when "1000" =>			-- 8
				w <= lfsr9_out;
			when "1001" =>			-- 9
				w <= lfsr5_out;
			when "1010" =>			-- A
				w <= toggled;
				if (div31_edge = '1') then
					toggled_next <= not toggled;
				end if;				
			when "1011" =>
				w <= '1';
			when "1100" =>
				w <= toggled;
				if (div6_edge = '1') then
					toggled_next <= not toggled;
				end if;
			when "1101" =>
				w <= toggled;
				if (div6_edge = '1') then
					toggled_next <= not toggled;
				end if;
			when "1110" =>
				w <= toggled;
				cnt3_ena <= div31_edge;
				if (div6_edge = '1') then
					toggled_next <= not toggled;
				end if;
			when "1111" =>
				w <= toggled;
				if (lfsr5_edge = '1') then
					toggled_next <= not toggled;
				end if;
		end case;
	end process;
	
	
	
	
	
		
						
	cnt3_next <= "00" when cnt3 ="10" else cnt3 + 1;
	lfsr4_next <= "1111" when lfsr4 = "0000" else 
					  (lfsr4(0) xor lfsr4(1)) & lfsr4(3 downto 1);
	lfsr5_next <= "11111" when lfsr5 = "00000" else 
					 (lfsr5(0) xor lfsr5(2)) & lfsr5(4 downto 1); 
	lfsr9_next <= "111111111" when lfsr9 = "000000000" else
					(lfsr9(0) xor lfsr9(4)) & lfsr9(8 downto 1);
	lfsr4_out <= lfsr4(0);
	lfsr5_out <= lfsr5(0);
	lfsr9_out <= lfsr9(0);
	
	output <= (volume) and (w & w & w & w);

end Behavioral;