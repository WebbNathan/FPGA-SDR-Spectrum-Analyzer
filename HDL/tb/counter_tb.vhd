library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity counter_tb is
end entity counter_tb;

architecture sim of counter_tb is
    constant CLK_PERIOD : time    := 8 ns; -- 125MHz  
    constant N          : integer := 1024;
    constant LOG_N      : integer := 10;

    signal clk          : std_logic;
    signal reset        : std_logic;

    signal pulse_in     : std_logic;
    signal pulse_out    : std_logic;

    signal i_out        : std_logic_vector(clog2(LOG_N + 1) -1 downto 0);
    signal j_out        : std_logic_vector(clog2(N/2) -1 downto 0); 
begin
    dut : entity work.counter
        generic map(
            N     => N,
            LOG_N => LOG_N
        )
        port map(
            clk       => clk,
            reset     => reset,
            
            pulse_in  => pulse_in,
            pulse_out => pulse_out,

            i_out     => i_out,
            j_out     => j_out
        );

    -- Clock generator
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Input stimulus
    stimulus_proc : process
    begin

        -- Hold reset active
        reset         <= '1';
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        while true loop
            pulse_in <= '1';
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            pulse_in <= '0';
            wait for 10 * CLK_PERIOD;
        end loop;

    end process;

end architecture sim;