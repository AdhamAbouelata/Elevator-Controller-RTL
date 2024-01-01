--=============================
-- SSD decoder
--=============================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity declaration

entity ssd_decoder is 
	port (
		BCD_in: in std_logic_vector(3 downto 0);
		SSD_out: out std_logic_vector(6 downto 0)
	);
end ssd_decoder;

--architecture

architecture ssd_4bit of ssd_decoder is
begin
	process(BCD_in)
	begin
		case BCD_in is
         when "0000" =>
            SSD_out <= "0000001"; --0
			when "0001" =>
				SSD_out <= "1001111"; --1
			when "0010" =>
				SSD_out <= "0010010"; --2
			when "0011" =>
				SSD_out <= "0000110"; --3
			when "0100" =>
				SSD_out <= "1001100"; --4
			when "0101" =>
				SSD_out <= "0100100"; --5
			when "0110" =>
				SSD_out <= "0100000"; --6
			when "0111" =>
				SSD_out <= "0001111"; --7
			when "1000" =>
				SSD_out <= "0000000"; --8
			when "1001" =>
				SSD_out <= "0000100"; --9
			when others =>
				SSD_out <= "0000001"; --to ensure comb synthesis
			end case;
	end process;
end ssd_4bit;