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

entity TIA is Port (
	reset : in std_logic;
	clk : in std_logic;
	clk_3_5714_ena : in std_logic;
	clk_div3_ena : out std_logic;
	comp_sync : out std_logic;
	burst : out std_logic;
	data_in : in std_logic_vector(7 downto 0);
	data_out : out std_logic_vector(7 downto 0);
	addr : in std_logic_vector(5 downto 0);
	rw : in std_logic;
	cs : in std_logic;
	luma : out std_logic_vector(2 downto 0);
	chroma : out std_logic_vector(3 downto 0);
	rdy : out std_logic;
	vsync : out std_logic;
	hsync : out std_logic;
	sw : in std_logic_vector(7 downto 0);
	i_n : in std_logic_vector(5 downto 0);
	audio : out std_logic_vector(4 downto 0)
);
end TIA;
architecture Behavioral of TIA is

-- Register addresses
constant REGADDR_VSYNC : std_logic_vector := x"00"; 
constant REGADDR_VBLANK : std_logic_vector := x"01";
constant REGADDR_WSYNC : std_logic_vector := x"02";

constant REGADDR_NUSIZ0 : std_logic_vector := x"04";
constant REGADDR_NUSIZ1 : std_logic_vector := x"05";


constant REGADDR_COLUP0 : std_logic_vector := x"06";
constant REGADDR_COLUP1 : std_logic_vector := x"07";
constant REGADDR_COLUPF : std_logic_vector := x"08";
constant REGADDR_COLUBK : std_logic_vector := x"09";
constant REGADDR_CTRLPF : std_logic_vector := x"0a";
constant REGADDR_REFP0 : std_logic_vector := x"0b";
constant REGADDR_REFP1 : std_logic_vector := x"0c";
constant REGADDR_PF0 : std_logic_vector := x"0d";
constant REGADDR_PF1 : std_logic_vector := x"0e";
constant REGADDR_PF2 : std_logic_vector := x"0f";
constant REGADDR_RESP0 : std_logic_vector := x"10";
constant REGADDR_RESP1 : std_logic_vector := x"11";
constant REGADDR_RESM0 : std_logic_vector := x"12";
constant REGADDR_RESM1 : std_logic_vector := x"13";
constant REGADDR_RESBL : std_logic_vector := x"14";
constant REGADDR_AUDC0 : std_logic_vector := x"15";
constant REGADDR_AUDC1 : std_logic_vector := x"16";
constant REGADDR_AUDF0 : std_logic_vector := x"17";
constant REGADDR_AUDF1 : std_logic_vector := x"18";
constant REGADDR_AUDV0 : std_logic_vector := x"19";
constant REGADDR_AUDV1 : std_logic_vector := x"1a";

constant REGADDR_GRP0 : std_logic_vector := x"1b";
constant REGADDR_GRP1 : std_logic_vector := x"1c";
constant REGADDR_ENAM0 : std_logic_vector := x"1d";
constant REGADDR_ENAM1 : std_logic_vector := x"1e";
constant REGADDR_ENABL : std_logic_vector := x"1f";

constant REGADDR_HMP0 : std_logic_vector := x"20";
constant REGADDR_HMP1 : std_logic_vector := x"21";
constant REGADDR_HMM0 : std_logic_vector := x"22";
constant REGADDR_HMM1 : std_logic_vector := x"23";
constant REGADDR_HMBL : std_logic_vector := x"24";

constant REGADDR_VDELP0 : std_logic_vector := x"25";
constant REGADDR_VDELP1 : std_logic_vector := x"26";
constant REGADDR_RESMP0 : std_logic_vector := x"28";
constant REGADDR_RESMP1 : std_logic_vector := x"29";

constant REGADDR_HMOVE : std_logic_vector := x"2a";
constant REGADDR_HMCLR : std_logic_vector := x"2b";
constant REGADDR_CXCLR : std_logic_vector := x"2c";

constant REGADDR_CXM0P : std_logic_vector := x"00";
constant REGADDR_CXM1P : std_logic_vector := x"01";
constant REGADDR_CXP0FB : std_logic_vector := x"02";
constant REGADDR_CXP1FB : std_logic_vector := x"03";
constant REGADDR_CXM0FB: std_logic_vector := x"04";
constant REGADDR_CXM1FB : std_logic_vector := x"05";
constant REGADDR_CXBLPF : std_logic_vector := x"06";
constant REGADDR_CXPPMM : std_logic_vector := x"07";
  
constant REGADDR_INPT4 : std_logic_vector := x"0c";
constant REGADDR_INPT5 : std_logic_vector := x"0d";

signal clk_div3 : std_logic_vector(2 downto 0) := "100";
signal clk_div4 : std_logic_vector(1 downto 0) := "00";


-- HS counter stuff
signal hs_counter, hs_counter_next : std_logic_vector(5 downto 0);
signal hs_hsync_start, hs_hsync_end, hs_burst, hs_hblank_end, 
	    hs_late_hblank_end, hs_hblank_start, hs_center : std_logic;

signal ready : std_logic := '1';		 
signal ready_delay : std_logic_vector(1 downto 0); 
signal ready_next : std_logic;
signal reg_vsync, reg_vsync_next : std_logic;
signal reg_vblank, reg_vblank_next : std_logic;
signal reg_colubk, reg_colubk_next : std_logic_vector(7 downto 1);
signal reg_colupf, reg_colupf_next : std_logic_vector(7 downto 1);
signal reg_colup0, reg_colup0_next : std_logic_vector(7 downto 1);
signal reg_colup1, reg_colup1_next : std_logic_vector(7 downto 1);
signal reg_pf0, reg_pf0_next : std_logic_vector(3 downto 0);
signal reg_pf1, reg_pf1_next : std_logic_vector(7 downto 0);
signal reg_pf2, reg_pf2_next : std_logic_vector(7 downto 0);
signal reg_ctrlpf, reg_ctrlpf_next : std_logic_vector(7 downto 0);
signal reg_grp0, reg_grp0_next : std_logic_vector(7 downto 0);	 
signal reg_grp1, reg_grp1_next : std_logic_vector(7 downto 0);	 
signal reg_grp0_delayed, reg_grp0_delayed_next : std_logic_vector(7 downto 0);	 
signal reg_grp1_delayed, reg_grp1_delayed_next : std_logic_vector(7 downto 0);	 
signal reg_vdelp0, reg_vdelp0_next, reg_vdelp1, reg_vdelp1_next : std_logic;
signal reg_hmp0, reg_hmp1, reg_hmp0_next, reg_hmp1_next, reg_hmbl, reg_hmbl_next,
		 reg_hmm0, reg_hmm0_next, reg_hmm1, reg_hmm1_next : std_logic_vector(7 downto 4);
signal reg_nusiz0, reg_nusiz0_next : std_logic_vector(5 downto 0);
signal reg_nusiz1, reg_nusiz1_next : std_logic_vector(5 downto 0);
signal reg_enabl, reg_enabl_next : std_logic;
signal reg_enam0, reg_enam0_next, reg_enam1, reg_enam1_next : std_logic;
signal reg_refp0, reg_refp0_next, reg_refp1, reg_refp1_next : std_logic;
signal reg_audv0, reg_audv0_next, reg_audv1, reg_audv1_next : std_logic_vector(3 downto 0);
signal reg_audf0, reg_audf0_next, reg_audf1, reg_audf1_next : std_logic_vector(4 downto 0);
signal reg_audc0, reg_audc0_next, reg_audc1, reg_audc1_next : std_logic_vector(3 downto 0);

signal input_latches, input_latches_next : std_logic_vector(1 downto 0);
signal input_latch_enable, input_latch_enable_next : std_logic;
signal collision_latches, collision_latches_next : std_logic_vector(14 downto 0);

signal hmove : std_logic := '0';
signal hmove_next : std_logic;
signal hmove_trigger : std_logic;
signal line_tick : std_logic;
	 
signal blanking : std_logic;
signal in_hblank, in_hblank_next : std_logic;
signal in_hsync, in_hsync_next : std_logic;

signal mirror_pf : std_logic;
signal pixel : std_logic_vector(6 downto 0);

signal pf_pixel : std_logic;
signal pf_pixel_color : std_logic_vector(6 downto 0);

signal p0_pixel, p0_rst_strobe, p1_pixel, p1_rst_strobe : std_logic;

signal m0_pixel, m1_pixel, m0_rst_strobe, m1_rst_strobe : std_logic;
signal reg_resmp0, reg_resmp0_next, reg_resmp1, reg_resmp1_next : std_logic;
signal p0_missile_reset, p1_missile_reset : std_logic;

signal ball_pixel, ball_rst_strobe : std_logic;
signal ball_size : std_logic_vector(1 downto 0);
	 
signal motck_ena : std_logic;
	 
signal read_addr : std_logic_vector(3 downto 0);

signal p0_data, p1_data : std_logic_vector(7 downto 0);

signal audio_tick_edge : std_logic;

signal audio_ch0_output, audio_ch1_output : std_logic_vector(3 downto 0);

signal past_half, past_half_next : std_logic;
signal pf_score_coloring_mode : std_logic;

begin


	process(reset, clk, clk_3_5714_ena)
	begin
		if (reset = '1') then
			clk_div3 <= "100";
			clk_div4 <= "00";
		elsif (clk'event and clk = '1') then
			
			if (clk_3_5714_ena = '1') then
				ready_delay <= ready_delay(0) & ready_next;
				clk_div3 <= clk_div3(1 downto 0) & clk_div3(2);
				clk_div4 <= clk_div4 + 1;
				
				if (line_tick = '1') then
					clk_div3 <= "001";
				end if;
			end if;

		end if;
	end process;
	
	clk_div3_ena <= '1' when clk_div3(2) = '1' and clk_3_5714_ena = '1' else '0';

	
	-- register updates
	process(reset, clk) 
	begin
		if (reset = '1') then
			hs_counter <= (others => '0');
		   reg_colubk <= (others => '0');
		   reg_colupf <= (others => '0');
		   reg_ctrlpf <= (others => '0');
			reg_vsync <= '0';
			reg_vblank <= '0';
			reg_pf0 <= (others => '0');
			reg_pf1 <= (others => '0');
			reg_pf2 <= (others => '0');
			reg_grp0 <= (others => '0');
			reg_grp1 <= (others => '0');
			reg_colup0 <= (others => '0');
			reg_colup1 <= (others => '0');
			reg_hmp0 <= (others => '0');
			reg_hmp1 <= (others => '0');
			reg_hmbl <= (others => '0');
			hmove <= '0';
			ready <= '1';
			collision_latches <= (others => '0');
		else 
			if (clk'event and clk = '1' and clk_div4 = "11" and clk_3_5714_ena = '1') then
				hs_counter <= hs_counter_next;
				in_hblank <= in_hblank_next;
				in_hsync <= in_hsync_next;
				past_half <= past_half_next;
			end if;
			
			if (clk'event and clk = '1' and clk_3_5714_ena = '1' and clk_div3 = "100") then
				reg_enabl <= reg_enabl_next;
				reg_colubk <= reg_colubk_next;
				reg_colupf <= reg_colupf_next;
				reg_vsync <= reg_vsync_next;
				reg_vblank <= reg_vblank_next;
				reg_pf0 <= reg_pf0_next;
				reg_pf1 <= reg_pf1_next;
				reg_pf2 <= reg_pf2_next;
				reg_ctrlpf <= reg_ctrlpf_next;
				reg_grp0 <= reg_grp0_next;
				reg_grp1 <= reg_grp1_next;
				reg_grp0_delayed <= reg_grp0_delayed_next;
				reg_grp1_delayed <= reg_grp1_delayed_next;
				reg_colup0 <= reg_colup0_next;
				reg_colup1 <= reg_colup1_next;
				reg_hmp0 <= reg_hmp0_next;
				reg_hmp1 <= reg_hmp1_next;
				reg_hmbl <= reg_hmbl_next;
				reg_hmm0 <= reg_hmm0_next;
				reg_hmm1 <= reg_hmm1_next;
				reg_nusiz0 <= reg_nusiz0_next;
				reg_nusiz1 <= reg_nusiz1_next;
				reg_refp0 <= reg_refp0_next;
				reg_refp1 <= reg_refp1_next;
				reg_vdelp0 <= reg_vdelp0_next;
				reg_vdelp1 <= reg_vdelp1_next;
				reg_audv0 <= reg_audv0_next;
				reg_audv1 <= reg_audv1_next;
				reg_audf0 <= reg_audf0_next;
				reg_audf1 <= reg_audf1_next;
				reg_audc0 <= reg_audc0_next;
				reg_audc1 <= reg_audc1_next;
				reg_enam0 <= reg_enam0_next;
				reg_enam1 <= reg_enam1_next;
				reg_resmp0 <= reg_resmp0_next;
				reg_resmp1 <= reg_resmp1_next;
			end if;
			
			if (clk'event and clk = '1' and clk_3_5714_ena = '1') then
				ready <= ready_next;
				hmove <= hmove_next;
				input_latch_enable <= input_latch_enable_next;
				input_latches <= input_latches_next;
				collision_latches <= collision_latches_next;
			end if;	
		end if;
			
	end process;
	
	-- Wrap around logic for hs_counter
	hs_counter_next <= (others => '0') when hs_counter = conv_std_logic_vector(56, 6) else hs_counter + 1;
	
	-- clk 280ns
	-- counter tick 1,120uS
	
	-- HS counter decodes
	hs_hblank_start <= '1' when hs_counter = conv_std_logic_vector(56, 6) else '0';
	hs_hsync_start <= '1' when hs_counter = conv_std_logic_vector(4, 6) else '0';
	hs_hsync_end <= '1' when hs_counter = conv_std_logic_vector(8, 6) else '0';
	hs_burst <= '1' when hs_counter = conv_std_logic_vector(11, 6) else '0';
	hs_hblank_end <= '1' when hs_counter = conv_std_logic_vector(16, 6) else '0';
	hs_late_hblank_end <= '1' when hs_counter = conv_std_logic_vector(18, 6) else '0';
	hs_center <= '1' when hs_counter = conv_std_logic_vector(36, 6) else '0';

	-- Used for playfield score coloring mode
	past_half_next <= '1' when hs_center = '1' else 
							'0' when hs_counter_next = "000000" else
							past_half;
	
	-- Horizontal blank & sync logic 
	process(in_hsync, in_hblank, hs_hblank_start, hs_hblank_end, hs_hsync_start, hs_hsync_end)
	begin
		in_hsync_next <= in_hsync;
		in_hblank_next <= in_hblank;
		if (hs_hblank_start = '1') then
			in_hblank_next <= '1';
		elsif (hs_late_hblank_end = '1' and hmove = '1') then
			in_hblank_next <= '0';
		elsif (hs_hblank_end = '1' and hmove = '0') then
			in_hblank_next <= '0';
		end if;
		
		if (hs_hsync_start = '1') then
			in_hsync_next <= '1';
		elsif (hs_hsync_end = '1') then
			in_hsync_next <= '0';
		end if;
	end process;
	
	-- HMOVE logic
	process(addr, rw, cs) 
	begin
		hmove_next <= hmove;
		hmove_trigger <= '0';
		if (addr = REGADDR_HMOVE and cs = '1' and rw = '0') then
			hmove_next <= '1';
			hmove_trigger <= '1';
		elsif (hs_counter_next = "000000") then
			hmove_next <= '0';
		end if;
	end process;
	
	-- RDY & WSYNC strobe logic
	process(ready, addr, rw, cs, hs_hsync_start)
	begin
		ready_next <= ready;
		line_tick <= '0';
		if (addr = REGADDR_WSYNC and cs = '1' and rw = '0') then
			ready_next <= '0';
		end if;
		-- Can't be elsif because in some games (Pitfall I) sta WSYNC can be called on 
		-- the last remaining cycles of a line, causing a scanline to be doubled.
		if (hs_counter_next = "000000" and clk_div4 = "11") then
			ready_next <= '1';
			line_tick <= '1';
		end if;
	end process;
	
	-- RESP0 and RESP1 strobe logic
	process(addr, cs, rw, clk_div3)
	begin
		p0_rst_strobe <= '0';
		p1_rst_strobe <= '0';
		ball_rst_strobe <= '0';
		m0_rst_strobe <= '0';
		m1_rst_strobe <= '0';
		
		if (addr = REGADDR_RESP0 and cs = '1' and rw = '0' and clk_div3 = "100" ) then
			p0_rst_strobe <= '1';
		end if;
		
		if (addr = REGADDR_RESP1 and cs = '1' and rw = '0' and clk_div3 = "100" ) then
			p1_rst_strobe <= '1';
		end if;
		
		if (addr = REGADDR_RESBL and cs = '1' and rw = '0' and clk_div3 = "100" ) then
			ball_rst_strobe <= '1';
		end if;

		if (addr = REGADDR_RESM0 and cs = '1' and rw = '0' and clk_div3 = "100" ) then
			m0_rst_strobe <= '1';
		end if;

		if (addr = REGADDR_RESM1 and cs = '1' and rw = '0' and clk_div3 = "100" ) then
			m1_rst_strobe <= '1';
		end if;

	
	end process;
	
	-- Register write access logic
	process(addr, rw, cs, data_in, reg_colubk, reg_vblank, reg_vsync,
			  reg_ctrlpf, reg_pf1, hs_hblank_end)
	begin
		reg_colubk_next <= reg_colubk;
		reg_colupf_next <= reg_colupf;
		reg_vblank_next <= reg_vblank;
		reg_vsync_next <= reg_vsync;
		reg_ctrlpf_next <= reg_ctrlpf;
		reg_pf0_next <= reg_pf0;
		reg_pf1_next <= reg_pf1;
		reg_pf2_next <= reg_pf2;
		reg_grp0_next <= reg_grp0;
		reg_grp1_next <= reg_grp1;
		reg_grp0_delayed_next <= reg_grp0_delayed;
		reg_grp1_delayed_next <= reg_grp1_delayed;
		reg_colup0_next <= reg_colup0;
		reg_colup1_next <= reg_colup1;
		reg_nusiz0_next <= reg_nusiz0;
		reg_nusiz1_next <= reg_nusiz1;
		reg_hmp0_next <= reg_hmp0;
		reg_hmp1_next <= reg_hmp1;
		reg_hmbl_next <= reg_hmbl;
		reg_hmm0_next <= reg_hmm0;
		reg_hmm1_next <= reg_hmm1;
		reg_refp0_next <= reg_refp0;
		reg_refp1_next <= reg_refp1;
		reg_vdelp0_next <= reg_vdelp0;
		reg_vdelp1_next <= reg_vdelp1;
		reg_enabl_next <= reg_enabl;
		reg_audv0_next <= reg_audv0;
		reg_audv1_next <= reg_audv1;
		reg_audf0_next <= reg_audf0;
		reg_audf1_next <= reg_audf1;
		reg_audc0_next <= reg_audc0;
		reg_audc1_next <= reg_audc1;
		reg_enam0_next <= reg_enam0;
		reg_enam1_next <= reg_enam1;
		reg_resmp0_next <= reg_resmp0;
		reg_resmp1_next <= reg_resmp1;		
		
		if (addr = REGADDR_COLUBK and cs = '1' and rw = '0') then
			reg_colubk_next <= data_in(7 downto 1);
		end if;
		
		if (addr = REGADDR_COLUPF and cs = '1' and rw = '0') then
			reg_colupf_next <= data_in(7 downto 1);
		end if;
		
		if (addr = REGADDR_VBLANK and cs = '1' and rw = '0') then
			reg_vblank_next <= data_in(1);
		end if;

		if (addr = REGADDR_VSYNC and cs = '1' and rw = '0') then
			reg_vsync_next <= data_in(1);
		end if;
		
		if (addr = REGADDR_PF0 and cs = '1' and rw = '0') then
			reg_pf0_next <= data_in(7 downto 4);
		end if;
		
		if (addr = REGADDR_PF1 and cs = '1' and rw = '0') then
			reg_pf1_next <= data_in;
		end if;
		
		if (addr = REGADDR_PF2 and cs = '1' and rw = '0') then
			reg_pf2_next <= data_in;
		end if;
		
		if (addr = REGADDR_CTRLPF and cs = '1' and rw = '0') then
			reg_ctrlpf_next <= data_in;
		end if;
		
		if (addr = REGADDR_COLUP0 and cs = '1' and rw = '0') then
			reg_colup0_next <= data_in(7 downto 1);
		end if;
		
		if (addr = REGADDR_COLUP1 and cs = '1' and rw = '0') then
			reg_colup1_next <= data_in(7 downto 1);
		end if;
		
		if (addr = REGADDR_GRP0 and cs = '1' and rw = '0') then
			reg_grp0_next <= data_in;
			reg_grp1_delayed_next <= reg_grp1;
		end if;
		
		if (addr = REGADDR_GRP1 and cs = '1' and rw = '0') then
			reg_grp1_next <= data_in;
			reg_grp0_delayed_next <= reg_grp0;
		end if;
		
		if (addr = REGADDR_HMP0 and cs = '1' and rw = '0') then
			reg_hmp0_next <= data_in(7 downto 4);
		end if;
		
		if (addr = REGADDR_HMP1 and cs = '1' and rw = '0') then
			reg_hmp1_next <= data_in(7 downto 4);
		end if;
		
		if (addr = REGADDR_HMBL and cs = '1' and rw = '0') then
			reg_hmbl_next <= data_in(7 downto 4);
		end if;
		
		if (addr = REGADDR_HMM0 and cs = '1' and rw = '0') then
			reg_hmm0_next <= data_in(7 downto 4);
		end if;

		if (addr = REGADDR_HMM1 and cs = '1' and rw = '0') then
			reg_hmm1_next <= data_in(7 downto 4);
		end if;
		
		if (addr = REGADDR_NUSIZ0 and cs = '1' and rw = '0') then
			reg_nusiz0_next <= data_in(5 downto 0);
		end if;
		
		if (addr = REGADDR_NUSIZ1 and cs = '1' and rw = '0') then
			reg_nusiz1_next <= data_in(5 downto 0);
		end if;
		
		if (addr = REGADDR_HMCLR and cs = '1' and rw = '0') then
			reg_hmp0_next <= "0000";
			reg_hmp1_next <= "0000";
			reg_hmbl_next <= "0000";
			reg_hmm0_next <= "0000";
			reg_hmm1_next <= "0000";
		end if;
		
		if (addr = REGADDR_REFP0 and cs = '1' and rw = '0') then
			reg_refp0_next <= data_in(3);
		end if;

		if (addr = REGADDR_REFP1 and cs = '1' and rw = '0') then
			reg_refp1_next <= data_in(3);
		end if;
		
		if (addr = REGADDR_REFP1 and cs = '1' and rw = '0') then
			reg_refp1_next <= data_in(3);
		end if;
		
		if (addr = REGADDR_REFP1 and cs = '1' and rw = '0') then
			reg_refp1_next <= data_in(3);
		end if;
		
		if (addr = REGADDR_VDELP0 and cs = '1' and rw = '0') then
			reg_vdelp0_next <= data_in(0);
		end if;

		if (addr = REGADDR_VDELP1 and cs = '1' and rw = '0') then
			reg_vdelp1_next <= data_in(0);
		end if;
		
		if (addr = REGADDR_ENABL and cs = '1' and rw = '0') then
			reg_enabl_next <= data_in(1);
		end if;
		
		if (addr = REGADDR_AUDV0 and cs = '1' and rw = '0') then
			reg_audv0_next <= data_in(3 downto 0);
		end if;
		
		if (addr = REGADDR_AUDV1 and cs = '1' and rw = '0') then
			reg_audv1_next <= data_in(3 downto 0);
		end if;

		if (addr = REGADDR_AUDF0 and cs = '1' and rw = '0') then
			reg_audf0_next <= data_in(4 downto 0);
		end if;
		
		if (addr = REGADDR_AUDF1 and cs = '1' and rw = '0') then
			reg_audf1_next <= data_in(4 downto 0);
		end if;		
		
		if (addr = REGADDR_AUDC0 and cs = '1' and rw = '0') then
			reg_audc0_next <= data_in(3 downto 0);
		end if;
		
		if (addr = REGADDR_AUDC1 and cs = '1' and rw = '0') then
			reg_audc1_next <= data_in(3 downto 0);
		end if;		
		
		if (addr = REGADDR_ENAM0 and cs = '1' and rw = '0') then
			reg_enam0_next <= data_in(1);
		end if;

		if (addr = REGADDR_ENAM1 and cs = '1' and rw = '0') then
			reg_enam1_next <= data_in(1);
		end if;

		if (addr = REGADDR_RESMP0 and cs = '1' and rw = '0') then
			reg_resmp0_next <= data_in(1);
		end if;

		if (addr = REGADDR_RESMP1 and cs = '1' and rw = '0') then
			reg_resmp1_next <= data_in(1);
		end if;		
	end process;
	
	read_addr <= addr(3 downto 0);
	
	-- register read access logic
	process (addr, cs, rw)
	begin
		data_out <= "00000000";
		if (read_addr = REGADDR_INPT4) then
			if (input_latch_enable = '1') then
				data_out(7) <= input_latches(0);
			else
				data_out(7) <= i_n(4);
			end if;
		elsif (read_addr = REGADDR_INPT5) then
			if (input_latch_enable = '1') then
				data_out(7) <= input_latches(1);
			else
				data_out(7) <= i_n(5);
			end if;
		-- Collision regs
		elsif (read_addr = REGADDR_CXM0P) then
			data_out(7 downto 6) <= collision_latches(1 downto 0);
		elsif (read_addr = REGADDR_CXM1P) then
			data_out(7 downto 6) <= collision_latches(3 downto 2);
		elsif (read_addr = REGADDR_CXP0FB) then
			data_out(7 downto 6) <= collision_latches(5 downto 4);
		elsif (read_addr = REGADDR_CXP1FB) then
			data_out(7 downto 6) <= collision_latches(7 downto 6);
		elsif (read_addr = REGADDR_CXM0FB) then
			data_out(7 downto 6) <= collision_latches(9 downto 8);
		elsif (read_addr = REGADDR_CXM1FB) then
			data_out(7 downto 6) <= collision_latches(11 downto 10);
		elsif (read_addr = REGADDR_CXBLPF) then
			data_out(7) <= collision_latches(12);
		elsif (read_addr = REGADDR_CXPPMM) then
			data_out(7 downto 6) <= collision_latches(14 downto 13);
		end if;
	end process;
	
	-- latched input ports
	process (i_n, input_latches)
	begin
		input_latches_next <= input_latches;
		input_latch_enable_next <= input_latch_enable;
		
		if (addr = REGADDR_VBLANK and cs = '1' and rw = '0') then
			input_latch_enable_next <= data_in(6);
			if (data_in(6) = '1') then
				input_latches_next <= "11";
			end if;
		else
			if (i_n(4) = '0') then
				input_latches_next(0) <= '0';
			end if;
					
			if (i_n(5) = '0') then
				input_latches_next(1) <= '0';
			end if;
		end if;
	end process;
	
	
	-- playfield
	mirror_pf <= reg_ctrlpf(0);	
	process(reg_pf0, reg_pf1, reg_pf2, hs_counter, mirror_pf)
	begin
		pf_pixel <= '0';
		case hs_counter is
			when "010001" => pf_pixel <= reg_pf0(0);
			when "010010" => pf_pixel <= reg_pf0(1);
			when "010011" => pf_pixel <= reg_pf0(2);
			when "010100" => pf_pixel <= reg_pf0(3);
			when "010101" => pf_pixel <= reg_pf1(7);
			when "010110" => pf_pixel <= reg_pf1(6);
			when "010111" => pf_pixel <= reg_pf1(5);
			when "011000" => pf_pixel <= reg_pf1(4);
			when "011001" => pf_pixel <= reg_pf1(3);
			when "011010" => pf_pixel <= reg_pf1(2);
			when "011011" => pf_pixel <= reg_pf1(1);
			when "011100" => pf_pixel <= reg_pf1(0);
			when "011101" => pf_pixel <= reg_pf2(0);
			when "011110" => pf_pixel <= reg_pf2(1);
			when "011111" => pf_pixel <= reg_pf2(2);
			when "100000" => pf_pixel <= reg_pf2(3);		
			when "100001" => pf_pixel <= reg_pf2(4);
			when "100010" => pf_pixel <= reg_pf2(5);
			when "100011" => pf_pixel <= reg_pf2(6);
			when "100100" => pf_pixel <= reg_pf2(7);
			when others => null;
		end case;
		
		if (mirror_pf = '0') then
			case hs_counter is
				when "100101" => pf_pixel <= reg_pf0(0);
				when "100110" => pf_pixel <= reg_pf0(1);
				when "100111" => pf_pixel <= reg_pf0(2);
				when "101000" => pf_pixel <= reg_pf0(3);
				when "101001" => pf_pixel <= reg_pf1(7);
				when "101010" => pf_pixel <= reg_pf1(6);
				when "101011" => pf_pixel <= reg_pf1(5);
				when "101100" => pf_pixel <= reg_pf1(4);
				when "101101" => pf_pixel <= reg_pf1(3);
				when "101110" => pf_pixel <= reg_pf1(2);
				when "101111" => pf_pixel <= reg_pf1(1);
				when "110000" => pf_pixel <= reg_pf1(0);
				when "110001" => pf_pixel <= reg_pf2(0);
				when "110010" => pf_pixel <= reg_pf2(1);
				when "110011" => pf_pixel <= reg_pf2(2);
				when "110100" => pf_pixel <= reg_pf2(3);
				when "110101" => pf_pixel <= reg_pf2(4);
				when "110110" => pf_pixel <= reg_pf2(5);
				when "110111" => pf_pixel <= reg_pf2(6);
				when "111000" => pf_pixel <= reg_pf2(7);
				when others => null;
			end case;
		else
			case hs_counter is
				when "100101" => pf_pixel <= reg_pf2(7);
				when "100110" => pf_pixel <= reg_pf2(6);
				when "100111" => pf_pixel <= reg_pf2(5);
				when "101000" => pf_pixel <= reg_pf2(4);
				when "101001" => pf_pixel <= reg_pf2(3);
				when "101010" => pf_pixel <= reg_pf2(2);
				when "101011" => pf_pixel <= reg_pf2(1);
				when "101100" => pf_pixel <= reg_pf2(0);
				when "101101" => pf_pixel <= reg_pf1(0);
				when "101110" => pf_pixel <= reg_pf1(1);
				when "101111" => pf_pixel <= reg_pf1(2);
				when "110000" => pf_pixel <= reg_pf1(3);
				when "110001" => pf_pixel <= reg_pf1(4);
				when "110010" => pf_pixel <= reg_pf1(5);
				when "110011" => pf_pixel <= reg_pf1(6);
				when "110100" => pf_pixel <= reg_pf1(7);
				when "110101" => pf_pixel <= reg_pf0(3);
				when "110110" => pf_pixel <= reg_pf0(2);
				when "110111" => pf_pixel <= reg_pf0(1);
				when "111000" => pf_pixel <= reg_pf0(0);
				when others => null;
			end case;
		end if;
			
			
	end process;
	
	motck_ena <= not in_hblank;
	
	p0_data <= reg_grp0 when reg_vdelp0 = '0' else reg_grp0_delayed;
	p1_data <= reg_grp1 when reg_vdelp1 = '0' else reg_grp1_delayed;
	
	p0 : entity work.player port map (
		clk => clk,
		clk_ena => clk_3_5714_ena,
		motck_ena => motck_ena,
		reset => reset,
		reset_strobe => p0_rst_strobe,
		pixel => p0_pixel,
		data => p0_data,
		hm_value => reg_hmp0,
		hm_trigger => hmove_trigger,
		nusiz => reg_nusiz0,
		reflect => reg_refp0,
		missile_reset => p0_missile_reset
	);

	p1 : entity work.player port map (
		clk => clk,
		clk_ena => clk_3_5714_ena,
		motck_ena => motck_ena,
		reset => reset,
		reset_strobe => p1_rst_strobe,
		pixel => p1_pixel,
		data => p1_data,
		hm_value => reg_hmp1,
		hm_trigger => hmove_trigger,
		nusiz => reg_nusiz1,
		reflect => reg_refp1,
		missile_reset => p1_missile_reset
	);
	
	m0 : entity work.missile port map (
		clk => clk,
		clk_ena => clk_3_5714_ena,
		motck_ena => motck_ena,
		reset => reset,
		reset_strobe => m0_rst_strobe,
		pixel => m0_pixel,
		hm_value => reg_hmm0,
		hm_trigger => hmove_trigger,
		nusiz => reg_nusiz0,
		enable => reg_enam0,
		reset_to_player_mode => reg_resmp0,
		reset_to_player_strobe => p0_missile_reset
	);

	m1 : entity work.missile port map (
		clk => clk,
		clk_ena => clk_3_5714_ena,
		motck_ena => motck_ena,
		reset => reset,
		reset_strobe => m1_rst_strobe,
		pixel => m1_pixel,
		hm_value => reg_hmm1,
		hm_trigger => hmove_trigger,
		nusiz => reg_nusiz1,
		enable => reg_enam1,
		reset_to_player_mode => reg_resmp1,
		reset_to_player_strobe => p1_missile_reset
	);

	
	ball_size <= reg_ctrlpf(5 downto 4);

	ball : entity work.ball port map (
		clk => clk,
		clk_ena => clk_3_5714_ena,
		motck_ena => motck_ena,
		reset => reset,
		reset_strobe => ball_rst_strobe,
		pixel => ball_pixel,
		hm_value => reg_hmbl,
		hm_trigger => hmove_trigger,
		size => ball_size,
		enable => reg_enabl
	);
	
	
	
	audio_tick_edge <= '1' when (hs_counter = "000000" and clk_div4 = "00" and clk_3_5714_ena = '1') or
								       (hs_center = '1' and clk_div4 = "00" and clk_3_5714_ena = '1') else '0';
	
	audio_ch0 : entity work.audio port map (
		clk => clk,
		reset => reset,
		clk_ena => audio_tick_edge,
		volume => reg_audv0,
		freq => reg_audf0,
		mode => reg_audc0,
		output => audio_ch0_output
	);
	
	audio_ch1 : entity work.audio port map (
		clk => clk,
		reset => reset,
		clk_ena => audio_tick_edge,
		volume => reg_audv1,
		freq => reg_audf1,
		mode => reg_audc1,
		output => audio_ch1_output
	);
	
	audio <= ("0" & audio_ch0_output) + ("0" & audio_ch1_output);
	
	pf_score_coloring_mode <= '1' when reg_ctrlpf(1) = '1' and reg_ctrlpf(2) = '0' else '0';
	
	-- Graphics priority encoder
	process (reg_colubk, pf_pixel, pf_pixel_color)
	begin
		pixel <= reg_colubk;

		if (reg_ctrlpf(2) = '0') then
			if (pf_pixel = '1' or ball_pixel = '1') then
				if (pf_score_coloring_mode = '0') then
					pixel <= reg_colupf;
				else
					if (past_half = '0') then
						pixel <= reg_colup0;
					else
						pixel <= reg_colup1;
					end if;
				end if;
			end if;
			
			if (p1_pixel = '1' or m1_pixel = '1') then
				pixel <= reg_colup1;
			end if;
			
			if (p0_pixel = '1' or m0_pixel = '1') then
				pixel <= reg_colup0;
			end if;
		else
			if (p1_pixel = '1' or m1_pixel = '1') then
				pixel <= reg_colup1;
			end if;
			
			if (p0_pixel = '1' or m0_pixel = '1') then
				pixel <= reg_colup0;
			end if;
			
			if (pf_pixel = '1' or ball_pixel = '1') then
				if (pf_score_coloring_mode = '0') then
					pixel <= reg_colupf;
				else
					if (past_half = '0') then
						pixel <= reg_colup0;
					else
						pixel <= reg_colup1;
					end if;
				end if;
			end if;
		end if;
	end process;

	
	-- Collision logic
	-- m0-p0 = 0
	-- m0-p1 = 1
	-- m1-p1 = 2
	-- m1-p0 = 3
	-- p0-bl = 4
	-- p0-pf = 5
	-- p1-bl = 6
	-- p1-pf = 7
	-- m0-bl = 8
	-- m0-pf = 9
	-- m1-bl = 10
	-- m1-pf = 11
	-- bl-pf = 12
	-- m0-m1 = 13
	-- p0-p1 = 14
	process (collision_latches, pf_pixel, p0_pixel, p1_pixel)
	begin
		collision_latches_next <= collision_latches;

		if (pf_pixel = '1') then
			if (p0_pixel = '1') then
				collision_latches_next(5) <= '1';
			end if;
			
			if (p1_pixel = '1') then
				collision_latches_next(7) <= '1';
			end if;
			
			if (ball_pixel = '1') then
				collision_latches_next(12) <= '1';
			end if;
		end if;
		
		if (m0_pixel = '1' and p0_pixel = '1') then
			collision_latches_next(0) <= '1';
		end if;

		if (m0_pixel = '1' and p1_pixel = '1') then
			collision_latches_next(1) <= '1';
		end if;

		if (m1_pixel = '1' and p1_pixel = '1') then
			collision_latches_next(2) <= '1';
		end if;
		
		if (m1_pixel = '1' and p0_pixel = '1') then
			collision_latches_next(3) <= '1';
		end if;
		
		if (m0_pixel = '1' and ball_pixel = '1') then
			collision_latches_next(8) <= '1';
		end if;
		
		if (m0_pixel = '1' and pf_pixel = '1') then
			collision_latches_next(9) <= '1';
		end if;
		
		if (m1_pixel = '1' and ball_pixel = '1') then
			collision_latches_next(10) <= '1';
		end if;
		
		if (m1_pixel = '1' and pf_pixel = '1') then
			collision_latches_next(11) <= '1';
		end if;	
		
		if (m0_pixel = '1' and m1_pixel = '1') then
			collision_latches_next(13) <= '1';
		end if;	
		
		if (p0_pixel = '1' and p1_pixel = '1') then
			collision_latches_next(14) <= '1';
		end if;
		
		if (p0_pixel = '1' and ball_pixel = '1') then
			collision_latches_next(4) <= '1';
		end if;

		if (p1_pixel = '1' and ball_pixel = '1') then
			collision_latches_next(6) <= '1';
		end if;
		
		if (addr = REGADDR_CXCLR and cs = '1' and rw = '0') then
			collision_latches_next <= (others => '0');
		end if;
		
	end process;
	
	luma <= pixel(2 downto 0) when blanking = '0' else (others => '0');
	chroma <= pixel(6 downto 3) when blanking = '0' else (others => '0');
	blanking <= '1' when in_hblank = '1' or reg_vblank = '1' else '0';
	comp_sync <= '1' when ((in_hsync = '1' and reg_vsync = '0') or (reg_vsync = '1' and hs_counter < 52)) else '0';
	burst <= hs_burst;
	rdy <= ready_delay(0);
	hsync <= in_hsync;
	vsync <= reg_vsync;
		
	end Behavioral;