--==================================
-- request_resolver.vhd HW3 ASIC RTL
--==================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity request_resolver is
    generic(
        numberOfFloors : integer := 10;
        bits : integer := 4
    );
    port(
        -- Global Inputs
        clk: in std_logic;
        reset: in std_logic;
        en: in std_logic;
        -- Inputs from UnitControl
        up: in std_logic;
        down: in std_logic;
        open_door: in std_logic;
        floors: in std_logic_vector((bits-1) downto 0);
        -- Local Inputs
        in_elevator: in std_logic_vector ((numberOfFloors-1) downto 0); -- pushbutton for each floor inside elevator
        out_elevator_up: in std_logic_vector ((numberOfFloors-1) downto 0); -- pushbutton for each up button outside elevator
        out_elevator_down: in std_logic_vector ((numberOfFloors-1) downto 0); -- pushbutton for each down button outside elevator
        -- Output 
        request_final: out std_logic_vector ((bits-1) downto 0) -- final resolved request
        
    );
end request_resolver;
architecture req_resolver_arch of request_resolver is
    --===== Request Register
    signal combined_request: std_logic_vector ((numberOfFloors-1) downto 0);
    signal combined_request_next: std_logic_vector ((numberOfFloors-1) downto 0);
    --=====
    --===== Counter signals (to loop over the request register)
    signal loop_counter: std_logic_vector ((bits-1) downto 0);
    signal loop_counter_next: std_logic_vector((bits-1) downto 0);
    signal load: std_logic; -- load with the current floor when necessary
    signal direction: std_logic; -- inc or dec
    --=====
    signal encoded_req: std_logic_vector(9 downto 0); -- ORed input request
    signal request: std_logic_vector((bits-1) downto 0); -- current output of the decoder
    signal pushed_request: std_logic_vector((bits-1) downto 0); -- final output request
    signal push: std_logic; -- enabling the pushing of the next request
    signal was_up: std_logic; -- sampling the up direction for the idle algorithm
    signal was_down: std_logic; -- sampling the down direction for the idle algorithm
    signal dir_reset: std_logic; -- to timeout the values in was_up and was_down if no further up/down requests were found
begin
    process (clk, reset) -- Synchronous element
    begin
        if (reset = '0') then
            loop_counter <= (others=>'0');
        else
            if (clk'event and clk='1' and en = '1') then
                -- manufacturing the rollover at 9 instead of F
                if (loop_counter_next > std_logic_vector(to_unsigned(numberOfFloors-1, bits))) then
                    if (loop_counter_next = x"F") then
                        loop_counter <= std_logic_vector(to_unsigned(numberOfFloors-1, bits));
                    else
                        loop_counter <= x"0";
                    end if;
                else
                    loop_counter <= loop_counter_next;
                end if;
            end if;
        end if;
    end process;
   
    --Combining the requests
    process (clk, reset) 
    begin
        if (reset = '0') then
            combined_request <= (others=>'0');
        else
            if(clk'event and clk='1' and en = '1') then
                combined_request <= combined_request_next;
            end if;
        end if;
    end process;
    -- pushing the output request
    process (clk, reset) 
    begin
        if (reset = '0') then
            pushed_request <= x"F";
        else
            if(clk'event and clk='0' and push = '1') then
                pushed_request <= request;
            end if;
        end if;
    end process;
     -- Sampling directions with timeout
    -- Sampling up
    process(up, dir_reset, reset)
    begin
        if (dir_reset = '0' or reset = '0') then
            was_up <= '0';
        else
            if (up'event and up = '0') then
                was_up <= '1';
            end if;
        end if;
    end process;
    -- sampling down
    process(down, dir_reset, reset)
    begin
        if (dir_reset = '0' or reset = '0') then
            was_down <= '0';
        else
            if (down'event and down = '0') then
                was_down <= '1';
            end if;
        end if;
    end process;
    -- timeout
    process (loop_counter)
    begin
        -- To forget the direction memory if the corner cases of the loop counter are reached (no further up or down request)
            if (loop_counter = std_logic_vector(to_unsigned(numberOfFloors-1, bits)) or loop_counter = x"0") then
                dir_reset <= '0';
            else
                dir_reset <= '1';
            end if;
    end process;
    -- counter next state logic
    process (direction, floors, load, loop_counter)
    begin
        if (load = '1') then
            loop_counter_next <= floors;
        else
            if(direction = '1') then
                loop_counter_next <= std_logic_vector(unsigned(loop_counter)+1);
            else 
                loop_counter_next <= std_logic_vector(unsigned(loop_counter)-1);
            end if;
        end if;
    end process;

    -- Processing an input request
    process(loop_counter, combined_request) -- Scanning the merged input using a counter for the index
    begin
        encoded_req<=(others => '0');
        if (combined_request(to_integer(unsigned(loop_counter))) = '1') then
            encoded_req(to_integer(unsigned(loop_counter))) <= '1'; 
        else 
            encoded_req(to_integer(unsigned(loop_counter))) <= '0';
        end if;
    end process;

    process (encoded_req) --output decoder
    begin
        case encoded_req is
            when "0000000001" =>
                request <= "0000"; --0
            when "0000000010" =>
                request <= "0001"; --1
            when "0000000100" =>
                request <= "0010"; --2
            when "0000001000" =>
                request <= "0011"; --3
            when "0000010000" =>
                request <= "0100"; --4
            when "0000100000" =>
                request <= "0101"; --5
            when "0001000000" =>
                request <= "0110"; --6
            when "0010000000" =>
                request <= "0111"; --7
            when "0100000000" =>
                request <= "1000"; --8
            when "1000000000" =>
                request <= "1001"; --9
            when others =>
                request <= "1111"; -- No request
        end case;
    end process;
    
    -- Processing the next request
    process(up, down, open_door, pushed_request, request, in_elevator, out_elevator_up, out_elevator_down, combined_request, floors, was_up, was_down)
    begin
        combined_request_next <= combined_request or in_elevator or out_elevator_up or out_elevator_down;
    
        if (open_door = '1' and down = '0' and up = '0') then
            load <= '1';
            direction <= '1'; -- doesnt matter as load is asserted
            combined_request_next(to_integer(unsigned(pushed_request))) <= '0'; -- clear current floor from request register
            push <= '0';
        elsif (up = '1' and down = '0' and open_door = '0') then
            direction <= '1';
            load <= '0';
            -- Checking for requests that are below the current request to service first
            if ((request > floors) and (request < pushed_request)) then 
                push <= '1';
            else
                push <= '0';
            end if;
        elsif (up = '0' and down = '1' and open_door = '0') then
            load <= '0';
            direction <= '0';
            -- Checking for requests that are above the current request to service first
            if ((request < floors) and (request > pushed_request)) then
                push <= '1';
            else
                push <= '0';
            end if;
        else
        -- Idle algorithm, If it came here from open_door,the value of the last floor will be loaded
            load <= '0';
            -- If it was up then increment until it reaches the timeout(expressed in another process)
            if (was_up = '1') then
                direction <= '1';
                push <= '1';
            -- Same as above but decrementing if it was down
            elsif (was_down = '1') then
                direction <= '0';
                push <= '1';
            -- If it was completely idle or timeout has been reached, look for any request
            else 
                direction <= '1';
                push <= '1';
            end if;
        end if;   
    end process;
    -- assigning the pushed request to the output request
    request_final <= pushed_request;
end req_resolver_arch;