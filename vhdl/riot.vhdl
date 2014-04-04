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

entity RIOT is Port (
	reset : in std_logic;
	clk : in std_logic;
	clk_ena : in std_logic;
	data_in : in std_logic_vector(7 downto 0);
	data_out : out std_logic_vector(7 downto 0);
	addr : in std_logic_vector(6 downto 0);
	rw : in std_logic;
	rs : in std_logic;
	cs : in std_logic;
	joystick1 : in std_logic_vector(3 downto 0);
	joystick2: in std_logic_vector(3 downto 0);
	difficulty : in std_logic_vector(1 downto 0);
	game_reset : in std_logic;
	game_select : in std_logic
);
end RIOT;

architecture Behavioral of RIOT is

signal reg_wren, ram_wren : std_logic;
signal ram_data_out, ram_data_in, reg_data_out : std_logic_vector(7 downto 0);

constant REGADDR_SWCHA : std_logic_vector := x"00"; 
constant REGADDR_SWCHB : std_logic_vector := x"02"; 
constant REGADDR_INTIM : std_logic_vector := x"04"; 
constant REGADDR_TIM1T : std_logic_vector := x"14"; 
constant REGADDR_TIM8T : std_logic_vector := x"15"; 
constant REGADDR_TIM64T : std_logic_vector := x"16"; 
constant REGADDR_T1024T : std_logic_vector := x"17"; 

signal interval_tick : std_logic;
signal timer_counter, timer_counter_next : std_logic_vector(7 downto 0);
signal countdown_mode, countdown_mode_next : std_logic;
signal prescaler, prescaler_next : std_logic_vector(1 downto 0);
signal prescale_counter, prescale_counter_next : std_logic_vector(9 downto 0);
begin

	ram_wren <= not rw and cs and rs;
	reg_wren <= not rw and cs and not rs;

	process(reset, prescaler_next)
	begin
		if (reset = '1') then
			prescaler <= (others => '0');
			timer_counter <= (others => '0');
			countdown_mode <= '0';
			prescale_counter <= (others => '0');
		elsif (clk'event and clk = '1' and clk_ena = '1') then
			prescaler <= prescaler_next;
			countdown_mode <= countdown_mode_next;
			timer_counter <= timer_counter_next;
			prescale_counter <= prescale_counter_next;
		end if;
	end process;
	
	-- register write logic
	process (reg_wren, addr, data_in)
	begin
		interval_tick <= '0';
		prescale_counter_next <= prescale_counter + 1;
		countdown_mode_next <= countdown_mode;
		prescaler_next <= prescaler;
		
		if (countdown_mode = '1') then
			case prescaler is
				when "00" =>		-- 1x
					interval_tick <= '1';
									
				when "01" =>		-- 8x
					if (prescale_counter(2 downto 0) = "111") then
						interval_tick <= '1';
					end if;
					
				when "10" =>		-- 64x
					if (prescale_counter(5 downto 0) = "111111") then
						interval_tick <= '1';
					end if;
					
				when "11" =>		-- 1024x
					if (prescale_counter = "1111111111") then
						interval_tick <= '1';
					end if;
			end case;
		else
			interval_tick <= '1';
		end if;
		
		
		
		if (timer_counter = "00000000" and interval_tick = '1') then
			countdown_mode_next <= '0';
		end if;

		if (interval_tick = '1') then
			timer_counter_next <= timer_counter  - 1;
		else
			timer_counter_next <= timer_counter;
		end if;
		
		if (reg_wren = '1') then 
			if (addr = REGADDR_TIM1T) then
				prescale_counter_next <= (others => '0');
				timer_counter_next <= data_in - 1;
				prescaler_next <= "00";
				countdown_mode_next <= '1';
			elsif (addr = REGADDR_TIM8T) then
				prescale_counter_next <= (others => '0');
				timer_counter_next <= data_in - 1;
				prescaler_next <= "01";
				countdown_mode_next <= '1';
			elsif (addr = REGADDR_TIM64T) then
				prescale_counter_next <= (others => '0');
				timer_counter_next <= data_in - 1;
				prescaler_next <= "10";
				countdown_mode_next <= '1';
			elsif (addr = REGADDR_T1024T) then
				prescale_counter_next <= (others => '0');
				timer_counter_next <= data_in - 1;
				prescaler_next <= "11";
				countdown_mode_next <= '1';
			end if;
	end if;
	end process;
	
	-- register read logic
	process (addr)
	begin
		reg_data_out <= "00000000";
		if (addr = REGADDR_INTIM) then
			reg_data_out <= timer_counter;
		elsif (addr = REGADDR_SWCHA) then
			reg_data_out <= joystick1 & joystick2;
		elsif (addr = REGADDR_SWCHB) then
			reg_data_out <= difficulty & "00" & "10" & game_select & game_reset;
		end if;
	end process;
	
	ram : entity work.riot_ram port map (
		address => addr,
		clock => clk,
		wren => ram_wren,
		data => ram_data_in,
		q => ram_data_out
	);
	
	ram_data_in <= data_in;
	data_out <= ram_data_out when rs = '1' else reg_data_out;
	
end Behavioral;