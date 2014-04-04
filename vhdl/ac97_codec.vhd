library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ac97_codec is port ( 
	clk_50 : in std_logic;
	clk_17 : in std_logic;
	
	reset : in std_logic;
	
	sample : in std_logic_vector(15 downto 0);
	
	ac97_xck : out std_logic;
	ac97_bclk : in std_logic;
	ac97_daclrck : in std_logic;
	ac97_dacdat : out std_logic;
	
	init_complete : out std_logic;
	init_error : out std_logic;
	
	i2c_sclk : out std_logic;
	i2c_sdat : inout std_logic
	);
end ac97_codec;
	
	
architecture behavioral of ac97_codec is

-- Reset signals for the bit stream generator and initializer
signal reset_stream : std_logic;

-- Internal versions of init_complete and init_error signals, because VHDL doesn't allow
-- using output pins in statements
signal init_complete_internal : std_logic;
signal init_error_internal : std_logic;

-- PLL signals
signal pll_locked : std_logic;
signal clk_16m934 : std_logic;

begin
	
	ac97_xck <= clk_17;
		
	streamer : work.ac97_bit_stream_generator port map (
		clk => clk_50,
		reset => reset_stream,
		sample => sample,
		ac97_bclk => ac97_bclk,
		ac97_daclrck => ac97_daclrck,
		ac97_dacdat => ac97_dacdat );
		
	initializer : work.ac97_init port map (
		clk_50 => clk_50,
		reset => reset,
		
		init_complete => init_complete_internal,
		init_error => init_error_internal,
		
		i2c_sclk => i2c_sclk,
		i2c_sdat => i2c_sdat );
				
	-- Hold stream generator in reset while init is not complete or there was an error
	-- init_complete will be low if external reset is applied to the initializer
	reset_stream <= not init_complete_internal or init_error_internal;
	

	init_complete <= init_complete_internal;
	init_error <= init_error_internal;
	
end behavioral;