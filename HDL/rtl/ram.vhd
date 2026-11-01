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
    type mem_t is array (0 to WORD_CNT-1)
        of std_logic_vector(WORD_SIZE-1 downto 0);

    impure function init_ram(filename : string) return mem_t is
        file input_file : text open read_mode is filename;
        variable row    : line;
        variable memory : mem_t := (others => (others => '0'));
        variable idx    : natural := 0;
    begin
        while not endfile(input_file) and idx < WORD_CNT loop
            readline(input_file, row);
            hread(row, memory(idx));
            idx := idx + 1;
        end loop;

        return memory;
    end function;

    --signal mem : mem_t := init_ram("pkg/fft_input.hex");
    signal mem : mem_t := (others => (others => '0'));
begin

    process(clk) 
    begin
        if rising_edge(clk) then
            if reset = '1' then
                --mem <= (others => (others => '0'));
            else
                if write_en = '1' then
                    mem(to_integer(unsigned(addr_0))) <= in_0;
                    if one_input = '0' then
                        mem(to_integer(unsigned(addr_1))) <= in_1;
                    end if;
                    write_done                        <= '1';
                else
                    write_done <= '0';
                end if;

                if read_en = '1' then
                    out_0     <= mem(to_integer(unsigned(addr_0)));
                    if one_input = '0' then
                        out_1     <= mem(to_integer(unsigned(addr_1)));
                    end if;
                    read_done <= '1';
                else
                    read_done <= '0';
                end if;
            end if;
        end if;
    end process;

    dump_proc : process
        file output_file : text open write_mode is "sim/fft_output.hex";
        variable row : line;
    begin
        wait for 2 ms;  -- After the FFT finishes.
        wait until falling_edge(clk);

        if dump_out = '1' then
            for idx in mem'range loop
                hwrite(row, mem(idx));
                writeline(output_file, row);
            end loop;

            file_close(output_file);
            report "RAM dumped to fft_output.hex";
            wait;
        end if;
    end process;
    -- synthesis translate_on

end architecture;