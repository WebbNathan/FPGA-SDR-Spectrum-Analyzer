library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.util_pkg.all;
use work.fir_taps.all;

entity fir_pipeline_tb is
end entity fir_pipeline_tb;

architecture sim of fir_pipeline_tb is
    constant CLK_PERIOD           : time    := 8 ns; -- 125MHz
    constant DATA_WIDTH           : integer := 16;
    constant CIC_N                : integer := 2;
    constant CIC_R_MAX            : integer := 64;
    constant CIC_R                : integer := 64;
    constant CIC_GROWTH           : integer := CIC_N * clog2(CIC_R);
    constant FIR_MOD_1_NUM_TAPS   : integer := 31;
    constant FIR_MOD_2_NUM_TAPS   : integer := 31;
    constant FIR_MOD_1_TAPS       : taps_array(0 to FIR_MOD_1_NUM_TAPS -1);
    constant FIR_MOD_2_TAPS       : taps_array(0 to FIR_MOD_2_NUM_TAPS -1);
    constant FIR_MOD_1_DECIM_RATE : integer := 2;
    constant FIR_MOD_2_DECIM_RATE : integer := 2

    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';

    signal signal_in          : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal signal_out         : std_logic_vector(DATA_WIDTH -1 downto 0);

    signal in_valid           : std_logic;
    signal out_valid          : std_logic;

    signal CIC_decim_rate     : std_logic_vector(clog2(CIC_R_MAX) -1 downto 0);
    signal CIC_gain_shift     : std_logic_vector(clog2(clog2(CIC_R_MAX +1)) -1 downto 0);

    signal FIR_num            : std_logic; -- '0' for 1 filter else '1' for both

    signal branch_error       : std_logic;

    file input_file           : text open read_mode  is "sim/fir_decim_in.txt";
    file output_file          : text open write_mode is "sim/fir_decim_out.txt";    
begin

     -- Device under test
    dut : entity work.filter_pipeline
        generic(
            DATA_WIDTH           => DATA_WIDTH,
            CIC_N                => CIC_N,
            CIC_R_MAX            => CIC_R_MAX,
            FIR_MOD_1_NUM_TAPS   => FIR_MOD_1_NUM_TAPS,
            FIR_MOD_2_NUM_TAPS   => FIR_MOD_2_NUM_TAPS,
            FIR_MOD_1_TAPS       => FIR_MOD_1_TAPS,
            FIR_MOD_2_TAPS       => FIR_MOD_2_TAPS,
            FIR_MOD_1_DECIM_RATE => FIR_MOD_1_DECIM_RATE,
            FIR_MOD_2_DECIM_RATE => FIR_MOD_2_DECIM_RATE
        )
        port(
            clk            => clk,
            reset          => reset,
            signal_in      => signal_in,
            signal_out     => signal_out,
            in_valid       => in_valid,
            out_valid      => out_valid,
            CIC_decim_rate => CIC_decim_rate,
            CIC_gain_shift => CIC_gain_shift,
            FIR_num        => FIR_num,
            branch_error   => branch_error
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

        -- Set control signals
        CIC_decim_rate <= std_logic_vector(to_unsigned(CIC_R, CIC_decim_rate'length));
        CIC_gain_shift <= std_logic_vector(to_unsigned(CIC_GROWTH, CIC_gain_shift'length));

        FIR_num        <= '1';

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