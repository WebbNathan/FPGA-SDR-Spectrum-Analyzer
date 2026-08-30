library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

-- Module for computing FFT butterfly's. Assumes first half of word is real component and second half is imag
-- Currently non-serial computation of out_a and out_b

entity butterfly is
    generic(
        DATA_WIDTH : integer := 32;
        FRAC_BITS  : integer := 15 -- Use 15 for Q1.15 
    );
    port(
        clk       : in std_logic;
        reset     : in std_logic;

        twiddle   : in std_logic_vector(DATA_WIDTH -1 downto 0);
        data_a    : in std_logic_vector(DATA_WIDTH -1 downto 0);
        data_b    : in std_logic_vector(DATA_WIDTH -1 downto 0);

        out_a     : out std_logic_vector(DATA_WIDTH -1 downto 0);
        out_b     : out std_logic_vector(DATA_WIDTH -1 downto 0);

        in_valid  : in std_logic;
        out_valid : out std_logic
    );
end butterfly;

architecture rtl of butterfly is
    constant DATA_HALF    : integer := DATA_WIDTH/2;
    constant ACCU_BUFFER  : integer := 2; -- Accounts for growth from 3 term sum
    constant SATU_UP_LIM  : integer := (2 **(DATA_HALF -1)) -1;
    constant SATU_LOW_LIM : integer := (2** (DATA_HALF -1)) * (-1);

    signal data_a_real    : signed(DATA_HALF -1 downto 0);
    signal data_a_imag    : signed(DATA_HALF -1 downto 0);
    signal data_b_real    : signed(DATA_HALF -1 downto 0);
    signal data_b_imag    : signed(DATA_HALF -1 downto 0);
    signal twiddle_real   : signed(DATA_HALF -1 downto 0);
    signal twiddle_imag   : signed(DATA_HALF -1 downto 0);
 
    signal out_a_real     : signed(DATA_HALF + ACCU_BUFFER -1 downto 0);
    signal out_a_imag     : signed(DATA_HALF + ACCU_BUFFER -1 downto 0);
    signal out_b_real     : signed(DATA_HALF + ACCU_BUFFER -1 downto 0);
    signal out_b_imag     : signed(DATA_HALF + ACCU_BUFFER -1 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                out_a_real     <= (others => '0');
                out_a_imag     <= (others => '0');
                out_b_real     <= (others => '0');
                out_b_imag     <= (others => '0');
                out_valid      <= '0';
            else    
                out_a_real <= resize(data_a_real, out_a_real'length)  
                              + resize(shift_right(data_b_real * twiddle_real, FRAC_BITS), out_a_real'length)
                              - resize(shift_right(data_b_imag * twiddle_imag, FRAC_BITS), out_a_real'length);
                out_a_imag <= resize(data_a_imag, out_a_imag'length)
                              + resize(shift_right(data_b_imag * twiddle_real, FRAC_BITS), out_a_imag'length)
                              + resize(shift_right(data_b_real * twiddle_imag, FRAC_BITS), out_a_imag'length);

                out_b_real <= resize(data_a_real, out_b_real'length) 
                              - resize(shift_right(data_b_real * twiddle_real, FRAC_BITS), out_b_real'length)
                              + resize(shift_right(data_b_imag * twiddle_imag, FRAC_BITS), out_b_real'length);

                out_b_imag <= resize(data_a_imag, out_b_imag'length)
                              - resize(shift_right(data_b_imag * twiddle_real, FRAC_BITS), out_b_imag'length)
                              - resize(shift_right(data_b_real * twiddle_imag, FRAC_BITS), out_b_imag'length);
            end if;
        end if;
    end process;

    data_a_real <= signed(data_a(DATA_WIDTH -1 downto DATA_HALF));
    data_a_imag <= signed(data_a(DATA_HALF -1 downto 0));
    data_b_real <= signed(data_b(DATA_WIDTH -1 downto DATA_HALF));
    data_b_imag <= signed(data_b(DATA_HALF -1 downto 0));

    out_a(DATA_WIDTH -1 downto DATA_HALF) <= std_logic_vector(to_signed(SATU_UP_LIM, DATA_HALF)) 
                                             when out_a_real > to_signed(SATU_UP_LIM, out_a_real'length) else
                                             std_logic_vector(to_signed(SATU_LOW_LIM, DATA_HALF)) 
                                             when out_a_real < to_signed(SATU_LOW_LIM, out_a_real'length) else
                                             std_logic_vector(resize(out_a_real, DATA_HALF));
    
    out_a(DATA_HALF -1 downto 0)          <= std_logic_vector(to_signed(SATU_UP_LIM, DATA_HALF)) 
                                             when out_a_imag > to_signed(SATU_UP_LIM, out_a_imag'length) else
                                             std_logic_vector(to_signed(SATU_LOW_LIM, DATA_HALF)) 
                                             when out_a_imag < to_signed(SATU_LOW_LIM, out_a_imag'length) else
                                             std_logic_vector(resize(out_a_imag, DATA_HALF));

    out_b(DATA_WIDTH -1 downto DATA_HALF) <= std_logic_vector(to_signed(SATU_UP_LIM, DATA_HALF)) 
                                             when out_b_real > to_signed(SATU_UP_LIM, out_a_real'length) else
                                             std_logic_vector(to_signed(SATU_LOW_LIM, DATA_HALF)) 
                                             when out_b_real < to_signed(SATU_LOW_LIM, out_a_real'length) else
                                             std_logic_vector(resize(out_b_real, DATA_HALF));

    out_b(DATA_HALF -1 downto 0)          <= std_logic_vector(to_signed(SATU_UP_LIM, DATA_HALF)) 
                                             when out_b_imag > to_signed(SATU_UP_LIM, out_a_imag'length) else
                                             std_logic_vector(to_signed(SATU_LOW_LIM, DATA_HALF)) 
                                             when out_b_imag < to_signed(SATU_LOW_LIM, out_a_imag'length) else
                                             std_logic_vector(resize(out_b_imag, DATA_HALF));

end architecture;