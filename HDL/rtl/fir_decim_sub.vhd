library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;
use work.fir_taps.all;

-- Module for generating polyphase sub filters
-- This modules is designed to work at an FPGA clock rate of 125MHz and a decimated input 
-- of 1_953_125Hz to 7_812_500Hz, with branch decimation rates of 2 or 4
-- At 1_953_125Hz input, decimated by 2, lowest number of clock cycles per new input is 32
-- Highest is 256
-- Number of taps should be limited to 64, thus will need two parellel multiplier and accumulator stages.

entity fir_decim_sub is
    generic(
        DATA_WIDTH                    : integer := 16;
        NUM_TAPS                      : integer := 31; -- Number of taps seen by branch (TOTAL # TAPS / BRANCH COUNT)
        TAPS                          : taps_array(0 to NUM_TAPS -1) -- Taps for branch
    );
    port(
        clk                           : in std_logic;
        reset                         : in std_logic;
        signal_in                     : in std_logic_vector(DATA_WIDTH -1 downto 0);

        signal_out                    : out std_logic_vector(DATA_WIDTH -1 downto 0);

        -- Control Signals
        in_valid                      : in std_logic; -- This will be the decimation pulse input
        out_valid                     : out std_logic;

        -- Error Signals
        input_before_completion_error : out std_logic -- For catching if a new input is sent while module is still calculating
    );
end entity fir_decim_sub;

architecture rtl of fir_decim_sub is
    constant ADDED_WIDTH   : natural := clog2(NUM_TAPS); -- Width to account for due to accumulation
    constant MUX_CNT_WIDTH : natural := clog2((NUM_TAPS +1)/2); -- Add 1 to num taps to get ceiling division 
    constant MUX_CNT_MAX   : natural := ((NUM_TAPS +1)/2) -1; -- Max value mux_cnt reaches
    constant NUM_TAPS_HALF : natural := ((NUM_TAPS +1)/2); -- For splitting taps in half, equal to the half way index +1
    constant NUM_TAPS_RND  : natural := (((NUM_TAPS +1)/2)*2); -- NUM_TAPS rounded to a multiple of 2
    constant CURR_OFF_SIZE : natural := clog2((((NUM_TAPS +1)/2)*2)); -- For sizing the offset
    
    type signed_arr_DATA_WIDTH_bit is array (natural range <>) of 
        signed(DATA_WIDTH -1 downto 0);

    signal tap_array_1        : signed_arr_DATA_WIDTH_bit(0 to NUM_TAPS_HALF -1);
    signal tap_array_2        : signed_arr_DATA_WIDTH_bit(0 to NUM_TAPS_HALF -1);

    signal in_valid_shft_reg  : std_logic := '0'; -- in_valid pipelining
    signal signal_in_shft_reg : signed_arr_DATA_WIDTH_bit(0 to NUM_TAPS_RND -1); 

    signal mux_cnt            : unsigned(MUX_CNT_WIDTH -1 downto 0) := (others => '0');
    signal calculating_bool   : std_logic := '0'; -- If 1 then calculation in progress, else 0
    signal curr_offset        : unsigned(CURR_OFF_SIZE -1 downto 0) := (others => '0'); 

    signal accu_1             : signed(DATA_WIDTH + ADDED_WIDTH -1 downto 0) := (others => '0'); -- Likely wrong sizing here
    signal accu_2             : signed(DATA_WIDTH + ADDED_WIDTH -1 downto 0) := (others => '0');
    signal total_accu_sum     : signed(DATA_WIDTH + ADDED_WIDTH -1 downto 0) := (others => '0');
begin

    -- Generation of two tap arrays
    gen_tap_arrays : for i in 0 to NUM_TAPS_RND -1 generate
    begin
        gen_first_half : if i < NUM_TAPS_HALF generate
        begin
            tap_array_1(i) <= TAPS(i);
        end generate;

        gen_second_half : if i >= NUM_TAPS_HALF and i < NUM_TAPS generate
        begin
            tap_array_2(i - NUM_TAPS_HALF) <= TAPS(i);
        end generate;

        gen_padding : if i >= NUM_TAPS generate
        begin
            tap_array_2(i - NUM_TAPS_HALF) <= (others => '0');
        end generate;
    end generate gen_tap_arrays;

    -- Counter logic for multiplexing
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mux_cnt                       <= (others => '0');
                input_before_completion_error <= '0';
            else
                if in_valid = '1' or 
                   mux_cnt = to_unsigned(MUX_CNT_MAX, mux_cnt'length) then
                    mux_cnt <= (others => '0'); -- Reset mux_cnt for new calculation
                    
                    if calculating_bool = '1' then -- Error condition
                        input_before_completion_error <= '1';
                    else
                        input_before_completion_error <= '0';
                    end if;
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
                if in_valid_shft_reg = '1' then
                    calculating_bool <= '1';
                elsif out_valid = '1' then
                    calculating_bool <= '0';
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
                if mux_cnt = to_unsigned(MUX_CNT_MAX, mux_cnt'length) 
                   and calculating_bool = '1' then
                   out_valid <= '1';
                else
                    out_valid <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Shift register logic
    gen_shft_reg : for i in 0 to NUM_TAPS_RND -1 generate
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then
                    signal_in_shft_reg(i) <= (others => '0');
                    in_valid_shft_reg     <= '0';
                else
                    if in_valid = '1' then
                        if i = 0 then
                            signal_in_shft_reg(i) <= resize(signed(signal_in), signal_in_shft_reg(i)'length);
                        else
                            signal_in_shft_reg(i) <= signal_in_shft_reg(i -1);
                        end if;
                        in_valid_shft_reg <= '1';
                    else
                        in_valid_shft_reg <= '0';
                    end if;
                end if;
            end if;
        end process;
    end generate gen_shft_reg;

    -- Multipliyer and accumulator logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                accu_1 <= (others => '0');
                accu_2 <= (others => '0');
            else
                if mux_cnt = to_unsigned(0, mux_cnt'length) then
                    accu_1 <= resize(
                                    shift_right(
                                               signal_in_shft_reg(0) * 
                                               tap_array_1(0), 
                                               DATA_WIDTH -1 -- -1 to account for only fractional bits
                                    ),
                                    accu_1'length
                            );
                    accu_2 <= resize(
                                    shift_right(
                                               signal_in_shft_reg(to_integer(curr_offset)) * 
                                               tap_array_2(0), 
                                               DATA_WIDTH -1
                                    ),
                                    accu_2'length
                            );
                else
                    accu_1 <= accu_1 +
                              resize( 
                                    shift_right(
                                               signal_in_shft_reg(to_integer(mux_cnt)) * 
                                               tap_array_1(to_integer(mux_cnt)), 
                                               DATA_WIDTH -1
                                    ),
                                    accu_1'length
                            );
                    accu_2 <= accu_2 +
                              resize( 
                                    shift_right(
                                               signal_in_shft_reg(to_integer(curr_offset)) * 
                                               tap_array_2(to_integer(mux_cnt)), 
                                               DATA_WIDTH -1
                                    ),
                                    accu_2'length
                            );
                end if;
            end if;
        end if;
    end process;

    curr_offset    <= resize(mux_cnt, curr_offset'length) + to_unsigned(NUM_TAPS_HALF, curr_offset'length);
    total_accu_sum <= accu_1 + accu_2;

    -- Signal out with saturation logic
    signal_out     <= std_logic_vector(to_signed(32767, DATA_WIDTH)) 
                      when total_accu_sum > to_signed(32767, DATA_WIDTH) else
                      std_logic_vector(to_signed(-32768, DATA_WIDTH)) 
                      when total_accu_sum < -to_signed(-32768, DATA_WIDTH) else
                      std_logic_vector(resize(total_accu_sum, DATA_WIDTH));

end architecture;