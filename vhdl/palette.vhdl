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

entity palette is Port ( 
    colu : in std_logic_vector(6 downto 0);
    luma : out std_logic_vector(10 downto 0);
    phase : out std_logic_vector(7 downto 0);
    chroma : out std_logic_vector(2 downto 0)
 );
end palette;

architecture Behavioral of palette is
begin

	luma <=
		conv_std_logic_vector(278, 11) when colu = "0000000" else
		conv_std_logic_vector(454, 11) when colu = "0000001" else
		conv_std_logic_vector(610, 11) when colu = "0000010" else
		conv_std_logic_vector(755, 11) when colu = "0000011" else
		conv_std_logic_vector(895, 11) when colu = "0000100" else
		conv_std_logic_vector(1032, 11) when colu = "0000101" else
		conv_std_logic_vector(1168, 11) when colu = "0000110" else
		conv_std_logic_vector(1301, 11) when colu = "0000111" else
		conv_std_logic_vector(351, 11) when colu = "0001000" else
		conv_std_logic_vector(495, 11) when colu = "0001001" else
		conv_std_logic_vector(628, 11) when colu = "0001010" else
		conv_std_logic_vector(756, 11) when colu = "0001011" else
		conv_std_logic_vector(891, 11) when colu = "0001100" else
		conv_std_logic_vector(1030, 11) when colu = "0001101" else
		conv_std_logic_vector(1166, 11) when colu = "0001110" else
		conv_std_logic_vector(1248, 11) when colu = "0001111" else
		conv_std_logic_vector(340, 11) when colu = "0010000" else
		conv_std_logic_vector(482, 11) when colu = "0010001" else
		conv_std_logic_vector(617, 11) when colu = "0010010" else
		conv_std_logic_vector(750, 11) when colu = "0010011" else
		conv_std_logic_vector(894, 11) when colu = "0010100" else
		conv_std_logic_vector(1031, 11) when colu = "0010101" else
		conv_std_logic_vector(1160, 11) when colu = "0010110" else
		conv_std_logic_vector(1254, 11) when colu = "0010111" else
		conv_std_logic_vector(366, 11) when colu = "0011000" else
		conv_std_logic_vector(455, 11) when colu = "0011001" else
		conv_std_logic_vector(605, 11) when colu = "0011010" else
		conv_std_logic_vector(751, 11) when colu = "0011011" else
		conv_std_logic_vector(894, 11) when colu = "0011100" else
		conv_std_logic_vector(1032, 11) when colu = "0011101" else
		conv_std_logic_vector(1137, 11) when colu = "0011110" else
		conv_std_logic_vector(1231, 11) when colu = "0011111" else
		conv_std_logic_vector(376, 11) when colu = "0100000" else
		conv_std_logic_vector(440, 11) when colu = "0100001" else
		conv_std_logic_vector(603, 11) when colu = "0100010" else
		conv_std_logic_vector(751, 11) when colu = "0100011" else
		conv_std_logic_vector(892, 11) when colu = "0100100" else
		conv_std_logic_vector(1030, 11) when colu = "0100101" else
		conv_std_logic_vector(1129, 11) when colu = "0100110" else
		conv_std_logic_vector(1221, 11) when colu = "0100111" else
		conv_std_logic_vector(396, 11) when colu = "0101000" else
		conv_std_logic_vector(457, 11) when colu = "0101001" else
		conv_std_logic_vector(600, 11) when colu = "0101010" else
		conv_std_logic_vector(750, 11) when colu = "0101011" else
		conv_std_logic_vector(893, 11) when colu = "0101100" else
		conv_std_logic_vector(1030, 11) when colu = "0101101" else
		conv_std_logic_vector(1129, 11) when colu = "0101110" else
		conv_std_logic_vector(1206, 11) when colu = "0101111" else
		conv_std_logic_vector(385, 11) when colu = "0110000" else
		conv_std_logic_vector(448, 11) when colu = "0110001" else
		conv_std_logic_vector(600, 11) when colu = "0110010" else
		conv_std_logic_vector(750, 11) when colu = "0110011" else
		conv_std_logic_vector(894, 11) when colu = "0110100" else
		conv_std_logic_vector(1022, 11) when colu = "0110101" else
		conv_std_logic_vector(1136, 11) when colu = "0110110" else
		conv_std_logic_vector(1216, 11) when colu = "0110111" else
		conv_std_logic_vector(353, 11) when colu = "0111000" else
		conv_std_logic_vector(446, 11) when colu = "0111001" else
		conv_std_logic_vector(606, 11) when colu = "0111010" else
		conv_std_logic_vector(751, 11) when colu = "0111011" else
		conv_std_logic_vector(892, 11) when colu = "0111100" else
		conv_std_logic_vector(1018, 11) when colu = "0111101" else
		conv_std_logic_vector(1139, 11) when colu = "0111110" else
		conv_std_logic_vector(1242, 11) when colu = "0111111" else
		conv_std_logic_vector(326, 11) when colu = "1000000" else
		conv_std_logic_vector(450, 11) when colu = "1000001" else
		conv_std_logic_vector(607, 11) when colu = "1000010" else
		conv_std_logic_vector(753, 11) when colu = "1000011" else
		conv_std_logic_vector(894, 11) when colu = "1000100" else
		conv_std_logic_vector(1023, 11) when colu = "1000101" else
		conv_std_logic_vector(1143, 11) when colu = "1000110" else
		conv_std_logic_vector(1261, 11) when colu = "1000111" else
		conv_std_logic_vector(327, 11) when colu = "1001000" else
		conv_std_logic_vector(448, 11) when colu = "1001001" else
		conv_std_logic_vector(606, 11) when colu = "1001010" else
		conv_std_logic_vector(751, 11) when colu = "1001011" else
		conv_std_logic_vector(894, 11) when colu = "1001100" else
		conv_std_logic_vector(1031, 11) when colu = "1001101" else
		conv_std_logic_vector(1150, 11) when colu = "1001110" else
		conv_std_logic_vector(1263, 11) when colu = "1001111" else
		conv_std_logic_vector(349, 11) when colu = "1010000" else
		conv_std_logic_vector(460, 11) when colu = "1010001" else
		conv_std_logic_vector(606, 11) when colu = "1010010" else
		conv_std_logic_vector(752, 11) when colu = "1010011" else
		conv_std_logic_vector(894, 11) when colu = "1010100" else
		conv_std_logic_vector(1032, 11) when colu = "1010101" else
		conv_std_logic_vector(1165, 11) when colu = "1010110" else
		conv_std_logic_vector(1250, 11) when colu = "1010111" else
		conv_std_logic_vector(355, 11) when colu = "1011000" else
		conv_std_logic_vector(465, 11) when colu = "1011001" else
		conv_std_logic_vector(605, 11) when colu = "1011010" else
		conv_std_logic_vector(753, 11) when colu = "1011011" else
		conv_std_logic_vector(896, 11) when colu = "1011100" else
		conv_std_logic_vector(1031, 11) when colu = "1011101" else
		conv_std_logic_vector(1168, 11) when colu = "1011110" else
		conv_std_logic_vector(1244, 11) when colu = "1011111" else
		conv_std_logic_vector(365, 11) when colu = "1100000" else
		conv_std_logic_vector(456, 11) when colu = "1100001" else
		conv_std_logic_vector(605, 11) when colu = "1100010" else
		conv_std_logic_vector(753, 11) when colu = "1100011" else
		conv_std_logic_vector(894, 11) when colu = "1100100" else
		conv_std_logic_vector(1032, 11) when colu = "1100101" else
		conv_std_logic_vector(1168, 11) when colu = "1100110" else
		conv_std_logic_vector(1237, 11) when colu = "1100111" else
		conv_std_logic_vector(355, 11) when colu = "1101000" else
		conv_std_logic_vector(467, 11) when colu = "1101001" else
		conv_std_logic_vector(606, 11) when colu = "1101010" else
		conv_std_logic_vector(752, 11) when colu = "1101011" else
		conv_std_logic_vector(895, 11) when colu = "1101100" else
		conv_std_logic_vector(1031, 11) when colu = "1101101" else
		conv_std_logic_vector(1166, 11) when colu = "1101110" else
		conv_std_logic_vector(1245, 11) when colu = "1101111" else
		conv_std_logic_vector(327, 11) when colu = "1110000" else
		conv_std_logic_vector(472, 11) when colu = "1110001" else
		conv_std_logic_vector(604, 11) when colu = "1110010" else
		conv_std_logic_vector(753, 11) when colu = "1110011" else
		conv_std_logic_vector(895, 11) when colu = "1110100" else
		conv_std_logic_vector(1033, 11) when colu = "1110101" else
		conv_std_logic_vector(1167, 11) when colu = "1110110" else
		conv_std_logic_vector(1267, 11) when colu = "1110111" else
		conv_std_logic_vector(324, 11) when colu = "1111000" else
		conv_std_logic_vector(472, 11) when colu = "1111001" else
		conv_std_logic_vector(606, 11) when colu = "1111010" else
		conv_std_logic_vector(753, 11) when colu = "1111011" else
		conv_std_logic_vector(895, 11) when colu = "1111100" else
		conv_std_logic_vector(1032, 11) when colu = "1111101" else
		conv_std_logic_vector(1169, 11) when colu = "1111110" else
		conv_std_logic_vector(1270, 11);

	chroma <=
		"111" when colu = "0000000" else
		"111" when colu = "0000001" else
		"111" when colu = "0000010" else
		"111" when colu = "0000011" else
		"111" when colu = "0000100" else
		"111" when colu = "0000101" else
		"111" when colu = "0000110" else
		"111" when colu = "0000111" else
		"000" when colu = "0001000" else
		"000" when colu = "0001001" else
		"000" when colu = "0001010" else
		"000" when colu = "0001011" else
		"001" when colu = "0001100" else
		"010" when colu = "0001101" else
		"011" when colu = "0001110" else
		"011" when colu = "0001111" else
		"000" when colu = "0010000" else
		"000" when colu = "0010001" else
		"000" when colu = "0010010" else
		"000" when colu = "0010011" else
		"001" when colu = "0010100" else
		"010" when colu = "0010101" else
		"011" when colu = "0010110" else
		"100" when colu = "0010111" else
		"000" when colu = "0011000" else
		"000" when colu = "0011001" else
		"001" when colu = "0011010" else
		"010" when colu = "0011011" else
		"011" when colu = "0011100" else
		"011" when colu = "0011101" else
		"100" when colu = "0011110" else
		"101" when colu = "0011111" else
		"000" when colu = "0100000" else
		"000" when colu = "0100001" else
		"010" when colu = "0100010" else
		"011" when colu = "0100011" else
		"011" when colu = "0100100" else
		"100" when colu = "0100101" else
		"101" when colu = "0100110" else
		"110" when colu = "0100111" else
		"000" when colu = "0101000" else
		"000" when colu = "0101001" else
		"001" when colu = "0101010" else
		"010" when colu = "0101011" else
		"011" when colu = "0101100" else
		"100" when colu = "0101101" else
		"100" when colu = "0101110" else
		"101" when colu = "0101111" else
		"000" when colu = "0110000" else
		"000" when colu = "0110001" else
		"001" when colu = "0110010" else
		"010" when colu = "0110011" else
		"011" when colu = "0110100" else
		"100" when colu = "0110101" else
		"101" when colu = "0110110" else
		"110" when colu = "0110111" else
		"000" when colu = "0111000" else
		"000" when colu = "0111001" else
		"010" when colu = "0111010" else
		"010" when colu = "0111011" else
		"011" when colu = "0111100" else
		"100" when colu = "0111101" else
		"101" when colu = "0111110" else
		"111" when colu = "0111111" else
		"000" when colu = "1000000" else
		"001" when colu = "1000001" else
		"010" when colu = "1000010" else
		"011" when colu = "1000011" else
		"100" when colu = "1000100" else
		"100" when colu = "1000101" else
		"101" when colu = "1000110" else
		"111" when colu = "1000111" else
		"000" when colu = "1001000" else
		"000" when colu = "1001001" else
		"010" when colu = "1001010" else
		"011" when colu = "1001011" else
		"011" when colu = "1001100" else
		"100" when colu = "1001101" else
		"101" when colu = "1001110" else
		"110" when colu = "1001111" else
		"000" when colu = "1010000" else
		"000" when colu = "1010001" else
		"001" when colu = "1010010" else
		"011" when colu = "1010011" else
		"011" when colu = "1010100" else
		"100" when colu = "1010101" else
		"100" when colu = "1010110" else
		"101" when colu = "1010111" else
		"000" when colu = "1011000" else
		"000" when colu = "1011001" else
		"001" when colu = "1011010" else
		"011" when colu = "1011011" else
		"100" when colu = "1011100" else
		"100" when colu = "1011101" else
		"101" when colu = "1011110" else
		"101" when colu = "1011111" else
		"000" when colu = "1100000" else
		"000" when colu = "1100001" else
		"010" when colu = "1100010" else
		"011" when colu = "1100011" else
		"100" when colu = "1100100" else
		"100" when colu = "1100101" else
		"101" when colu = "1100110" else
		"101" when colu = "1100111" else
		"000" when colu = "1101000" else
		"000" when colu = "1101001" else
		"000" when colu = "1101010" else
		"010" when colu = "1101011" else
		"011" when colu = "1101100" else
		"011" when colu = "1101101" else
		"100" when colu = "1101110" else
		"101" when colu = "1101111" else
		"000" when colu = "1110000" else
		"000" when colu = "1110001" else
		"000" when colu = "1110010" else
		"010" when colu = "1110011" else
		"011" when colu = "1110100" else
		"100" when colu = "1110101" else
		"100" when colu = "1110110" else
		"101" when colu = "1110111" else
		"000" when colu = "1111000" else
		"000" when colu = "1111001" else
		"000" when colu = "1111010" else
		"010" when colu = "1111011" else
		"011" when colu = "1111100" else
		"100" when colu = "1111101" else
		"100" when colu = "1111110" else
		"101";
	phase <=
		"11010111" when colu = "0000000" else
		"11010111" when colu = "0000001" else
		"11010111" when colu = "0000010" else
		"11010111" when colu = "0000011" else
		"11010111" when colu = "0000100" else
		"11010111" when colu = "0000101" else
		"11010111" when colu = "0000110" else
		"11010111" when colu = "0000111" else
		"00011110" when colu = "0001000" else
		"00001010" when colu = "0001001" else
		"00000110" when colu = "0001010" else
		"00000101" when colu = "0001011" else
		"00000100" when colu = "0001100" else
		"00000100" when colu = "0001101" else
		"00000100" when colu = "0001110" else
		"00000000" when colu = "0001111" else
		"11010110" when colu = "0010000" else
		"11101010" when colu = "0010001" else
		"11110001" when colu = "0010010" else
		"11110100" when colu = "0010011" else
		"11110100" when colu = "0010100" else
		"11110100" when colu = "0010101" else
		"11110101" when colu = "0010110" else
		"00000000" when colu = "0010111" else
		"11010110" when colu = "0011000" else
		"11011101" when colu = "0011001" else
		"11100011" when colu = "0011010" else
		"11100010" when colu = "0011011" else
		"11100010" when colu = "0011100" else
		"11100010" when colu = "0011101" else
		"11100110" when colu = "0011110" else
		"11110000" when colu = "0011111" else
		"11010110" when colu = "0100000" else
		"11001010" when colu = "0100001" else
		"11001011" when colu = "0100010" else
		"11001100" when colu = "0100011" else
		"11001011" when colu = "0100100" else
		"11001011" when colu = "0100101" else
		"11000110" when colu = "0100110" else
		"10110110" when colu = "0100111" else
		"10101101" when colu = "0101000" else
		"10101100" when colu = "0101001" else
		"10101100" when colu = "0101010" else
		"10101100" when colu = "0101011" else
		"10101101" when colu = "0101100" else
		"10101101" when colu = "0101101" else
		"10101100" when colu = "0101110" else
		"10101100" when colu = "0101111" else
		"10010101" when colu = "0110000" else
		"10011100" when colu = "0110001" else
		"10011100" when colu = "0110010" else
		"10011011" when colu = "0110011" else
		"10011011" when colu = "0110100" else
		"10100000" when colu = "0110101" else
		"10101100" when colu = "0110110" else
		"10101100" when colu = "0110111" else
		"10001001" when colu = "0111000" else
		"10010000" when colu = "0111001" else
		"10010000" when colu = "0111010" else
		"10001111" when colu = "0111011" else
		"10001111" when colu = "0111100" else
		"10010011" when colu = "0111101" else
		"10011110" when colu = "0111110" else
		"10101100" when colu = "0111111" else
		"10000001" when colu = "1000000" else
		"10000001" when colu = "1000001" else
		"10000001" when colu = "1000010" else
		"01111111" when colu = "1000011" else
		"10000001" when colu = "1000100" else
		"10000001" when colu = "1000101" else
		"01111110" when colu = "1000110" else
		"10000001" when colu = "1000111" else
		"01111101" when colu = "1001000" else
		"01110000" when colu = "1001001" else
		"01110001" when colu = "1001010" else
		"01110001" when colu = "1001011" else
		"01110001" when colu = "1001100" else
		"01110000" when colu = "1001101" else
		"01101001" when colu = "1001110" else
		"01010101" when colu = "1001111" else
		"01101101" when colu = "1010000" else
		"01100001" when colu = "1010001" else
		"01100000" when colu = "1010010" else
		"01100000" when colu = "1010011" else
		"01100000" when colu = "1010100" else
		"01100000" when colu = "1010101" else
		"01011111" when colu = "1010110" else
		"01010101" when colu = "1010111" else
		"00101010" when colu = "1011000" else
		"01000001" when colu = "1011001" else
		"01000011" when colu = "1011010" else
		"01000011" when colu = "1011011" else
		"01000011" when colu = "1011100" else
		"01000100" when colu = "1011101" else
		"01000011" when colu = "1011110" else
		"01010000" when colu = "1011111" else
		"00101010" when colu = "1100000" else
		"00101010" when colu = "1100001" else
		"00100111" when colu = "1100010" else
		"00100111" when colu = "1100011" else
		"00100111" when colu = "1100100" else
		"00100111" when colu = "1100101" else
		"00100111" when colu = "1100110" else
		"00100101" when colu = "1100111" else
		"00101010" when colu = "1101000" else
		"00100000" when colu = "1101001" else
		"00010100" when colu = "1101010" else
		"00010101" when colu = "1101011" else
		"00010101" when colu = "1101100" else
		"00010101" when colu = "1101101" else
		"00010101" when colu = "1101110" else
		"00001110" when colu = "1101111" else
		"00101010" when colu = "1110000" else
		"00001101" when colu = "1110001" else
		"00000111" when colu = "1110010" else
		"00001000" when colu = "1110011" else
		"00001000" when colu = "1110100" else
		"00001000" when colu = "1110101" else
		"00001000" when colu = "1110110" else
		"00000001" when colu = "1110111" else
		"11101000" when colu = "1111000" else
		"11111001" when colu = "1111001" else
		"11111100" when colu = "1111010" else
		"11111100" when colu = "1111011" else
		"11111100" when colu = "1111100" else
		"11111100" when colu = "1111101" else
		"11111100" when colu = "1111110" else
		"00000000";

end Behavioral;
