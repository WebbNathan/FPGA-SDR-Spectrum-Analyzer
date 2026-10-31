library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity get_twiddle_tb is
end entity get_twiddle_tb;

architecture sim of get_twiddle_tb is
    constant CLK_PERIOD : time    := 8 ns; -- 125MHz  
    constant N          : integer := 1024;
    constant LOG_N      : integer := 10;
    constant I_WIDTH    : integer := clog2(LOG_N + 1);
    constant J_WIDTH    : integer := clog2(N/2);
    constant FFT_SIZE   : integer := 1024;
    constant DATA_WIDTH : integer := 32;

    signal clk               : std_logic;
    signal reset             : std_logic;

    signal pulse_twiddle_in  : std_logic;
    signal pulse_counter_in  : std_logic;

    signal pulse_twiddle_out : std_logic;
    signal pulse_counter_out : std_logic;

    signal i_counter_out     : std_logic_vector(I_WIDTH -1 downto 0);
    signal j_counter_out     : std_logic_vector(J_WIDTH -1 downto 0);

    signal i_twiddle_in      : std_logic_vector(I_WIDTH -1 downto 0);
    signal j_twiddle_in      : std_logic_vector(J_WIDTH -1 downto 0); 

    signal twiddle_out       : std_logic_vector(DATA_WIDTH -1 downto 0);
begin
    dut : entity work.get_twiddle
        generic map(
            I_WIDTH    => I_WIDTH,
            J_WIDTH    => J_WIDTH,
            FFT_SIZE   => FFT_SIZE,
            DATA_WIDTH => DATA_WIDTH
        )
        port map(
            clk         => clk,
            reset       => reset,
            
            pulse_in    => pulse_twiddle_in,
            pulse_out   => pulse_twiddle_out,

            i           => i_twiddle_in,
            j           => j_twiddle_in,

            twiddle     => twiddle_out
        );

    -- Using counter to test the twiddle. Counter has it's own seperate TB
    util : entity work.counter
        generic map(
            N     => N,
            LOG_N => LOG_N
        )
        port map(
            clk       => clk,
            reset     => reset,
            
            pulse_in  => pulse_counter_in,
            pulse_out => pulse_counter_out,

            i_out     => i_counter_out,
            j_out     => j_counter_out
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
            pulse_counter_in <= '1';
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            pulse_counter_in <= '0';
            wait for 10 * CLK_PERIOD;
        end loop;

    end process;

    pulse_twiddle_in <= pulse_counter_out;
    i_twiddle_in     <= i_counter_out;
    j_twiddle_in     <= j_counter_out;  

end architecture sim;