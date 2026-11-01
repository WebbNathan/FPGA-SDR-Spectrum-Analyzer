library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library work;
use work.util_pkg.all;

entity fft_tb is
end entity fft_tb;

architecture sim of fft_tb is
    constant CLK_PERIOD   : time    := 8 ns; -- 125MHz  
    constant N            : integer := 1024;
    constant DATA_WIDTH   : integer := 32;
    constant LOG_FFT_SIZE : integer := clog2(N);
    constant DECIM_RATE   : integer := 128;

    signal clk               : std_logic;
    signal reset             : std_logic;

    signal start             : std_logic;
    signal signal_in         : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal signal_out        : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal in_valid          : std_logic;
    signal out_valid         : std_logic;
    signal fft_output_done   : std_logic;
    signal ram_error         : std_logic;

begin
    dut : entity work.fft_full_system
        generic map(
            FFT_SIZE   => N,
            DATA_SIZE  => DATA_WIDTH,
            DECIM_RATE => DECIM_RATE
        )
        port map(
            clk             => clk,
            reset           => reset,

            signal_in       => signal_in,
            signal_out      => signal_out,
            
            in_valid        => in_valid,
            out_valid       => out_valid,
            fft_output_done => fft_output_done,
            fft_error       => ram_error
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

    capture_proc : process
        file output_file : text open write_mode is "sim/fft_frames.hex";
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
        variable sample : std_logic_vector(31 downto 0);

        constant SAMPLE_INTERVAL : positive := DECIM_RATE;
    begin
        in_valid <= '0';
        signal_in  <= (others => '0');

        wait until reset = '0';
        wait for 4 * CLK_PERIOD; -- arbitrary time to let system settle after reset
        wait until rising_edge(clk);
        wait until falling_edge(clk);

        loop
            file_open(input_file, "pkg/fft_input.hex", read_mode);

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