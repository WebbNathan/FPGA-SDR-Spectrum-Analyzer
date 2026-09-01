library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity get_ab is
    generic(
        I_WIDTH    : integer := 4;
        J_WIDTH    : integer := 9;
        ADDR_WIDTH : integer := 10
    );
    port(
        clk        : in std_logic;
        reset      : in std_logic;

        pulse_in   : in std_logic;
        pulse_out  : out std_logic;

        i          : in std_logic_vector(I_WIDTH -1 downto 0);
        j          : in std_logic_vector(J_WIDTH -1 downto 0);

        out_a_addr : out std_logic_vector(ADDR_WIDTH -1 downto 0);
        out_b_addr : out std_logic_vector(ADDR_WIDTH -1 downto 0)
    );
end get_ab;

architecture rtl of get_ab is
begin
    process(clk)
        variable temp : unsigned(ADDR_WIDTH -1 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pulse_out  <= '0';
                out_a_addr <= (others => '0');
                out_b_addr <= (others => '0');
            else
                if pulse_in = '1' then
                    -- (j >> i) << i + j
                    temp := resize(
                                shift_left(
                                    shift_right(
                                        unsigned(j), 
                                        to_integer(unsigned(i))
                                    ), 
                                    to_integer(unsigned(i))
                                ) 
                                + unsigned(j), temp'length
                            );

                    out_a_addr <= std_logic_vector(temp);
                    out_b_addr <= std_logic_vector(
                                    temp 
                                    + shift_left(
                                            to_unsigned(1, out_b_addr'length), 
                                            to_integer(unsigned(i))
                                       )
                                  );
                                  
                    pulse_out  <= '1';
                else
                    pulse_out <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture;