library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity cic_decim is
    generic(
        N         : integer := 2;
        R_MAX     : integer := 64;
        IN_WIDTH  : integer := 16;
        OUT_WIDTH : integer := 16 
    );
    port(
        clk          : in std_logic;
        reset        : in std_logic;    
        signal_in    : in std_logic_vector(IN_WIDTH -1 downto 0);
        decim_factor : in std_logic_vector(clog2(R_MAX +1) -1 downto 0);
        gain_shift   : in std_logic_vector(clog2(N*clog2(R_MAX +1)) -1 downto 0);

        signal_out   : out std_logic_vector(OUT_WIDTH -1 downto 0);

        -- Control Signals
        in_valid     : in std_logic;
        out_valid    : out std_logic
    );
end cic_decim;

architecture rtl of cic_decim is
    constant R_WIDTH       : natural := clog2(R_MAX);
    constant MAX_BIT_GAIN  : natural := N * clog2(R_MAX);
    constant CIC_WIDTH     : natural := IN_WIDTH + MAX_BIT_GAIN; -- Accounts for CIC DC gain of RM^N
    constant R_SHIFT_WIDTH : natural := clog2(R_WIDTH +1); -- Plus one as R_SHIFT must allow value from 0 to MAX_R_SHIFT (MAX_R_SHIFT +1 values)
    
    type signed_arr_CIC_WIDTH_bit is array (natural range <>) of 
        signed(CIC_WIDTH -1 downto 0);
    
    type logic_arr is array (natural range <>) of
        std_logic;

    signal clk_slow_cnt_reg          : unsigned(R_WIDTH -1 downto 0); -- For creating the decimated clock, pulse on overflow
    signal slow_clk                  : std_logic;

    signal int_pipeline_reg          : signed_arr_CIC_WIDTH_bit(0 to N -1);
    signal comb_pipeline_reg         : signed_arr_CIC_WIDTH_bit(0 to N -1);
    signal comb_prev_in_pipeline_reg : signed_arr_CIC_WIDTH_bit(0 to N -1);

    signal out_valid_pipeline_reg    : logic_arr(0 to 2*N -1); -- 2*N pipeline stages
begin

    gen_modules : for i in 0 to N - 1 generate
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then
                    int_pipeline_reg(i)           <= (others => '0');
                    comb_pipeline_reg(i)          <= (others => '0');
                    comb_prev_in_pipeline_reg(i)  <= (others => '0');
                    out_valid_pipeline_reg(i)     <= '0';
                    out_valid_pipeline_reg(i + N) <= '0';
                else
                    if i = 0 then
                        if in_valid = '1' then
                            int_pipeline_reg(i) <= resize(signed(signal_in), int_pipeline_reg(i)'length) + int_pipeline_reg(i);
                        end if;
                        
                        out_valid_pipeline_reg(i) <= in_valid;

                        if slow_clk = '1' and out_valid_pipeline_reg(N -1) = '1' then
                            comb_pipeline_reg(i)          <= int_pipeline_reg(N -1) - comb_prev_in_pipeline_reg(i);
                            comb_prev_in_pipeline_reg(i)  <= int_pipeline_reg(N -1);
                            out_valid_pipeline_reg(i + N) <= out_valid_pipeline_reg(i + N -1);
                        end if;
                    elsif i = (N-1) then
                        if out_valid_pipeline_reg(i -1) = '1' then
                            int_pipeline_reg(i) <= int_pipeline_reg(i -1) + int_pipeline_reg(i);
                        end if;
                        out_valid_pipeline_reg(i) <= out_valid_pipeline_reg(i -1);

                        if slow_clk = '1' and out_valid_pipeline_reg(N -1 + i) = '1' then
                            comb_pipeline_reg(i)          <= comb_pipeline_reg(i -1) - comb_prev_in_pipeline_reg(i);
                            comb_prev_in_pipeline_reg(i)  <= comb_pipeline_reg(i -1);
                        end if;
                        out_valid_pipeline_reg(i + N) <= out_valid_pipeline_reg(i + N -1) and slow_clk; -- Ensures pulsing out valid only at decimation rate
                    else
                        int_pipeline_reg(i)       <= int_pipeline_reg(i -1) + int_pipeline_reg(i);
                        out_valid_pipeline_reg(i) <= out_valid_pipeline_reg(i -1);

                        if slow_clk = '1' then
                            comb_pipeline_reg(i)          <= comb_pipeline_reg(i -1) - comb_prev_in_pipeline_reg(i);
                            comb_prev_in_pipeline_reg(i)  <= comb_pipeline_reg(i -1);
                            out_valid_pipeline_reg(i + N) <= out_valid_pipeline_reg(i + N -1);
                        end if;
                    end if;
                end if;
            end if;
        end process;
    end generate gen_modules;

    slow_clk <= '1' when reset = '0'
                         and out_valid_pipeline_reg(N - 1) = '1'
                         and clk_slow_cnt_reg = unsigned(decim_factor) - 1
                else '0';
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                clk_slow_cnt_reg <= (others => '0');
            elsif out_valid_pipeline_reg(N - 1) = '1' then
                if slow_clk = '1' then
                    clk_slow_cnt_reg <= (others => '0');
                else
                    clk_slow_cnt_reg <= clk_slow_cnt_reg + 1;
                end if;
            end if;
        end if;
    end process;

    signal_out <= std_logic_vector(resize(
                                   shift_right(
                                   comb_pipeline_reg(N -1), 
                                   to_integer(unsigned(gain_shift))), 
                                   signal_out'length));

    out_valid  <= out_valid_pipeline_reg(2*N -1); 

end architecture;