library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

-- Two input RAM for use in FFT module. Two will be instantiated with a mux to create a buffer and FFT RAM

entity ram is
    generic(
        WORD_SIZE : integer := 32;
        WORD_CNT  : integer := 1024
    );
    port(
        clk      : in std_logic;
        reset    : in std_logic;

        write_en : in std_logic;
        read_en  : in std_logic;

        addr_0   : in std_logic_vector(clog2(WORD_CNT) -1 downto 0);
        addr_1   : in std_logic_vector(clog2(WORD_CNT) -1 downto 0);

        in_0     : in std_logic_vector(WORD_SIZE -1 downto 0);
        in_1     : in std_logic_vector(WORD_SIZE -1 downto 0);

        out_0    : out std_logic_vector(WORD_SIZE -1 downto 0);
        out_1    : out std_logic_vector(WORD_SIZE -1 downto 0)
    );
end ram;

architecture rtl of ram is
    type mem_t is array (0 to WORD_CNT-1)
        of std_logic_vector(WORD_SIZE-1 downto 0);

    signal mem : mem_t;
begin

    process(clk) 
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mem <= (others => (others => '0'));
            else
                if write_en = '1' then
                    mem(to_integer(unsigned(addr_0))) <= in_0;
                    mem(to_integer(unsigned(addr_1))) <= in_1;
                end if;

                if read_en = '1' then
                    out_0 <= mem(to_integer(unsigned(addr_0)));
                    out_1 <= mem(to_integer(unsigned(addr_1)));
                end if;
            end if;
        end if;
    end process;

end architecture;