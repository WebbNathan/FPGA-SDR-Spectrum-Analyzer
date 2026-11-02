library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library work;
use work.util_pkg.all;

entity spectrum_analyzer_tb is
end entity spectrum_analyzer_tb;

architecture sim of spectrum_analyzer_tb is
    constant CLK_PERIOD   : time    := 8 ns; -- 125MHz  
    constant DATA_WIDTH   : integer := 16;
    constant DECIM_RATE   : integer := 1;

    signal clk               : std_logic;
    signal reset             : std_logic;

    signal signal_in         : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal signal_out        : std_logic_vector((DATA_WIDTH*2) -1 downto 0);
    
    signal in_valid          : std_logic;
    signal out_valid         : std_logic;

    signal fft_output_done   : std_logic;
    signal fft_error         : std_logic;

    signal CIC_decim_factor  : std_logic_vector(6 downto 0);
    signal CIC_gain_shift    : std_logic_vector(3 downto 0);

    signal mixer_phase_incr  : std_logic_vector(DATA_WIDTH -1 downto 0);

begin
    analyzer: entity work.spectrum_analyzer
        generic map(
            DATA_SIZE => DATA_WIDTH
        )
        port map(
            clk              => clk,
            reset            => reset,

            signal_in        => signal_in,
            signal_out       => signal_out,

            full_frame_done  => fft_output_done,

            in_valid         => in_valid,
            out_valid        => out_valid,

            fft_error        => fft_error,

            CIC_decim_factor => CIC_decim_factor,
            CIC_gain_shift   => CIC_gain_shift,

            mixer_phase_incr => mixer_phase_incr
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

    reset_process : process
    begin
        reset <= '1';
        wait for 2 * CLK_PERIOD;
        wait until falling_edge(clk);
        reset <= '0';
        
        wait;
    end process;

    init_process : process
    begin
        CIC_decim_factor <= std_logic_vector(to_unsigned(64, CIC_decim_factor'length));
        CIC_gain_shift   <= std_logic_vector(to_unsigned(12, CIC_gain_shift'length));
        mixer_phase_incr <= std_logic_vector(to_unsigned(52, mixer_phase_incr'length)); -- ~100kHz at 125MHz clock
        wait;
    end process;

    capture_proc : process
        file output_file : text open write_mode is "sim/analyzer_frames.hex";
        file fir_real_file : text open write_mode is "sim/fir_real.hex";
        file fir_imag_file : text open write_mode is "sim/fir_imag.hex";

        variable real_row : line;
        variable imag_row : line;
        variable row          : line;
        variable frame_number : natural := 0;
        variable sample_count : natural := 0;
        variable previous_done : std_logic := '0';
    begin
        wait until rising_edge(clk);

        if reset = '0' then
            -- Capture each transferred output word.
            if out_valid = '1' then
                if sample_count = 0 then
                    write(row, string'("# FRAME "));
                    write(row, frame_number);
                    writeline(output_file, row);
                end if;

                hwrite(row, signal_out);
                writeline(output_file, row);
                sample_count := sample_count + 1;
            end if;

            -- Mark completion once, even if done stays high.
            if fft_output_done = '1' and previous_done = '0' then
                write(row, string'("# END_FRAME "));
                write(row, frame_number);
                write(row, string'(" COUNT "));
                write(row, sample_count);
                writeline(output_file, row);

                assert sample_count = 1024
                    report "Incorrect FFT output frame length"
                    severity error;

                sample_count := 0;
                frame_number := frame_number + 1;
                flush(output_file);
            end if;
        end if;

        previous_done := fft_output_done;
    end process;

   input_stimulus : process
        file input_file : text;
        variable row    : line;
        variable sample : std_logic_vector(DATA_WIDTH -1 downto 0);

        constant SAMPLE_INTERVAL : positive := DECIM_RATE;
    begin
        in_valid <= '0';
        signal_in  <= (others => '0');

        wait until reset = '0';
        wait for 4 * CLK_PERIOD; -- arbitrary time to let system settle after reset
        wait until rising_edge(clk);
        wait until falling_edge(clk);

        loop
            file_open(input_file, "sim/analyzer_input.hex", read_mode);

            while not endfile(input_file) loop
                readline(input_file, row);
                hread(row, sample);

                signal_in  <= sample;
                in_valid <= '1';

                wait until falling_edge(clk);
                in_valid <= '0';

                for cycle in 1 to SAMPLE_INTERVAL - 1 loop
                    wait until falling_edge(clk);
                end loop;
            end loop;

            file_close(input_file);
        end loop;
    end process;

end architecture sim;