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

entity argh2600_de2_top is Port (
	clk_50 : in std_logic;
	vga_clk : out std_logic;
	vga_g : out std_logic_vector(9 downto 0);
	vga_blank : out std_logic;
	vga_sync : out std_logic;	
	sw : in std_logic_vector(17 downto 0);
	
	ps2_clk : in std_logic;
	ps2_dat : in std_logic;

	aud_xck : out std_logic;
	aud_bclk : in std_logic;
	aud_daclrck : in std_logic;
	aud_dacdat : out std_logic;
	
	i2c_sclk : out std_logic;
	i2c_sdat : inout std_logic;
	
	btn : in std_logic_vector(3 downto 0)
	
);
end argh2600_de2_top;

architecture Behavioral of argh2600_de2_top is

signal reset_btn, reset, pll_locked : std_logic;
signal clk_60_71428 : std_logic;
signal clk_17 : std_logic;
signal clk_3_5714_ena : std_logic;
signal cpu_clk_ena : std_logic;

signal cpu_data_in, cpu_data_out : std_logic_vector(7 downto 0);
signal cpu_addr : std_logic_vector(23 downto 0);
signal cpu_read, cpu_sync, cpu_write_n, cpu_write, cpu_rw_n : std_logic;
signal cpu_irq_n, cpu_nmi_n, cpu_rdy, cpu_reset_n, cpu_so_n : std_logic;

signal tia_rw, tia_cs, tia_rdy : std_logic;
signal tia_addr : std_logic_vector(5 downto 0);
signal tia_luma : std_logic_vector(2 downto 0);
signal tia_chroma : std_logic_vector(3 downto 0);
signal tia_sync : std_logic;
signal tia_burst : std_logic;
signal tia_data_out, tia_data_in : std_logic_vector(7 downto 0);
signal tia_inputs : std_logic_vector(5 downto 0);
signal tia_audio : std_logic_vector(4 downto 0);

signal riot_addr : std_logic_vector(6 downto 0);
signal riot_data_in, riot_data_out : std_logic_vector(7 downto 0);
signal riot_rs, riot_cs : std_logic;

signal cartridge_addr : std_logic_vector(11 downto 0);
signal cartridge_data : std_logic_vector(7 downto 0);

signal ledgr, ledgr_next : std_logic_vector(7 downto 0);

signal tia_vsync, tia_hsync : std_logic;

signal color_index : std_logic_vector(6 downto 0);
signal composite_value : std_logic_vector(9 downto 0);
signal composite_sync : std_logic;
signal compoiste_burst : std_logic;
signal composite_dac_sync_voltage : std_logic;

signal scaled_audio : std_logic_vector(15 downto 0);

signal v1, v2 : std_logic;
signal vsync_period, vsync_period_next, current_period, current_period_next : std_logic_vector(23 downto 0);
signal vsync_count, vsync_count_next : std_logic_vector(7 downto 0);

signal ac97_sample : std_logic_vector(15 downto 0);

signal keyb_p1_fire, keyb_p1_left, keyb_p1_right, keyb_p1_up, keyb_p1_down,
       keyb_p2_fire, keyb_p2_left, keyb_p2_right, keyb_p2_up, keyb_p2_down,
		 keyb_game_reset, keyb_game_select : std_logic;

signal riot_joystick1, riot_joystick2 : std_logic_vector(3 downto 0);
signal riot_game_reset, riot_game_select : std_logic;
signal riot_difficulty : std_logic_vector(1 downto 0);		 
		 
signal p1_fire, p2_fire : std_logic;
		 
begin
	reset_btn <= sw(17);
	
	pll : entity work.pll port map (
		areset => reset_btn,
		inclk0 => clk_50,
		c0 => clk_60_71428,
		c1 => clk_17,
		locked => pll_locked
	);
	
	div17 : entity work.lfsr_div_17 port map (
		reset => reset,
		clk => clk_60_71428,
		tick => clk_3_5714_ena
	);
	
	reset <= not pll_locked or reset_btn;
	
	p1_fire <= btn(0) and (not keyb_p1_fire);
	p2_fire <= btn(1) and (not keyb_p2_fire);
	riot_joystick1 <= not keyb_p1_right & not keyb_p1_left & not keyb_p1_down & not keyb_p1_up;
	riot_joystick2 <= not keyb_p2_right & not keyb_p2_left & not keyb_p2_down & not keyb_p2_up;
	
	tia_inputs <= p2_fire & p1_fire & "0000";
	
	color_index <= tia_chroma & tia_luma;
	
	composite : entity work.composite_video_generator port map (
		reset => reset,
		clk_60_71428 => clk_60_71428,
		clk_pixel_ena => clk_3_5714_ena,
		output => composite_value,
		apply_sync_voltage => composite_dac_sync_voltage,
		color_index => color_index,
		in_sync => tia_sync,
		in_burst => tia_burst
	);
	
	vga_blank <= '1';
	vga_sync <= composite_dac_sync_voltage;
	vga_g <= composite_value;
	vga_clk <= clk_60_71428;
	
	tia : entity work.TIA port map (
		reset => reset,
		clk => clk_60_71428,
		clk_3_5714_ena => clk_3_5714_ena,
		clk_div3_ena => cpu_clk_ena,
		data_in => cpu_data_out,
		data_out => tia_data_out,
		addr => tia_addr,
		burst => tia_burst,
		rw => cpu_read,
		cs => tia_cs,
		rdy => tia_rdy,
		luma => tia_luma,
		chroma => tia_chroma,
		comp_sync => tia_sync,
		vsync => tia_vsync,
		hsync => tia_hsync,
		sw => sw(7 downto 0),
		i_n => tia_inputs,
		audio => tia_audio
	);

	tia_addr <= cpu_addr(5 downto 0);

	riot : entity work.RIOT port map (
		reset => reset,
		clk => clk_60_71428,
		clk_ena => cpu_clk_ena,
		addr => riot_addr,
		data_in => riot_data_in,
		data_out => riot_data_out,
		rs => riot_rs,
		cs => riot_cs,
		rw => cpu_read,
		joystick1 => riot_joystick1,
		joystick2 => riot_joystick2,
		game_select => riot_game_select,
		game_reset => riot_game_reset,
		difficulty => riot_difficulty
	);
	
	
	riot_game_reset <= not keyb_game_reset and sw(5);
	riot_game_select <= not keyb_game_select and sw(4);
	riot_difficulty <= sw(7 downto 6);
	
	riot_rs <= '0' when cpu_addr(9) = '1' else '1';
	riot_cs <= '1' when cpu_addr(12) = '0' and cpu_addr(7) = '1' else '0';
	tia_cs <=  '1' when (cpu_addr(12) = '0') and (cpu_addr(7) = '0') else '0';

	riot_addr <= cpu_addr(6 downto 0);
	riot_data_in <= cpu_data_out;
	
	cpu : entity work.t65 port map (
		Mode => "00",
		Res_n => cpu_reset_n,
		Enable => cpu_clk_ena,
		Clk => clk_60_71428,
		Rdy => cpu_rdy,
		Abort_n => cpu_irq_n,
		IRQ_n => cpu_irq_n,
		NMI_n => cpu_nmi_n,
		SO_n => cpu_so_n,
		R_W_n => cpu_rw_n,
		Sync => cpu_sync,
		A => cpu_addr,
		DI => cpu_data_in,
		DO => cpu_data_out
	);
		
	
	cpu_reset_n <= not reset;
	cpu_irq_n <= '1';
	cpu_nmi_n <= '1';
	cpu_so_n <= '1';
	cpu_rdy <= tia_rdy;
	cpu_read <= cpu_rw_n;

	-- CPU data mux
	cpu_data_in <= riot_data_out when riot_cs = '1' else
						tia_data_out when tia_cs = '1' else
						cartridge_data;
						
	cartridge_addr <= cpu_addr(11 downto 0);
	
	cartridge_rom : entity work.program_rom generic map (
		memory_file => "../../roms/barn.mif"
	) port map (
		clock => clk_60_71428,
		address => cartridge_addr,
		q => cartridge_data
	);
	
	scaled_audio <= "0" & tia_audio & "0000000000";
	
	codec : work.ac97_codec port map (
		clk_50 => clk_50,
		clk_17 => clk_17,
		reset => reset,
		ac97_xck => aud_xck,
		ac97_bclk => aud_bclk,
		ac97_daclrck => aud_daclrck,
		ac97_dacdat => aud_dacdat,
		i2c_sclk => i2c_sclk,
		i2c_sdat => i2c_sdat,
		sample => scaled_audio
	);

	controls : work.keyboard_controls port map (
		clk => clk_60_71428,
		reset => reset,
		ps2_clk => ps2_clk,
		ps2_data => ps2_dat,
		p1_left => keyb_p1_left,
		p1_right => keyb_p1_right,
		p1_up => keyb_p1_up,
		p1_down => keyb_p1_down,
		p1_fire => keyb_p1_fire,
		p2_left => keyb_p2_left,
		p2_right => keyb_p2_right,
		p2_up => keyb_p2_up,
		p2_down => keyb_p2_down,
		p2_fire => keyb_p2_fire,
		game_reset => keyb_game_reset,
		game_select => keyb_game_select
	);
	
end Behavioral;
