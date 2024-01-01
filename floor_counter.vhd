library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity floor_counter is
    generic(
        numberOfFloors : integer := 10;
        bits : integer := 4
    );
    port(
        inc: in std_logic;
        dec: in std_logic;
        clk: in std_logic;
		reset: in std_logic;
        floor_num: out std_logic_vector((bits-1) downto 0)
    );
end floor_counter;

architecture floorCounter of floor_counter is
    signal floor_next: std_logic_vector((bits-1) downto 0);
    signal floor_reg: std_logic_vector((bits-1) downto 0);
begin
    process(clk, reset)
    begin
        if (reset = '0') then
            floor_reg <= (others=>'0');
        else
            if (clk'event and clk='1') then
                floor_reg <= floor_next;
            end if;
        end if;
    end process;
    process(floor_reg, inc, dec)
    begin
        if (inc = '1') then
            if (floor_reg = x"9") then
                floor_next <= floor_reg;
            else
                floor_next <= std_logic_vector((unsigned(floor_reg))+1);
            end if;
        elsif (dec = '1') then
            if (floor_reg = x"0") then
                floor_next <= floor_reg;
            else
                floor_next <= std_logic_vector((unsigned(floor_reg))-1);
            end if;
        else 
            floor_next <= floor_reg;
        end if;
    end process;
    floor_num <= floor_reg;
end floorCounter;