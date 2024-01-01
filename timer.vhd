--==============================
-- timer.vhd HW3 ASIC RTL
--==============================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity timer is 
    port(
        clk: in std_logic;
        timer_en: in std_logic;
        reset: in std_logic;
        done: out std_logic
);
end timer;

architecture behavioral of timer is
    --signal counter_reg: std_logic_vector(26 downto 0);
    --signal counter_next: std_logic_vector(26 downto 0);
    signal counter_reg: std_logic_vector(6 downto 0);
    signal counter_next: std_logic_vector(6 downto 0);
begin
    process(clk, reset)
    begin
        if (reset = '0') then
            counter_reg <= (others=>'0');
        else
            if (clk'event and clk='1' and timer_en = '1') then
                counter_reg <= counter_next; 

            end if;
        end if;
    end process;
    process(counter_reg)
    begin
        --if (counter_reg < "101111101011110000100000000") then This is commented so anyone can run the code without questa crashing
        if (counter_reg < "1111") then
            counter_next <= std_logic_vector((unsigned(counter_reg))+1);
            done <= '0';
        else
            counter_next <= (others =>'0');
            done <= '1';
        end if;
    end process;
end behavioral;