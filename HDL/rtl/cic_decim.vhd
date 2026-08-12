library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity cic_decim is
    generic(
        N         : integer := 2;
        R         : integer := 64;
        IN_WIDTH  : integer := 16;
        OUT_WIDTH : integer := 16 
    );
    port(
        clk        : in std_logic;
        reset      : in std_logic;
        signal_in  : in std_logic_vector(IN_WIDTH -1 downto 0);

        slow_clk   : out std_logic; -- Decimated clock
        signal_out : out std_logic_vector(OUT_WIDTH -1 downto 0);

        -- Control Signals
        in_valid   : in std_logic;
        out_valid  : out std_logic
    );
end cic_decim;

architecture rtl of cic_decim is
    constant R_WIDTH   : natural := clog2(R);
    constant BIT_GAIN  : natural := N * clog2(R);
    constant CIC_WIDTH : natural := IN_WIDTH + BIT_GAIN; -- Accounts for CIC DC gain of RM^N
    
    type signed_arr_CIC_WIDTH_bit is array (natural range <>) of 
        signed(CIC_WIDTH -1 downto 0);
    
    type logic_arr is array (natural range <>) of
        std_logic;

    signal clk_slow_cnt_reg          : unsigned(R_WIDTH -1 downto 0); -- For creating the decimated clock, pulse on overflow

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
                        int_pipeline_reg(i)       <= resize(signed(signal_in), int_pipeline_reg(i)'length)  + int_pipeline_reg(i);
                        out_valid_pipeline_reg(i) <= in_valid;

                        if slow_clk = '1' then
                            comb_pipeline_reg(i)          <= int_pipeline_reg(N -1) - comb_prev_in_pipeline_reg(i);
                            comb_prev_in_pipeline_reg(i)  <= int_pipeline_reg(N -1);
                            out_valid_pipeline_reg(i + N) <= out_valid_pipeline_reg(i + N -1);
                        end if;
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

    -- Generate Slow Clock
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                clk_slow_cnt_reg <= to_unsigned(0, clk_slow_cnt_reg'length);
            else
                if clk_slow_cnt_reg = to_unsigned(R -1, clk_slow_cnt_reg'length) then
                    slow_clk <= '1';
                else
                    slow_clk <= '0';
                end if;
                
                clk_slow_cnt_reg <= clk_slow_cnt_reg + 1;
            end if;
        end if;
    end process;

    signal_out <= std_logic_vector(resize(shift_right(comb_pipeline_reg(N -1), BIT_GAIN), signal_out'length));
    out_valid  <= out_valid_pipeline_reg(2*N -1); 

end architecture;