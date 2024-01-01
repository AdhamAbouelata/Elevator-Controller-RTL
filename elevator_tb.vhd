--==================================
-- elevator_tb.vhd HW3 ASIC TESTBENCH
--==================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity elevator_tb is 
-- generics for the number of floors
generic(
    numberOfFloors : integer := 10;
    bits : integer := 4
);
end elevator_tb;

architecture displayTB of elevator_tb is
    component elevator_controller is
        port(
        -- Global Inputs
        clk: in std_logic;
        reset: in std_logic;
        en: in std_logic;
        -- Local Inputs
        in_elevator: in std_logic_vector ((numberOfFloors-1) downto 0); -- pushbutton for each floor inside elevator
        out_elevator_up: in std_logic_vector ((numberOfFloors-1) downto 0); -- pushbutton for each up button outside elevator
        out_elevator_down: in std_logic_vector ((numberOfFloors-1) downto 0); -- pushbutton for each down button outside elevator
        -- Outputs
        up: out std_logic;
        down: out std_logic;
        open_door: out std_logic;
        floors: out std_logic_vector(6 downto 0)
    );
    end component;
    -- internal test signals
        -- Global Inputs
    signal clk   : std_logic := '0'; 
    signal reset : std_logic;
    signal en    : std_logic;
        -- Local Inputs
    signal in_elevator: std_logic_vector ((numberOfFloors-1) downto 0) := (others =>'0');
    signal out_elevator_up: std_logic_vector ((numberOfFloors-1) downto 0):= (others =>'0');
    signal out_elevator_down: std_logic_vector ((numberOfFloors-1) downto 0):= (others =>'0');
    signal buttons_pressed: std_logic_vector ((numberOfFloors-1) downto 0):= (others =>'0');
        -- State Outputs
    signal up: std_logic;
    signal down: std_logic;
    signal open_door: std_logic;
    signal floors: std_logic_vector(6 downto 0);
    -- defining the clock period
    constant period: time := 20 ns;
begin
    -- instantiating the unit under test
    uut: elevator_controller
        port map(
            clk => clk,
            reset => reset,
            en => en,
            in_elevator => in_elevator,
            out_elevator_up => out_elevator_up,
            out_elevator_down => out_elevator_down,
            up => up,
            down => down,
            open_door => open_door,
            floors => floors
        );
    -- Clock Generation
    clk <= not clk after period/2;
    -- For monitoring the button activity
    buttons_pressed <= in_elevator or  out_elevator_up or out_elevator_down;
    -- stimulus
    -- testing scenarios in no particular order:
    -- Normal Operation
    -- 1- Idle to moving
    -- 2- additional requests while going up
    -- 3- additional requests while going down
    -- Corner Cases
    -- 4- down requests while going up
    -- 5- up requests while going down
    process
    alias floor_num is
        <<signal .elevator_tb.uut.inner_floor_count: std_logic_vector((bits-1) downto 0)>>;
    begin
        -- reset
        reset <= '0';
        en <= '0';
        wait for (period);
        -- relinquishing the reset
        reset <= '1';
        en <= '1';
        wait for (period);
        -- test scenario
        out_elevator_up <= "0001000000"; -- request from the 6th floor (case 1)
        wait for (period);
        out_elevator_up <= (others => '0');
        wait until (open_door = '1');
        wait for (30*period);
        out_elevator_down <= "1000100000"; -- up and down requests at 9th and 5th floor  
        wait for (period);
        out_elevator_down <= (others => '0');
        wait until (floor_num = "0111"); -- checking for an up request that is smaller than the current up request (case 2)
        out_elevator_down <= "0100000000";
        wait for (period);
        out_elevator_down <= (others => '0');
        out_elevator_up <= "0000000010"; -- request at the 1st floor while going up (case 4, will be repeated again later to make sure)
        wait for (period);
        out_elevator_up <= (others => '0');
        wait until (floor_num = "0100");
        out_elevator_up <= "0000000100"; -- request at the 2nd floor while going down to the first floor (case 3)
        wait for (period);
        out_elevator_up <= (others => '0');
        wait until (floor_num = "0001");
        in_elevator <= "1000010000"; -- requests at the fourth and ninth floor
        wait for (period);
        in_elevator <= (others => '0');
        wait until (floor_num = "0011");
        out_elevator_up <= "0000000010"; -- request at the first floor before reaching the fourth floor (case 4)
        wait for(period);
        out_elevator_up <= (others => '0');
        wait until (open_door = '1'); -- should be at the fourth floor
        in_elevator <= "0000000001"; -- request to the ground floor
        wait for(period);
        in_elevator <= (others => '0');
        wait until (floor_num = "1001");
        in_elevator <= "0000001001"; -- request to the ground floor and the third floor from the ninth floor
        wait for (period);
        in_elevator <= (others => '0');
        wait until (floor_num = "0101"); -- arbitrary point to test case 5
        out_elevator_down <= "1000000000"; -- request from the ninth floor (case 5)
        wait for (period);
        out_elevator_down <= (others => '0');

        wait;

    end process;
    -- monitoring the elevator activity
    process
        alias combined_request is
            <<signal .elevator_tb.uut.resolver.combined_request: std_logic_vector((numberOfFloors-1) downto 0)>>;
        alias pushed_request is
            <<signal .elevator_tb.uut.request_inner: std_logic_vector((bits-1) downto 0)>>;
        alias floor_num is
            <<signal .elevator_tb.uut.inner_floor_count: std_logic_vector((bits-1) downto 0)>>;
    begin 
        wait on floors;
        write(output, to_string(now, ns) & " requests = " & to_string(combined_request) & LF);
        write(output, to_string(now, ns) & " pushed request = " & to_string(to_integer(unsigned(pushed_request))) & LF);
        if (up = '1') then
            write(output, to_string(now, ns) & " elevator is moving up = " & to_string(to_integer(unsigned(floor_num))) & LF);
        elsif (down = '1') then
            write(output, to_string(now, ns) & " elevator is moving down = " & to_string(to_integer(unsigned(floor_num))) & LF);
        else
            write(output, to_string(now, ns) & " elevator is now at the " & to_string(to_integer(unsigned(floor_num))) & " floor " & LF);
        end if;
    end process;

    --monitoring the requests pressed
    process
    begin
        wait on buttons_pressed;
        if (buttons_pressed > x"000") then
            write(output, to_string(now, ns) & " buttons pressed = " & to_string(buttons_pressed) & LF);
        end if;
    end process;

end displayTB;