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
        branch_error : out std_logic
    );
end fir_decim;

architecture rtl of fir_decim is
    constant R_WIDTH             : natural := clog2(DECIM_FACTOR);
    constant NUM_TAPS_PER_FILTER : natural := ((NUM_TAPS + DECIM_FACTOR - 1) / DECIM_FACTOR);

    type signed_arr_DATA_WIDTH_bit is array (natural range <>) of 
        signed(DATA_WIDTH -1 downto 0);

    type logic_vect_arr_DATA_WIDTH_bit is array (natural range <>) of 
        std_logic_vector(DATA_WIDTH -1 downto 0);

    -- Pre decimation delays
    signal pipeline_reg         : signed_arr_DATA_WIDTH_bit(0 to DECIM_FACTOR -2); -- There are decimation_factor -1 delays

    -- Decimator logic
    signal decim_cnt            : unsigned(R_WIDTH - 1 downto 0);
    signal decim_pulse          : std_logic;

    -- Branch sub filter logic
    signal branch_error_arr     : std_logic_vector(DECIM_FACTOR -1 downto 0);
    signal branch_out_valid     : std_logic_vector(DECIM_FACTOR -1 downto 0);
    signal branch_out_valid_reg : std_logic_vector(DECIM_FACTOR -1 downto 0);
    signal branch_out           : logic_vect_arr_DATA_WIDTH_bit(0 to DECIM_FACTOR -1);
    signal branch_reg           : signed_arr_DATA_WIDTH_bit(0 to DECIM_FACTOR -1);
    
    -- Accumulator logic
    signal mux_cnt              : unsigned(R_WIDTH -1 downto 0);
    signal calculating_bool     : std_logic;
    signal accu                 : signed(DATA_WIDTH + R_WIDTH -1 downto 0) := (others => '0'); -- Maximum theoretical size would be the data_width + log2(amount of branches)
    signal accu_in              : signed(DATA_WIDTH -1 downto 0);
begin

    -- Branch sub filter insantiation
    gen_branches : for i in 0 to DECIM_FACTOR -1 generate
        first_branch : if i = 0 generate
            branch_i : entity work.fir_decim_sub
                generic map (
                    DATA_WIDTH => DATA_WIDTH,
                    NUM_TAPS   => NUM_TAPS_PER_FILTER,
                    TAPS       => create_sub_tap_array(
                                  NUM_TAPS,
                                  TAPS,
                                  i,
                                  DECIM_FACTOR)
                )
                port map (
                    clk          => clk,
                    reset        => reset,
                    signal_in    => signal_in,
                    signal_out   => branch_out(i),
                    in_valid     => decim_pulse,
                    out_valid    => branch_out_valid(i),
                    branch_error => branch_error_arr(i)
                );
        else generate
            branch_i : entity work.fir_decim_sub
                generic map (
                    DATA_WIDTH => DATA_WIDTH,
                    NUM_TAPS   => NUM_TAPS_PER_FILTER,
                    TAPS       => create_sub_tap_array(
                                  NUM_TAPS,
                                  TAPS,
                                  i,
                                  DECIM_FACTOR)
                )
                port map (
                    clk          => clk,
                    reset        => reset,
                    signal_in    => std_logic_vector(pipeline_reg(i -1)),
                    signal_out   => branch_out(i),
                    in_valid     => decim_pulse,
                    out_valid    => branch_out_valid(i),
                    branch_error => branch_error_arr(i)
                );
        end generate;
    end generate gen_branches;

    -- Pipeline registers
    gen_pipeline : for i in 0 to DECIM_FACTOR -2 generate
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then
                    pipeline_reg(i) <= (others => '0');
                else
                    if in_valid = '1' then
                        if i = 0 then
                            pipeline_reg(i) <= resize(signed(signal_in), pipeline_reg(i)'length);
                        else
                            pipeline_reg(i) <= pipeline_reg(i -1);
                        end if;
                    end if;
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
                if decim_cnt = to_unsigned(0, decim_cnt'length) then
                    decim_pulse <= '1';
                else
                    decim_pulse <= '0';
                end if;

                if decim_cnt = DECIM_FACTOR - 1 then
                    decim_cnt <= to_unsigned(0, decim_cnt'length);
                else
                    decim_cnt <= decim_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- Branch logic
    gen_branch_out : for i in 0 to DECIM_FACTOR -1 generate
        process(clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then
                    branch_reg(i) <= (others => '0');
                else
                    if branch_out_valid(i) = '1' then
                        branch_reg(i) <= signed(branch_out(i));
                    end if;
                end if;
            end if;
        end process;
    end generate gen_branch_out;

    -- Branch out_valid pipeline reg
    gen_branch_out_valid_reg : for i in 0 to DECIM_FACTOR -1 generate
        process(clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then
                    branch_out_valid_reg(i) <= '0';
                else
                    branch_out_valid_reg(i) <= branch_out_valid(i);
                end if;
            end if;
        end process;
    end generate gen_branch_out_valid_reg;

    -- Counter logic for multiplexing
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mux_cnt <= (others => '0');
            else
                if and branch_out_valid = '1' or 
                   mux_cnt = to_unsigned(DECIM_FACTOR -1, mux_cnt'length) then
                    mux_cnt <= (others => '0'); -- Reset mux_cnt for new calculation
                else
                    mux_cnt <= mux_cnt +1;
                end if;
            end if;
        end if;
    end process;

    -- Calculating state machine
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                calculating_bool <= '0';
            else
                if and branch_out_valid_reg = '1' then
                    calculating_bool <= '1';
                elsif mux_cnt = to_unsigned(DECIM_FACTOR -1, mux_cnt'length) then
                    calculating_bool <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Accumulator logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                accu <= (others => '0');
            else
                if mux_cnt = to_unsigned(0, mux_cnt'length) then
                    accu <= resize(
                            branch_reg(DECIM_FACTOR -1), 
                            accu'length); -- Last branch
                else
                    accu <= resize(
                        branch_reg(DECIM_FACTOR -1 - to_integer(mux_cnt)), 
                        accu'length) + 
                        accu;
                end if;
            end if;
        end if;
    end process;

    -- Out_valid logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                out_valid <= '0';
            else
                if mux_cnt = to_unsigned(DECIM_FACTOR -1, mux_cnt'length) 
                   and calculating_bool = '1' then
                   out_valid <= '1';
                else
                    out_valid <= '0';
                end if;
            end if;
        end if;
    end process;

    branch_error <= or branch_error_arr;

    signal_out     <= std_logic_vector(to_signed(32767, signal_out'length)) 
                      when accu > to_signed(32767, accu'length) else
                      std_logic_vector(to_signed(-32768, signal_out'length)) 
                      when accu < to_signed(-32768, accu'length) else
                      std_logic_vector(resize(accu, signal_out'length));
end architecture;