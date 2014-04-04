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

entity composite_video_generator is Port (
	reset : in std_logic;
	clk_60_71428 : in std_logic;
	clk_pixel_ena : in std_logic;
	in_burst : in std_logic;
	in_sync : in std_logic;
	color_index : in std_logic_vector(6 downto 0);
	output : out std_logic_vector(9 downto 0);
	apply_sync_voltage : out std_logic
);
end composite_video_generator;

architecture Behavioral of composite_video_generator is

signal color_index_reg : std_logic_vector(6 downto 0);
signal in_burst_reg, in_sync_reg : std_logic;

signal clkdiv_counter : std_logic_vector(2 downto 0);
signal pixel_clk_ena, half_pixel_clk_ena : std_logic;

signal color_carrier_phase, color_carrier_phase_next : std_logic_vector(17 downto 0);
signal color_carrier_phase_modulator, color_carrier_phase_modulated : std_logic_vector(7 downto 0);
signal color_carrier_amplitude, color_carrier_amplitude_clamped : std_logic_vector(2 downto 0);
signal color_carrier_value : std_logic_vector(10 downto 0);

signal luma_value_prev, luma_value_prev_next : std_logic_vector(10 downto 0);
signal luma_value, luma_value_filtered, composite_value, 
		 composite_value_subbed, composite_value_clamped : std_logic_vector(10 downto 0);
signal luma_values_added : std_logic_vector(11 downto 0);

signal sine_rom_addr : std_logic_vector(10 downto 0);
signal sine_rom_data : std_logic_vector(8 downto 0);

signal pixel_luma : std_logic_vector(10 downto 0);
signal pixel_phase : std_logic_vector(7 downto 0);
signal pixel_chroma : std_logic_vector(2 downto 0);



begin

	-- See https://github.com/elpuri/NTSC-composite-encoder for details how this works
	
	process(reset, clk_60_71428, clk_pixel_ena) 
	begin
		if (clk_60_71428'event and clk_60_71428 = '1') then
			if (clk_pixel_ena = '1') then
				color_index_reg <= color_index;
			end if;
			in_burst_reg <= in_burst;
			in_sync_reg <= in_sync;
			color_carrier_phase <= color_carrier_phase_next; 
			luma_value_prev <= luma_value_prev_next;
		end if;
	end process;
	
	-- Clock divider
	process(clk_60_71428, clkdiv_counter)
	begin
		if clk_60_71428'event and clk_60_71428 = '1' then
			clkdiv_counter <= clkdiv_counter + 1;
		end if;
		
		if clkdiv_counter = "000" then 
			pixel_clk_ena <= '1';
		else
			pixel_clk_ena <= '0';
		end if;
		
		if clkdiv_counter = "000" or clkdiv_counter = "100" then
			half_pixel_clk_ena <= '1';
		else
			half_pixel_clk_ena <= '0';
		end if;
	end process;
	
	color_carrier_phase_next <= color_carrier_phase + 15455;
	color_carrier_phase_modulated <= color_carrier_phase(17 downto 10) + color_carrier_phase_modulator;
	

	color_carrier_phase_modulator <= "00000000" when in_burst_reg = '1' else pixel_phase;


	color_carrier_amplitude <= "001" when in_burst = '1' else
							         pixel_chroma;

	color_carrier_value <= sine_rom_data(8) & sine_rom_data(8) & sine_rom_data when color_carrier_amplitude /= "111" else 
						  (others => '0');

	luma_value <= conv_std_logic_vector(0, 11) when in_sync_reg = '1' else		
			        conv_std_logic_vector(278, 11) when in_burst_reg = '1' else
			        pixel_luma;

	luma_value_prev_next <= luma_value_prev when half_pixel_clk_ena = '0' else luma_value;
	luma_values_added <= ("0" & luma_value_prev) + ("0" & luma_value);	
	luma_value_filtered <= luma_values_added(11 downto 1);					

	sine_rom_addr <= color_carrier_amplitude & color_carrier_phase_modulated;

	composite_value <= luma_value_filtered + color_carrier_value;
	composite_value_subbed <= composite_value_clamped - 428;
	composite_value_clamped <= composite_value when (composite_value <= 1023 + 428) else conv_std_logic_vector(1023 + 428, 11);
	output <= composite_value_subbed(9 downto 0) when composite_value(10)  = '1' else composite_value(9 downto 0);
	apply_sync_voltage <= composite_value(10);

	palette : entity work.palette port map (
		colu => color_index_reg,
		luma => pixel_luma,
		phase => pixel_phase,
		chroma => pixel_chroma
	);
	
	sinetable : entity work.sine_rom port map (
		address => sine_rom_addr,
		clock => clk_60_71428,
		q => sine_rom_data
	);

end Behavioral;