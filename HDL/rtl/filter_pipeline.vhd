library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;
use work.fir_taps.all;

entity filter_pipeline is
    generic(
        DATA_WIDTH           : integer := 16;
        CIC_N                : integer := 2;
        CIC_R_MAX            : integer := 64;
        FIR_MOD_1_NUM_TAPS   : integer := 31;
        FIR_MOD_2_NUM_TAPS   : integer := 31;
        FIR_MOD_1_TAPS       : taps_array(0 to FIR_MOD_1_NUM_TAPS -1);
        FIR_MOD_2_TAPS       : taps_array(0 to FIR_MOD_2_NUM_TAPS -1);
        FIR_MOD_1_DECIM_RATE : integer := 2;
        FIR_MOD_2_DECIM_RATE : integer := 2
    );
    port(
        clk            : in std_logic;
        reset          : in std_logic;
        signal_in      : in std_logic_vector(DATA_WIDTH -1 downto 0);

        signal_out     : out std_logic_vector(DATA_WIDTH -1 downto 0);

        -- Control Signals
        in_valid       : in std_logic;
        out_valid      : out std_logic;

        CIC_decim_rate : in std_logic_vector(clog2(CIC_R_MAX) -1 downto 0);
        CIC_gain_shift : in std_logic_vector(clog2(clog2(CIC_R_MAX +1)) -1 downto 0);

        FIR_num        : in std_logic; -- '0' for 1 filter else '1' for both 

        -- Error Signals
        branch_error   : out std_logic
    );
end filter_pipeline;

architecture rtl of filter_pipeline is

    signal CIC_signal_out       : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal CIC_out_valid        : std_logic;

    signal FIR_MOD_1_signal_out : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal FIR_MOD_1_out_valid  : std_logic;
    signal FIR_MOD_1_branch_err  : std_logic;

    signal FIR_MOD_2_signal_out : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal FIR_MOD_2_out_valid  : std_logic;
    signal FIR_MOD_2_branch_err : std_logic;

begin

    cic_decim_module : entity work.cic_decim
        generic map (
            N         => CIC_N,
            R_MAX     => CIC_R_MAX,
            IN_WIDTH  => DATA_WIDTH,
            OUT_WIDTH => DATA_WIDTH
        )
        port map (
            clk           => clk,
            reset         => reset,
            signal_in     => signal_in,
            decim_factor  => CIC_decim_rate,
            gain_shift    => CIC_gain_shift,
            signal_out    => CIC_signal_out,
            in_valid      => in_valid,
            out_valid     => CIC_out_valid
        );

    fir_decim_module_1 : entity work.fir_decim
        generic map (
            DATA_WIDTH   => DATA_WIDTH,
            NUM_TAPS     => FIR_MOD_1_NUM_TAPS,
            TAPS         => FIR_MOD_1_TAPS,
            DECIM_FACTOR => FIR_MOD_1_DECIM_RATE
        )
        port map (
            clk           => clk,
            reset         => reset,
            signal_in     => CIC_signal_out,
            signal_out    => FIR_MOD_1_signal_out,
            in_valid      => CIC_out_valid,
            out_valid     => FIR_MOD_1_out_valid,
            branch_error  => FIR_MOD_1_branch_err
        );

    fir_decim_module_2 : entity work.fir_decim
        generic map (
            DATA_WIDTH   => DATA_WIDTH,
            NUM_TAPS     => FIR_MOD_2_NUM_TAPS,
            TAPS         => FIR_MOD_2_TAPS,
            DECIM_FACTOR => FIR_MOD_2_DECIM_RATE
        )
        port map (
            clk           => clk,
            reset         => reset,
            signal_in     => FIR_MOD_1_signal_out,
            signal_out    => FIR_MOD_2_signal_out,
            in_valid      => FIR_MOD_1_out_valid,
            out_valid     => FIR_MOD_2_out_valid,
            branch_error  => FIR_MOD_2_branch_err
        );

        signal_out   <= FIR_MOD_2_signal_out when FIR_num = '1'
                        else FIR_MOD_1_signal_out;

        out_valid    <= FIR_MOD_2_out_valid when FIR_num = '1'
                        else FIR_MOD_1_out_valid;  

        branch_error <= FIR_MOD_1_branch_err or FIR_MOD_2_branch_err;

end architecture;
