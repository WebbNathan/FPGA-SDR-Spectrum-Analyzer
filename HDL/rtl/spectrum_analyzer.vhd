library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;
use work.fir_taps.all;

entity spectrum_analyzer is
    generic(
        DATA_SIZE : integer := 16
    );
    port(
        clk              : in std_logic;
        reset            : in std_logic;

        signal_in        : in std_logic_vector(DATA_SIZE -1 downto 0);
        signal_out       : out std_logic_vector((DATA_SIZE*2) -1 downto 0);

        full_frame_done  : out std_logic; -- Signifies a full 1024 sized frame has been output

        in_valid         : in std_logic;
        out_valid        : out std_logic;

        fft_error        : out std_logic;

        CIC_decim_factor : in std_logic_vector(6 downto 0);
        CIC_gain_shift   : in std_logic_vector(3 downto 0);

        mixer_phase_incr : in std_logic_vector(DATA_SIZE -1 downto 0)
    );
end spectrum_analyzer;

architecture rtl of spectrum_analyzer is
    constant FFT_SIZE         : integer := 1024;
    constant DOUBLE_DATA_SIZE : integer := DATA_SIZE*2;
    constant DECIM_RATE       : integer := 128;
    constant NUM_TAPS         : integer := 91;
    constant FIR_DECIM_FACTOR : integer := 2;
    constant CIC_N            : integer := 2;
    constant CIC_R_MAX        : integer := 64;
    constant CORDIC_STAGE     : integer := 15;
    
    signal adc_sample              : std_logic_vector(15 downto 0);

    -- FIR
    signal FIR_signal_out_real     : std_logic_vector(DATA_SIZE -1 downto 0);
    signal FIR_signal_out_imag     : std_logic_vector(DATA_SIZE -1 downto 0);
    signal FIR_signal_out          : std_logic_vector(DOUBLE_DATA_SIZE -1 downto 0);
    signal FIR_out_valid_real      : std_logic;
    signal FIR_out_valid_imag      : std_logic;
    signal FIR_branch_error_real   : std_logic;
    signal FIR_branch_error_imag   : std_logic;

    -- CIC
    signal CIC_signal_out_real     : std_logic_vector(DATA_SIZE -1 downto 0);
    signal CIC_signal_out_imag     : std_logic_vector(DATA_SIZE -1 downto 0);
    signal CIC_out_valid_real      : std_logic;
    signal CIC_out_valid_imag      : std_logic;

    -- Mixer
    signal mixer_signal_out_real  : std_logic_vector(DATA_SIZE -1 downto 0);
    signal mixer_signal_out_imag  : std_logic_vector(DATA_SIZE -1 downto 0);
    signal mixer_out_valid        : std_logic;

begin

    fft_system: entity work.fft_full_system
        generic map(
            FFT_SIZE   => FFT_SIZE,
            DATA_SIZE  => DOUBLE_DATA_SIZE,
            DECIM_RATE => DECIM_RATE
        )
        port map(
            clk             => clk,
            reset           => reset,

            signal_in       => FIR_signal_out,
            signal_out      => signal_out,

            in_valid        => FIR_out_valid_real and FIR_out_valid_imag,
            out_valid       => out_valid,
            fft_output_done => full_frame_done,

            fft_error       => fft_error
        );

    fir_decim_real: entity work.fir_decim
        generic map(
            NUM_TAPS       => NUM_TAPS,
            DECIM_FACTOR   => FIR_DECIM_FACTOR,
            DATA_WIDTH     => DATA_SIZE,
            TAPS           => FIR_MOD_1_TAPS -- WILL NEED TO ACTUALLY WRITE
        )
        port map(
            clk          => clk,
            reset        => reset,
            signal_in    => CIC_signal_out_real,

            signal_out   => FIR_signal_out_real,

            in_valid     => CIC_out_valid_real,
            out_valid    => FIR_out_valid_real,

            branch_error => FIR_branch_error_real
        );

    fir_decim_imag: entity work.fir_decim
        generic map(
            NUM_TAPS       => NUM_TAPS,
            DECIM_FACTOR   => FIR_DECIM_FACTOR,
            DATA_WIDTH     => DATA_SIZE,
            TAPS           => FIR_MOD_1_TAPS -- WILL NEED TO ACTUALLY WRITE
        )
        port map(
            clk          => clk,
            reset        => reset,
            signal_in    => CIC_signal_out_imag,

            signal_out   => FIR_signal_out_imag,

            in_valid     => CIC_out_valid_imag,
            out_valid    => FIR_out_valid_imag,

            branch_error => FIR_branch_error_imag
        );

        cic_decim_real: entity work.cic_decim
            generic map(
                N         => CIC_N,
                R_MAX     => CIC_R_MAX,
                IN_WIDTH  => DATA_SIZE,
                OUT_WIDTH => DATA_SIZE
            )
            port map(
                clk          => clk,
                reset        => reset,
                signal_in    => mixer_signal_out_real,
                decim_factor => CIC_decim_factor,
                gain_shift   => CIC_gain_shift,

                signal_out   => CIC_signal_out_real,

                in_valid     => mixer_out_valid,
                out_valid    => CIC_out_valid_real
            );

        cic_decim_imag: entity work.cic_decim
            generic map(
                N         => CIC_N,
                R_MAX     => CIC_R_MAX,
                IN_WIDTH  => DATA_SIZE,
                OUT_WIDTH => DATA_SIZE
            )
            port map(
                clk          => clk,
                reset        => reset,
                signal_in    => mixer_signal_out_imag,
                decim_factor => CIC_decim_factor,
                gain_shift   => CIC_gain_shift,

                signal_out   => CIC_signal_out_imag,

                in_valid     => mixer_out_valid,
                out_valid    => CIC_out_valid_imag
            );

        mixer: entity work.mixer
            generic map(
                CORDIC_STAGE     => CORDIC_STAGE,
                AMPLITUDE_WIDTH  => DATA_SIZE
            )
            port map(
                clk        => clk,
                reset      => reset,

                phase_incr => mixer_phase_incr,
                signal_in  => adc_sample,
                
                I_val      => mixer_signal_out_real,
                Q_val      => mixer_signal_out_imag,

                in_valid   => in_valid,
                out_valid  => mixer_out_valid
            );

        FIR_signal_out <= FIR_signal_out_real & FIR_signal_out_imag;
        adc_sample <= (not signal_in(15)) & signal_in(14 downto 4) & "0000";

end architecture;