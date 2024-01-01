--==================================
-- elevator_controller.vhd HW3 ASIC RTL
--==================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity elevator_controller is
    generic(
        numberOfFloors : integer := 10;
        halfwayPoint : integer := 4;
        HPwidth : integer := 3;
        bits : integer := 4
    );
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
        floors: out std_logic_vector(6 downto 0) -- for seven segment display
    );
end elevator_controller;
architecture rtl_elevator_controller of elevator_controller is
component unit_control is
    port(
        -- Global Inputs
        clk: in std_logic;
        reset: in std_logic;
        en: in std_logic;
        -- Local Inputs
        request: in std_logic_vector((bits-1) downto 0); -- From request_resolver
        -- State Outputs
        up: out std_logic;
        down: out std_logic;
        open_door: out std_logic;
        -- Current Floor
        floors: out std_logic_vector((bits-1) downto 0)
    );
end component;  
component request_resolver is
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
end component;
component ssd_decoder is
	port (
		BCD_in: in std_logic_vector(3 downto 0);
		SSD_out: out std_logic_vector(6 downto 0)
	);
end component;
signal up_inner: std_logic;
signal down_inner: std_logic;
signal open_door_inner: std_logic;
signal request_inner: std_logic_vector((bits-1) downto 0);
signal enable: std_logic;
signal inner_floor_count: std_logic_vector((bits-1) downto 0);
begin
    ssd: ssd_decoder
        port map(
            BCD_in => inner_floor_count,
            SSD_out => floors
        );
    fsm: unit_control
        port map(
            clk => clk,
            reset => reset,
            en => en,
            request => request_inner,
            up => up_inner,
            down => down_inner,
            open_door => open_door_inner,
            floors => inner_floor_count
    );

    resolver: request_resolver
        port map( 
            clk => clk,
            reset => reset,
            en => en,
            up => up_inner,
            down => down_inner,
            open_door => open_door_inner,
            floors => inner_floor_count,
            in_elevator => in_elevator,
            out_elevator_up => out_elevator_up,
            out_elevator_down => out_elevator_down,
            request_final => request_inner
    );
    up <= up_inner;
    down <= down_inner;
    open_door <= open_door_inner;
end rtl_elevator_controller;