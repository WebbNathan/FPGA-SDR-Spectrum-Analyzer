library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity fft_tb is
end entity fft_tb;

architecture sim of fft_tb is
    type sample_array_t is array (0 to 7) of integer;

    constant CLK_PERIOD   : time    := 8 ns; -- 125MHz  
    constant N            : integer := 1024;
    constant DATA_WIDTH   : integer := 32;
    constant LOG_FFT_SIZE : integer := clog2(N);

    constant samples         : sample_array_t := (1, 2, 3, 4, 5, 6, 7, 8);

    signal clk               : std_logic;
    signal reset             : std_logic;

    signal start             : std_logic;
    signal signal_in         : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal in_valid          : std_logic;
    signal fft_RAM_error     : std_logic;
    signal fft_complete      : std_logic;
    signal test_load         : std_logic;
    signal test_addr         : std_logic_vector(LOG_FFT_SIZE -1 downto 0);
    signal test_value        : std_logic_vector(DATA_WIDTH -1 downto 0);

begin
    dut : entity work.fft
        generic map(
            FFT_SIZE  => N,
            DATA_SIZE => DATA_WIDTH 
        )
        port map(
            clk           => clk,
            reset         => reset,

            signal_in     => signal_in,
            
            in_valid      => in_valid,
            test_start    => start,

            fft_RAM_error => fft_RAM_error,
            fft_complete  => fft_complete
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
        reset <= '1';
        start <= '0';

        wait for 2 * CLK_PERIOD;

        wait until falling_edge(clk);
        reset <= '0';

        wait until falling_edge(clk);
        start <= '1';

        wait until falling_edge(clk);
        start <= '0';

        wait;

    end process;

end architecture sim;