library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;
use work.twiddle_factors.all;

-- twiddle_addr = k*1024/M, where M is current local FFT siz, if 1024 size FFT
-- k = j mod M/2
-- M = 2**i

entity get_twiddle is
    generic(
        I_WIDTH    : integer := 4;
        J_WIDTH    : integer := 9;
        FFT_SIZE   : integer := 1024;
        DATA_WIDTH : integer := 32
    );
    port(
        clk       : in std_logic;
        reset     : in std_logic;

        pulse_in  : in std_logic;
        pulse_out : out std_logic;

        i         : in std_logic_vector(I_WIDTH -1 downto 0);
        j         : in std_logic_vector(J_WIDTH -1 downto 0);

        twiddle   : out std_logic_vector(DATA_WIDTH -1 downto 0)
    );
end get_twiddle;

architecture rtl of get_twiddle is
    constant LOG_FFT_SIZE : integer := clog2(FFT_SIZE);
begin
    process(clk)
        variable M             : integer;
        variable index         : integer;
        variable shift         : integer;
        variable index_shifted : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pulse_out  <= '0';
                twiddle <= (others => '0');
            else
                if pulse_in = '1' then
                    M     := to_integer(
                                shift_left(
                                    to_unsigned(1, twiddle'length), 
                                    to_integer(unsigned(i)) +1
                                )
                            );

                    shift := LOG_FFT_SIZE 
                             -to_integer(unsigned(i)) 
                             -1;

                    index := to_integer(
                                unsigned(
                                    j(to_integer(unsigned(i)) -1 downto 0)
                                )
                             );

                    index_shifted := to_integer(
                                        shift_left(
                                            to_unsigned(index, twiddle'length), shift
                                        )
                                    );

                    twiddle <= std_logic_vector(TWIDDLE_ROM(index_shifted));
                    pulse_out  <= '1';
                else
                    pulse_out <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture;