library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;
use work.fir_taps.all;

-- This module will use a polyphase FIR filter design

entity fir_decim is
    generic(
        NUM_TAPS       : integer := 31;
        DECIM_FACTOR   : integer := 2;
        DATA_WIDTH     : integer := 16;
        TAPS           : taps_array(0 to NUM_TAPS -1)
    );
    port(
        clk        : in std_logic;
        reset      : in std_logic;
        signal_in  : in std_logic_vector(DATA_WIDTH -1 downto 0);

        signal_out : out std_logic_vector(DATA_WIDTH -1 downto 0);

        -- Control Signals
        in_valid   : in std_logic;
        out_valid  : out std_logic;

        -- Error Signals
        input_before_completion_error : out std_logic
    );
end fir_decim;

architecture rtl of fir_decim is
    constant R_WIDTH             : natural := clog2(DECIM_FACTOR);
    constant NUM_TAPS_PER_FILTER : natural 

    type signed_arr_DATA_WIDTH_bit is array (natural range <>) of 
        signed(DATA_WIDTH -1 downto 0);

    type logic_arr is array (natural range <>) of
        std_logic;

    -- Decimator logic
    signal decim_cnt         : unsigned(R_WIDTH - 1 downto 0);
    signal decim_pulse       : std_logic;
    
    -- Pre decimation delays
    signal pipeline_reg      : signed_arr_DATA_WIDTH_bit(0 to DECIM_FACTOR -2); -- There are decimation_factor -1 delays
    signal in_valid_pipeline : logic_arr(0 to DECIM_FACTOR -2);
    
    -- Accumulator logic
    signal accu              : signed(DATA_WIDTH + R_WIDTH -1 downto 0); -- Maximum theoretical size would be the data_width + log2(amount of branches)
    signal accu_in           : signed(DATA_WIDTH -1 downto 0);

    -- Branch sub filter logic
    signal branch_reg        : signed_arr_DATA_WIDTH_bit(0 to DECIM_FACTOR -1);
begin

    -- Branch sub filter insantiation
    gen_branches : for i in 0 to DECIM_FACTOR -1 generate
        if i = 0 then
            branch_i : entity work.fir_decim_sub
                generic map (
                    DATA_WIDTH => DATA_WIDTH,
                    NUM_TAPS   => ((NUM_TAPS + DECIM_FACTOR - 1) / DECIM_FACTOR),
                    TAPS       => create_sub_tap_array(
                                                      NUM_TAPS,
                                                      TAPS,
                                                      i,
                                                      DECIM_FACTOR
                                  )
                )
                port map (
                    clk                           => clk,
                    reset                         => reset
                    signal_in                     => signal_in,

                    signal_out                    => branch_reg(i),

                    in_valid                      => in_valid and
                                                     decim_pulse,
                    out_valid                     =>

                    input_before_completion_error =>
                );
        else
            branch_i : entity work.fir_decim_sub
                generic map (
                    DATA_WIDTH => DATA_WIDTH
                    NUM_TAPS   =>
                    TAPS       => create_sub_tap_array(
                                                      NUM_TAPS,
                                                      TAPS,
                                                      i,
                                                      DECIM_FACTOR
                                  )
                )
                port map (
                    clk                           => clk,
                    reset                         => reset
                    signal_in                     => pipeline_reg(i -1),

                    signal_out                    => branch_reg(i),

                    in_valid                      => in_valid_pipeline(i -1) and 
                                                     decim_pulse,
                    out_valid                     =>

                    input_before_completion_error =>
                );
        end if;
    end generate gen_branches;

    -- Pipeline registers
    gen_pipeline : for i in 0 to DECIM_FACTOR -2 generate
    begin
        process(clk)
        begin
            if reset = '1' then
                pipeline_reg(i) <= (others => '0');
            else
                if i = 0 then
                    pipeline_reg(i)   <= resize(signed(signal_in), pipeline_reg(i)'length);
                    in_valid_pipeline <= in_valid;
                else
                    pipeline_reg(i)      <= pipeline_reg(i -1);
                    in_valid_pipeline(i) <= in_valid_pipeline(i -1);
                end if;
            end if;
        end process;
    end generate gen_pipeline;

    -- Decimation counter
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                decim_cnt   <= to_unsigned(0, decim_cnt'length);
                decim_pulse <= '0';
            else
                if decim_cnt = to_unsigned(DECIM_FACTOR -1, decim_cnt'length) then
                    decim_pulse <= '1';
                else
                    decim_pulse <= '0';
                end if;
                
                decim_cnt <= decim_cnt + 1;
            end if;
        end if;
    end process;

    -- Accumulator logic
    process(clk)
    begin
        if reset = '1' then
            accu <= to_signed(0, accu'length);
        else
            if decim_cnt = to_unsigned(0, decim_cnt'length) then
                accu <= branch_reg(DECIM_FACTOR -1); -- Last branch
            else
                accu <= branch_reg(DECIM_FACTOR -1 - decim_cnt) + accu;
            end if;
        end if;
    end process;
end architecture;