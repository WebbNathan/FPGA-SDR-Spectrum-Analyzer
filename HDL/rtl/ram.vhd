library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

use std.textio.all;

library work;
use work.util_pkg.all;

-- Two input RAM for use in FFT module. Two will be instantiated with a mux to create a buffer and FFT RAM

entity ram is
    generic(
        WORD_SIZE : integer := 32;
        WORD_CNT  : integer := 1024
    );
    port(
        clk        : in std_logic;
        reset      : in std_logic;

        write_en   : in std_logic;
        read_en    : in std_logic;

        addr_0     : in std_logic_vector(clog2(WORD_CNT) -1 downto 0);
        addr_1     : in std_logic_vector(clog2(WORD_CNT) -1 downto 0);

        in_0       : in std_logic_vector(WORD_SIZE -1 downto 0);
        in_1       : in std_logic_vector(WORD_SIZE -1 downto 0);

        out_0      : out std_logic_vector(WORD_SIZE -1 downto 0);
        out_1      : out std_logic_vector(WORD_SIZE -1 downto 0);

        read_done  : out std_logic;
        write_done : out std_logic; 

        one_input  : in std_logic; -- For specifying whether only one input port is used (1 if yes)

        -- Test signals
        dump_out   : in std_logic -- 1 if module should dump outputs to file
    );
end ram;

architecture rtl of ram is
    type mem_t is array (0 to WORD_CNT - 1)
        of std_logic_vector(WORD_SIZE - 1 downto 0);

    shared variable mem : mem_t := (others => (others => '0'));

    signal port0_en : std_logic;
    signal port1_en : std_logic;
    signal port0_we : std_logic;
begin
    port0_we <= write_en;

    port0_en <= (read_en or port0_we) and not reset;
    port1_en <= (read_en or write_en) and not one_input and not reset;

    -- Port 0
    process(clk)
    begin
        if rising_edge(clk) then
            if port0_en = '1' then
                out_0 <= mem(to_integer(unsigned(addr_0)));
                if port0_we = '1' then
                    mem(to_integer(unsigned(addr_0))) := in_0;
                end if;
            end if;
        end if;
    end process;

    -- Port 1
    process(clk)
    begin
        if rising_edge(clk) then
            if port1_en = '1' then
                out_1 <= mem(to_integer(unsigned(addr_1)));
                if write_en = '1' then
                    mem(to_integer(unsigned(addr_1))) := in_1;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                read_done  <= read_en;
                write_done <= write_en;

                -- synthesis translate_off
                assert not (read_en = '1' and write_en = '1')
                    report "FFT RAM received a read and a write on the same edge"
                    severity failure;
                -- synthesis translate_on
            end if;
        end if;
    end process;
end architecture;