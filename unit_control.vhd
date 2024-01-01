--==============================
-- unit_control.vhd HW3 ASIC RTL
--==============================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity unit_control is
    generic(
        numberOfFloors : integer := 10;
        bits : integer := 4
    );
    port(
	    clk: in std_logic;
        reset: in std_logic;
        en: in std_logic;
        request: in std_logic_vector((bits-1) downto 0); 
        up: out std_logic;
        down: out std_logic;
        open_door: out std_logic;
        floors: out std_logic_vector((bits-1) downto 0)
    );
end unit_control;
-- architecture
architecture moore_machine of unit_control is
    type state_type is (Idle, OpenDoor, MovingUp, MovingDown);
    signal state_reg, state_next: state_type; -- for the inferrence of the state register
    signal inc: std_logic;
    signal dec: std_logic;
    signal done: std_logic;
    signal timer_en: std_logic;
    signal floor_num: std_logic_vector((bits-1) downto 0);
    signal open_door_en: std_logic;

    component floor_counter is
        port(
            inc: in std_logic;
            dec: in std_logic;
            clk: in std_logic;
            reset: in std_logic;
            floor_num: out std_logic_vector(3 downto 0)
        );
    end component;
    component timer is
        port(
            clk: in std_logic;
            timer_en: in std_logic;
            reset: in std_logic;
            done: out std_logic
        );
    end component;
    begin
        u1: floor_counter
            port map(
                inc => inc,
                dec => dec,
                clk => clk,
                reset => reset,
                floor_num => floor_num
            );
        u2: timer
            port map(
                clk => clk,
                timer_en => timer_en,
                reset => reset,
                done => done
            );
        process (clk, reset) -- state registers, no reset
        begin
        if (reset = '0') then
            state_reg <= Idle;
        else
            if (clk'event and clk='1' and en = '1' and open_door_en = '1') then
                state_reg <= state_next; 

            end if;
        end if;
        end process;

        process (state_reg, request, floor_num)
        begin
            
            case state_reg is
                when Idle => -- idle state next state logic
                    if ((request>floor_num) and (request<std_logic_vector(to_unsigned(numberOfFloors, bits))))  then   
                        state_next <= MovingUp;
                    elsif ((request<floor_num) and (floor_num > "0000"))then
                        state_next <= MovingDown;
                    elsif (request = floor_num) then
                        state_next <= OpenDoor;                      
                    else
                        state_next <= Idle;
                      
                    end if;
                when OpenDoor => --opendoor state next state logic
                    state_next <= Idle;
                when MovingUp => --movingup next state logic
                    if (unsigned(floor_num) = (unsigned(request))) then
                        state_next <= OpenDoor; 
                        
                    else 
                        state_next <= MovingUp; -- continue moving up 
                    end if;
                when MovingDown => --movingdown
                    if (unsigned(floor_num) = (unsigned(request))) then
                        state_next <= OpenDoor;
                        
                    else 
                        state_next <= MovingDown; -- continue moving down 
                    end if;
                when others => 
                    state_next <= Idle; -- idle is default state, this will never happen
            end case;
        end process;
    -- state output logic
        process (state_reg, done)
        begin
            open_door_en <= '1';
            case state_reg is
                when Idle => -- idle outputs
                    up <= '0';
                    down <= '0';
                    inc <= '0';
                    dec <= '0';
                    open_door <= '0';
                    timer_en <= '0';
                when OpenDoor => -- opendoor outputs
                    timer_en <= '1'; 
                    if (done = '1') then
                        up <= '0';
                        down <= '0';
                        inc <= '0';
                        dec <= '0';
                        open_door <= '1'; 
                        open_door_en <= '1';
                    else
                        up <= '0';
                        down <= '0';
                        inc <= '0';
                        dec <= '0';
                        open_door <= '1'; 
                        open_door_en <= '0';
                    end if;

                when MovingUp => -- movingup outputs
                    timer_en <= '1';
                    if(done = '1')then
                        up <= '1';
                        down <= '0';
                        inc <= '1';
                        dec <= '0';
                        open_door <= '0';  
                    else
                        up <= '1';
                        down <= '0';
                        inc <= '0';
                        dec <= '0';
                        open_door <= '0';  
                    end if;
                when MovingDown => --movingdown outputs
                    timer_en <= '1';
                    if(done = '1')then
                        up <= '0';
                        down <= '1';
                        inc <= '0';
                        dec <= '1';
                        open_door <= '0';  
                    else
                        up <= '0';
                        down <= '1';
                        inc <= '0';
                        dec <= '0';
                        open_door <= '0'; 
                    end if; 
                when others => -- Not needed, but included to make sure
                    up <= '0';
                    down <= '0';
                    inc <= '0';
                    dec <= '0';
                    open_door <= '0'; 
                    timer_en <= '0'; 
            end case;
        end process;
		floors <= floor_num;
end moore_machine;  