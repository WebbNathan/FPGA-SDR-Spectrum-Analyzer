library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;
use work.twiddle_factors.all;

entity fft is
    generic(
        FFT_SIZE     : integer := 1024;
        DATA_SIZE    : integer := 32;
        LOG_FFT_SIZE : integer := 10
    );
    port(
        clk             : in std_logic;
        reset           : in std_logic;

        read_mem_done   : in std_logic;
        write_mem_done  : in std_logic;

        ram_out_0       : in std_logic_vector(DATA_SIZE -1 downto 0);
        ram_out_1       : in std_logic_vector(DATA_SIZE -1 downto 0);

        ab_addr_a       : out std_logic_vector(LOG_FFT_SIZE -1 downto 0);
        ab_addr_b       : out std_logic_vector(LOG_FFT_SIZE -1 downto 0);

        read_mem_pulse  : out std_logic;
        write_mem_pulse : out std_logic;

        butterfly_out_a : out std_logic_vector(DATA_SIZE -1 downto 0);
        butterfly_out_b : out std_logic_vector(DATA_SIZE -1 downto 0);

        fft_complete    : out std_logic;
        start           : in std_logic
    );
end fft;

architecture rtl of fft is

    constant WORD_SIZE             : integer := 32;
    constant FRAC_BITS             : integer := 15; --Number of bits for fractional real and imag part of twiddle (Using Q1.15)

    -- FFT Controller logic
    signal counter_done            : std_logic;
    signal get_ab_done             : std_logic;
    signal get_twiddle_done        : std_logic;
    signal butterfly_done          : std_logic;

    signal counter_pulse           : std_logic;
    signal get_ab_pulse            : std_logic;
    signal get_twiddle_pulse       : std_logic;
    signal butterfly_pulse         : std_logic;

    -- Counter Logic
    signal counter_i_out            : std_logic_vector(clog2(LOG_FFT_SIZE + 1) -1 downto 0);
    signal counter_j_out            : std_logic_vector(clog2(FFT_SIZE/2) -1 downto 0);
    signal counter_reset            : std_logic;

    -- Get Twiddle Logic
    signal twiddle_out              : std_logic_vector(DATA_SIZE -1 downto 0);

begin

    fft_contr : entity work.fft_controller
        generic map(
            N     => FFT_SIZE,
            LOG_N => LOG_FFT_SIZE
        )
        port map(
            clk               => clk,
            reset             => reset,

            start             => start,

            counter_done      => counter_done,
            get_ab_done       => get_ab_done,
            get_twiddle_done  => get_twiddle_done,
            butterfly_done    => butterfly_done,
            read_mem_done     => read_mem_done,
            write_mem_done    => write_mem_done,

            counter_pulse     => counter_pulse,
            get_ab_pulse      => get_ab_pulse,
            get_twiddle_pulse => get_twiddle_pulse,
            butterfly_pulse   => butterfly_pulse,
            read_mem_pulse    => read_mem_pulse,
            write_mem_pulse   => write_mem_pulse,

            i                 => counter_i_out,
            j                 => counter_j_out,

            done              => fft_complete,
            counter_reset     => counter_reset
        );

    fft_counter : entity work.counter
        generic map(
            N     => FFT_SIZE,
            LOG_N => LOG_FFT_SIZE
        )
        port map(
            clk          => clk,
            reset        => reset,

            system_reset => counter_reset,
            
            pulse_in     => counter_pulse,
            pulse_out    => counter_done,

            i_out        => counter_i_out,
            j_out        => counter_j_out
        );

        fft_get_ab : entity work.get_ab
            generic map(
                I_WIDTH    => counter_i_out'length,
                J_WIDTH    => counter_j_out'length,
                ADDR_WIDTH => LOG_FFT_SIZE
            )
            port map(
                clk        => clk,
                reset      => reset,

                pulse_in   => get_ab_pulse,
                pulse_out  => get_ab_done,

                i          => counter_i_out,
                j          => counter_j_out,

                out_a_addr => ab_addr_a,
                out_b_addr => ab_addr_b
            );
        
        fft_get_twiddle : entity work.get_twiddle
            generic map(
                I_WIDTH    => counter_i_out'length,
                J_WIDTH    => counter_j_out'length,
                FFT_SIZE   => FFT_SIZE,
                DATA_WIDTH => DATA_SIZE
            )
            port map(
                clk       => clk,
                reset     => reset,

                pulse_in  => get_twiddle_pulse,
                pulse_out => get_twiddle_done,

                i         => counter_i_out,
                j         => counter_j_out,

                twiddle   => twiddle_out
            );

        fft_butterfly : entity work.butterfly
            generic map(
                DATA_WIDTH => DATA_SIZE,
                FRAC_BITS  => FRAC_BITS
            )
            port map(
                clk       => clk,
                reset     => reset,

                twiddle   => twiddle_out,
                data_a    => ram_out_0,
                data_b    => ram_out_1,

                out_a     => butterfly_out_a,
                out_b     => butterfly_out_b,

                in_valid  => butterfly_pulse,
                out_valid => butterfly_done
            );

end architecture;