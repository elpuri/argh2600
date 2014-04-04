library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Assumes a left justified 16-bit digital audio interface, the AC97 codec acting as a master

entity ac97_bit_stream_generator is port ( 
	clk : in std_logic;
	reset : in std_logic;
	
	ac97_bclk : in std_logic;
	ac97_daclrck : in std_logic;
	ac97_dacdat : out std_logic;
	
	sample : in std_logic_vector(15 downto 0)
	);
end ac97_bit_stream_generator;

architecture behavioral of ac97_bit_stream_generator is

signal bclk_synch, bclk_synch2 : std_logic; 	-- 2-stage synchronizer for the bit clock
signal lrck_synch, lrck_synch2 : std_logic;		-- 2-stage synchronizer for the lr clock

alias bclk is bclk_synch2;		-- more readable names for the synchronizer outputs
alias lrclk is lrck_synch2;

signal bclk_delay, lrclk_delay : std_logic;		-- delay regs for edge detectors
signal bclk_falling, lrclk_transition : std_logic;

signal bit_counter, bit_counter_next : std_logic_vector(3 downto 0);

signal current_sample, current_sample_next : std_logic_vector(15 downto 0);

begin
	process(clk, reset)
	begin
		if (reset = '1') then
			bclk_synch <= '0'; bclk_synch2 <= '0';
			lrck_synch <= '0'; lrck_synch2 <= '0';
			current_sample <= (others => '0');
			bit_counter <= (others => '0');
			
		elsif (clk'event and clk = '1') then
			-- Synchronizers
			bclk_synch <= ac97_bclk; bclk_synch2 <= bclk_synch;
			lrck_synch <= ac97_daclrck; lrck_synch2 <= lrck_synch;
			
			-- Edge detectors
			bclk_delay <= bclk;
			lrclk_delay <= lrclk;
			
			current_sample <= current_sample_next;
			bit_counter <= bit_counter_next;
			
		end if;
	end process;
	
	bclk_falling <= '1' when bclk_delay = '1' and bclk = '0' else '0';
	lrclk_transition <= '1' when (lrclk_delay = '0' and lrclk = '1') or
								 (lrclk_delay = '1' and lrclk = '0') else '0';
	
	

	process (bit_counter, current_sample, lrclk, lrclk_transition, bclk_falling, sample)
	begin
		current_sample_next <= current_sample;
		bit_counter_next <= bit_counter;
		
		if (lrclk_transition = '1') then
			-- lrclk changed so start transmitting a new byte
			bit_counter_next <= "1111";
			
			-- If this is the rising edge of lrclk store the current sample to a register to make
			-- sure that the sample inputs don't change during transfer and that both channels get the
			-- same sample
			if (lrclk = '1') then
				current_sample_next <= sample;
			end if;
		elsif (bclk_falling = '1') then
			bit_counter_next <= bit_counter - 1;
		end if;
	end process;
	
	ac97_dacdat <= 	current_sample(0) when bit_counter = "0000" else
					current_sample(1) when bit_counter = "0001" else
					current_sample(2) when bit_counter = "0010" else
					current_sample(3) when bit_counter = "0011" else
					current_sample(4) when bit_counter = "0100" else
					current_sample(5) when bit_counter = "0101" else
					current_sample(6) when bit_counter = "0110" else
					current_sample(7) when bit_counter = "0111" else
					current_sample(8) when bit_counter = "1000" else
					current_sample(9) when bit_counter = "1001" else
					current_sample(10) when bit_counter = "1010" else
					current_sample(11) when bit_counter = "1011" else
					current_sample(12) when bit_counter = "1100" else
					current_sample(13) when bit_counter = "1101" else
					current_sample(14) when bit_counter = "1110" else
					current_sample(15);
		
end;