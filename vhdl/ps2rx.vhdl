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

entity ps2rx is port (
	clk : in std_logic;			-- clock input, can be anything ~2MHz+
	ps2clk : in std_logic;		-- unsynchronized clock signal from the ps/2 connector
	ps2data : in std_logic;		-- unsynchronized data signal from the ps/2 connector
	data : out std_logic_vector(7 downto 0);		-- received byte
	data_tick : out std_logic );						-- asserted for one clock cycle, indicates new data received
	
end ps2rx;

architecture Behavioral of ps2rx is

signal state_reg, state_reg_next : std_logic_vector(3 downto 0);
signal data_reg : std_logic_vector(7 downto 0);
signal data_shift_en : std_logic;

-- PS2 signals are asynchronous (to the FPGA clock), so they need synchronizers
signal ps2clk_s0, ps2clk_s1, ps2clk_synch, ps2data_s0, ps2data_s1, ps2data_synch : std_logic;

-- Signals for the ps2 clock falling edge detector
signal ps2clk_falling_tick, ps2clk_delay_reg : std_logic;

signal parity_reg : std_logic;

begin
	process (clk)
	begin
		if (clk'event and clk = '1') then
			state_reg <= state_reg_next;

			-- PS2 signal synchronizers
			ps2clk_s0 <= ps2clk;
			ps2clk_s1 <= ps2clk_s0;
			ps2data_s0 <= ps2data;
			ps2data_s1 <= ps2data_s0;
			
			-- 1 cycle delay line for the falling edge detector
			ps2clk_delay_reg <= ps2clk_synch;
			
			if (data_shift_en = '1') then
				data_reg <= ps2data_synch & data_reg(7 downto 1);	-- shift in a new data bit
				parity_reg <= parity_reg xor ps2data_synch;						-- flip parity if data bit is 1
			end if;
			
			if (state_reg = "0000")	then
				parity_reg <= '0';			-- clear the parity reg in the idle state
			end if;
			
				
	
			
		end if;
	end process;
	
	-- Assign outputs of the synchronizers to signals with more descriptive names
	ps2clk_synch <= ps2clk_s1;
	ps2data_synch <= ps2data_s1;

	-- PS2 clock falling edge detector logic
	ps2clk_falling_tick <= '1' when ps2clk_synch = '0' and ps2clk_delay_reg = '1' else '0';
	
	data <= data_reg;
	
	-- State machine logic
	process (ps2clk_falling_tick, state_reg, ps2data_synch, parity_reg)
	begin
		state_reg_next <= state_reg;		-- by default stay in the same state
		data_shift_en <= '0';
		data_tick <= '0';
		
		case state_reg is
			when "0000"	=>		-- idle
				if (ps2clk_falling_tick = '1') then
					if (ps2data_synch = '0') then			-- check that the start bit is 0
						state_reg_next <= "0001";
					end if;
				end if;
				
			when "0001" | "0010" | "0011" | "0100" | "0101" | "0110" | "0111" | "1000" => 	-- data bits
				if (ps2clk_falling_tick = '1') then
					data_shift_en <= '1';				-- shift a bit in this state
					state_reg_next <= state_reg + 1;		-- move to the next state
				end if;
				
			when "1001" =>
				if (ps2clk_falling_tick = '1') then
					if (parity_reg /= ps2data_synch)	then
						state_reg_next <= "1010";			-- there was an even number of 1's 
					else
						state_reg_next <= "0000"; 			-- the idle state can handle the stop bit as an invalid start bit
					end if;
				end if;
				
			when "1010" =>
				if (ps2clk_falling_tick = '1') then
					if (ps2data_synch = '1') then
						state_reg_next <= "1011";
					else
						state_reg_next <= "0000";	-- invalid start bit
					end if;
				end if;
				
			when "1011" =>		-- byte read succesfully 
				data_tick <= '1';
				state_reg_next <= "0000";		-- back to idle state
				
			when others =>
		end case;
	end process;
	
end Behavioral;

