library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ac97_init is port ( 
	clk_50 : in std_logic;
	reset : in std_logic;
		
	init_complete : out std_logic;
	init_error : out std_logic;
	
	i2c_sclk : out std_logic;
	i2c_sdat : inout std_logic
	);
	
end ac97_init;

architecture behavioral of ac97_init is

-- Data signals from the initialization data LUT
signal init_data : std_logic_vector(15 downto 0); 	

-- Address register and its next state logic signal for the initialization data LUT
signal init_address, init_address_next : std_logic_vector(3 downto 0);

-- Address of the AC97 codec on Terasic DE2 board
constant i2c_address : std_logic_vector(7 downto 0) := x"34";

-- Initializer state register and next state logic signal
signal state, state_next : std_logic_vector(6 downto 0);

-- A counter used to divide the 50MHz clock to produce an enable signal for the state machine
signal clk_divider_counter : std_logic_vector(8 downto 0);

-- A 100kHz enable tick used to drive the state machine
signal i2c_tick : std_logic;		-- ~100 kHz

-- Register i2c clock and data to avoid glitches. This is very important because for example any glitches in 
-- the data signal are interpreted as start or stop conditions by the slave if they happen when the 
-- clock is high.
signal i2c_di, i2c_do, i2c_do_regged: std_logic;
signal i2c_clk_regged, i2c_clk : std_logic;		

-- Control signal for the output pin 3-state buffer
signal i2c_dir : std_logic;					

signal data_shift_reg, data_shift_reg_next : std_logic_vector(15 downto 0);	
signal bang_done_tick : std_logic;
signal shift_data_tick : std_logic;

begin


	-- Asynchronous reset logic and registers
	-- The FSM state and initialization LUT address pointer are updated only 
	-- when i2c_tick is asseted (~100kHz)
	process(clk_50, reset)
	begin
		if (reset = '1') then
			state <= "1111000";
			clk_divider_counter <= (others => '0');
			init_address <= (others => '0');
		elsif (clk_50'event and clk_50 = '1') then
			clk_divider_counter <= clk_divider_counter + 1;
			i2c_do_regged <= i2c_do;
			i2c_clk_regged <= i2c_clk;
			
			if (i2c_tick = '1') then
				state <= state_next;
				init_address <= init_address_next;
				data_shift_reg <= data_shift_reg_next;

			end if;
		end if;
	end process;

	-- Tri-state logic for the i2c data inout pin
	i2c_sdat <= i2c_do_regged when i2c_dir = '1' else 'Z';
	i2c_di <= i2c_sdat;		
	
	-- Assign the registered (to avoid glitches) i2c clock to the output pin
	i2c_sclk <= i2c_clk_regged;		
				
	-- Generate tick every time the counter resets			 
	i2c_tick <= '1' when clk_divider_counter = 0 else '0'; 
				 
	-- Initialization data LUT for the WM8731 AC97 codec
	-- Format "xxyy"
	-- xx = 7-bit register number + most significant data bit
	-- yy = 8 less significant data bits
	init_data <= 	-- Reset
					x"1e00" when init_address = "0000" else	
					
					-- Audio interface format
					-- Left justified, 16 bits per channel, codec acts as the master
					x"0e41" when init_address = "0001" else		
					
					-- Analog audio path control
					-- DAC selected, no line-in or mic mixing
					x"0810" when init_address = "0010" else
					
					-- Sampling control
					-- 16.934MHz clock, 44.1kHz sampling
					x"1022" when init_address = "0011" else		
					
					-- Digital audio path control
					-- Disable soft mute
					x"0a00" when init_address = "0100" else
					
					-- Right line-in control
					-- 0dB amplification, mute off
					x"0217" when init_address = "0101" else
					
					-- Left headphone/line-out control
					x"04f0" when init_address = "0110" else
					
					-- Right headphone/line-out control
					x"06f0" when init_address = "0111" else
					
					-- Power down control
					-- Everything powered up
					x"0c00" when init_address = "1000" else
					
					-- Active control
					-- Set the codec active
					x"1201" when init_address = "1001" else 
					
					-- Left line-in control
					-- 0dB amplification, mute off
					x"0017" when init_address = "1010" else (others => 'X');



	-- Combinatorial logic for complete and error signals
	init_complete <= '1' when state = "1111110" else '0';
	init_error <= '1' when state = "1111111" else '0';

	
	-- Bangin' logic
	

	-- Next state logic and moore outputs
	process(state, init_data, init_address, i2c_di)
	begin
		state_next <= state + 1;	-- by default move to the next state
		i2c_dir <= '1';				-- by default output
		init_address_next <= init_address;
		
		-- This is embarrassingly bad, but I had some problem with the FSM and
		-- wanted to be as explicit as possible and now I'm too lazy to make it nice and compact.
		case state is
			-- Idle 
			when "0000000" => i2c_clk <= '1'; i2c_do <= '1'; 	-- Idle
			
			-- Start condition
			when "0000001" => i2c_clk <= '1'; i2c_do <= '0';     
			when "0000010" => i2c_clk <= '0'; i2c_do <= '0'; 	
			
			-- Bang in address and R/W (included in the i2c_address signal)
			when "0000011" => i2c_clk <= '0'; i2c_do <= i2c_address(7);	
			when "0000100" => i2c_clk <= '0'; i2c_do <= i2c_address(7);		-- bugi bugi
			when "0000101" => i2c_clk <= '1'; i2c_do <= i2c_address(7);				
			when "0000110" => i2c_clk <= '0'; i2c_do <= i2c_address(7);	
			when "0000111" => i2c_clk <= '0'; i2c_do <= i2c_address(6);				
			when "0001000" => i2c_clk <= '1'; i2c_do <= i2c_address(6);				
			when "0001001" => i2c_clk <= '0'; i2c_do <= i2c_address(6);	
			when "0001010" => i2c_clk <= '0'; i2c_do <= i2c_address(5);				
			when "0001011" => i2c_clk <= '1'; i2c_do <= i2c_address(5);				
			when "0001100" => i2c_clk <= '0'; i2c_do <= i2c_address(5);	
			when "0001101" => i2c_clk <= '0'; i2c_do <= i2c_address(4);				
			when "0001110" => i2c_clk <= '1'; i2c_do <= i2c_address(4);				
			when "0001111" => i2c_clk <= '0'; i2c_do <= i2c_address(4);	
			when "0010000" => i2c_clk <= '0'; i2c_do <= i2c_address(3);				
			when "0010001" => i2c_clk <= '1'; i2c_do <= i2c_address(3);				
			when "0010010" => i2c_clk <= '0'; i2c_do <= i2c_address(3);	
			when "0010011" => i2c_clk <= '0'; i2c_do <= i2c_address(2);				
			when "0010100" => i2c_clk <= '1'; i2c_do <= i2c_address(2);				
			when "0010101" => i2c_clk <= '0'; i2c_do <= i2c_address(2);	
			when "0010110" => i2c_clk <= '0'; i2c_do <= i2c_address(1);				
			when "0010111" => i2c_clk <= '1'; i2c_do <= i2c_address(1);				
			when "0011000" => i2c_clk <= '0'; i2c_do <= i2c_address(1);	
			when "0011001" => i2c_clk <= '0'; i2c_do <= i2c_address(0);				
			when "0011010" => i2c_clk <= '1'; i2c_do <= i2c_address(0);	state_next <= "0011100";
			when "0011011" => i2c_clk <= '1'; i2c_do <= i2c_address(0);		 -- bugi bugi		
			when "0011100" => i2c_clk <= '0'; i2c_do <= i2c_address(0); 
			
			-- Check ACK
			when "0011101" => i2c_clk <= '1'; i2c_dir <= '0'; i2c_do <= '0';		-- direction is in, so "do" is don't care
						
							
			
			-- Issue a i2c cycle so that the slave releases the data line
			when "0011110" => i2c_clk <= '1'; i2c_dir <= '0'; i2c_do <= '0';
						        if (i2c_di = '1') then 
								 state_next <= "1111111";		-- go to error state
							  end if;
							  
			when "0011111" => i2c_clk <= '0'; i2c_do <= 'X';
			
			-- Send register (8 bits)
			when "0100000" => i2c_clk <= '0'; i2c_do <= init_data(15);	
			when "0100001" => i2c_clk <= '1'; i2c_do <= init_data(15);				
			when "0100010" => i2c_clk <= '0'; i2c_do <= init_data(15);	
			when "0100011" => i2c_clk <= '0'; i2c_do <= init_data(14);				
			when "0100100" => i2c_clk <= '1'; i2c_do <= init_data(14);				
			when "0100101" => i2c_clk <= '0'; i2c_do <= init_data(14);	
			when "0100110" => i2c_clk <= '0'; i2c_do <= init_data(13);				
			when "0100111" => i2c_clk <= '1'; i2c_do <= init_data(13);				
			when "0101000" => i2c_clk <= '0'; i2c_do <= init_data(13);	
			when "0101001" => i2c_clk <= '0'; i2c_do <= init_data(12);				
			when "0101010" => i2c_clk <= '1'; i2c_do <= init_data(12);				
			when "0101011" => i2c_clk <= '0'; i2c_do <= init_data(12);	
			when "0101100" => i2c_clk <= '0'; i2c_do <= init_data(11);				
			when "0101101" => i2c_clk <= '1'; i2c_do <= init_data(11);				
			when "0101110" => i2c_clk <= '0'; i2c_do <= init_data(11);	
			when "0101111" => i2c_clk <= '0'; i2c_do <= init_data(10);				
			when "0110000" => i2c_clk <= '1'; i2c_do <= init_data(10);				
			when "0110001" => i2c_clk <= '0'; i2c_do <= init_data(10);	
			when "0110010" => i2c_clk <= '0'; i2c_do <= init_data(9);				
			when "0110011" => i2c_clk <= '1'; i2c_do <= init_data(9);				
			when "0110100" => i2c_clk <= '0'; i2c_do <= init_data(9);	
			when "0110101" => i2c_clk <= '0'; i2c_do <= init_data(8);				
			when "0110110" => i2c_clk <= '1'; i2c_do <= init_data(8);				
			when "0110111" => i2c_clk <= '0'; i2c_do <= init_data(8); 
			
			-- Check ACK
			when "0111000" => i2c_clk <= '1'; i2c_dir <= '0'; i2c_do <= '0';		-- direction is in, so "do" is don't care
							  
			
			-- Issue a i2c cycle so that the slave releases the data line
			when "0111001" => i2c_clk <= '1'; i2c_dir <= '0'; i2c_do <= '0';
							if (i2c_di = '1') then 
								 state_next <= "1111111";		-- go to error state
							  end if;
			when "0111010" => i2c_clk <= '0'; i2c_do <= 'X';
			
			-- Send data (8 bits)
			when "0111011" => i2c_clk <= '0'; i2c_do <= init_data(7);	
			when "0111100" => i2c_clk <= '1'; i2c_do <= init_data(7);				
			when "0111101" => i2c_clk <= '0'; i2c_do <= init_data(7);	
			when "0111110" => i2c_clk <= '0'; i2c_do <= init_data(6);				
			when "0111111" => i2c_clk <= '1'; i2c_do <= init_data(6);				
			when "1000000" => i2c_clk <= '0'; i2c_do <= init_data(6);	
			when "1000001" => i2c_clk <= '0'; i2c_do <= init_data(5);				
			when "1000010" => i2c_clk <= '1'; i2c_do <= init_data(5);				
			when "1000011" => i2c_clk <= '0'; i2c_do <= init_data(5);	
			when "1000100" => i2c_clk <= '0'; i2c_do <= init_data(4);				
			when "1000101" => i2c_clk <= '1'; i2c_do <= init_data(4);				
			when "1000110" => i2c_clk <= '0'; i2c_do <= init_data(4);	
			when "1000111" => i2c_clk <= '0'; i2c_do <= init_data(3);				
			when "1001000" => i2c_clk <= '1'; i2c_do <= init_data(3);				
			when "1001001" => i2c_clk <= '0'; i2c_do <= init_data(3);	
			when "1001010" => i2c_clk <= '0'; i2c_do <= init_data(2);				
			when "1001011" => i2c_clk <= '1'; i2c_do <= init_data(2);				
			when "1001100" => i2c_clk <= '0'; i2c_do <= init_data(2);	
			when "1001101" => i2c_clk <= '0'; i2c_do <= init_data(1);				
			when "1001110" => i2c_clk <= '1'; i2c_do <= init_data(1);				
			when "1001111" => i2c_clk <= '0'; i2c_do <= init_data(1);	
			when "1010000" => i2c_clk <= '0'; i2c_do <= init_data(0);				
			when "1010001" => i2c_clk <= '1'; i2c_do <= init_data(0);				
			when "1010010" => i2c_clk <= '0'; i2c_do <= init_data(0); 
											
			-- Check ACK
			when "1010011" => i2c_clk <= '0'; i2c_dir <= '1'; i2c_do <= '0';		-- direction is in, so "do" is don't care
							  
							 
			-- Issue a i2c cycle so that the slave releases the data line
			when "1010100" => i2c_clk <= '1'; i2c_dir <= '0'; i2c_do <= '0';
						if (i2c_di = '1') then 
								 state_next <= "1111111";		-- go to error state
							  end if;
			when "1010101" => i2c_clk <= '0'; i2c_do <= '0';		
			
			-- Issue STOP condition
			when "1010110" => i2c_clk <= '0'; i2c_do <= '0';
			when "1010111" => i2c_clk <= '1'; i2c_do <= '0';
			when "1011000" => i2c_clk <= '1'; i2c_do <= '1';
			
			-- Check if this was the last byte, if yes go to completed state, 
			-- if not increase address and go to first state
			
			when "1011001" => if (init_address = "1010") then 
						   		 state_next <= "1111110";		-- go to completed state
							  else
								 init_address_next <= init_address + 1;
								 state_next <= "0000000";
							  end if;
							  i2c_clk <= '1'; i2c_do <= '1';	-- stay in STOP condition
			
			when "1111111" => state_next <= "1111111";
							  i2c_clk <= '1'; i2c_do <= '1';	-- stay in STOP condition
							  
			when "1111110" => state_next <= "1111110";
							  i2c_clk <= '1'; i2c_do <= '1';	-- stay in STOP condition
							  
			-- Initial state:
			-- Generate stop condition and jump to the "original initial state"				  
			when "1111000" => i2c_clk <= '1'; i2c_do <= '0';
			when "1111001" => i2c_clk <= '1'; i2c_do <= '0';
			when "1111010" => i2c_clk <= '1'; i2c_do <= '1'; state_next <= "0000000";
			
			when others => state_next <= "1111100";
							  i2c_clk <= '1'; i2c_do <= '1';	-- stay in STOP condition
				
		end case;				 
	end process;

end behavioral;
