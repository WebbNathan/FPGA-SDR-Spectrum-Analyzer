library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.util_pkg.all;
use work.fir_taps.all;

entity fir_decim_tb is
end entity fir_decim_tb;

architecture sim of fir_decim_tb is
    constant CLK_PERIOD       : time    := 8 ns; -- 125MHz
    constant DATA_WIDTH       : integer := 16;
    constant NUM_TAPS         : integer := 31;
    constant TAPS             : taps_array(0 to NUM_TAPS -1) := load_taps(
                                                                "sim/fir_decim_taps.txt",
                                                                NUM_TAPS);
                                                                
    constant DECIM_FACTOR     : integer := 4;
    constant R_WIDTH          : natural := clog2(DECIM_FACTOR);

    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';

    signal signal_in          : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal signal_out         : std_logic_vector(DATA_WIDTH -1 downto 0);

    signal in_valid           : std_logic;
    signal out_valid          : std_logic;

    file input_file           : text open read_mode  is "sim/fir_decim_in.txt";
    file output_file          : text open write_mode is "sim/fir_decim_out.txt";    
begin

     -- Device under test
    dut : entity work.fir_decim
        generic map (
            DATA_WIDTH   => DATA_WIDTH,
            NUM_TAPS     => NUM_TAPS,
            TAPS         => TAPS,
            DECIM_FACTOR => DECIM_FACTOR
        )
        port map (
            clk           => clk,
            reset         => reset,
            signal_in     => signal_in,
            signal_out    => signal_out,
            in_valid      => in_valid,
            out_valid     => out_valid
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
        variable input_line : line;
        variable sample_int : integer;
    begin

        -- Hold reset active
        reset         <= '1';
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        while not endfile(input_file) loop

            readline(input_file, input_line);
            read(input_line, sample_int);

            signal_in <= std_logic_vector(to_signed(sample_int, signal_in'length));
            in_valid  <= '1';

            wait until rising_edge(clk);

        end loop;

        in_valid <= '0';

        wait;
    end process;

    output_proc : process(clk)
        variable output_line : line;
    begin
        if rising_edge(clk) then

            if out_valid = '1' then

                write(output_line, to_integer(signed(signal_out)));

                writeline(output_file, output_line);

            end if;

        end if;
    end process;

end architecture;