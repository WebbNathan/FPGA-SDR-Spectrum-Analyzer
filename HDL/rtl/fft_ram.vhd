library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity fft_ram is
    generic(
        FFT_SIZE     : integer := 1024;
        LOG_FFT_SIZE : integer := 10;
        DATA_SIZE    : integer := 32 
    );
    port(
        clk            : in std_logic;
        reset          : in std_logic;

        -- Swap signal
        swap_blocks    : in std_logic;

        -- FFT input addresses
        fft_addr_a     : in std_logic_vector(LOG_FFT_SIZE -1 downto 0);
        fft_addr_b     : in std_logic_vector(LOG_FFT_SIZE -1 downto 0);

        -- FFT input values
        fft_in_a       : in std_logic_vector(DATA_SIZE -1 downto 0);
        fft_in_b       : in std_logic_vector(DATA_SIZE -1 downto 0);

        -- FFT read and write pulse
        fft_read       : in std_logic;
        fft_write      : in std_logic;

        -- FFT output values
        fft_out_a      : out std_logic_vector(DATA_SIZE -1 downto 0);
        fft_out_b      : out std_logic_vector(DATA_SIZE -1 downto 0);
        fft_read_done  : out std_logic;
        fft_write_done : out std_logic;

        -- Sample input address
        sample_addr    : in std_logic;

        -- Sample input value
        sample_in      : in std_logic_vector(DATA_SIZE -1 downto 0);

        -- Sample write pulse
        sample_write   : in std_logic;
    );
end fft_ram;

architecture rtl of fft_ram is

    -- RAM_0 logic
    signal ram_0_write_en   : std_logic;
    signal ram_0_read_en    : std_logic;

    signal ram_0_addr_0     : std_logic;
    signal ram_0_addr_1     : std_logic;

    signal ram_0_in_0       : std_logic;
    signal ram_0_in_1       : std_logic;

    signal ram_0_out_0      : std_logic;
    signal ram_0_out_1      : std_logic;

    signal ram_0_read_done  : std_logic;
    signal ram_0_write_done : std_logic;

    signal ram_0_one_input  : std_logic;

    -- RAM_1 logic
    signal ram_1_write_en   : std_logic;
    signal ram_1_read_en    : std_logic;

    signal ram_1_addr_0     : std_logic;
    signal ram_1_addr_1     : std_logic;

    signal ram_1_in_0       : std_logic;
    signal ram_1_in_1       : std_logic;

    signal ram_1_out_0      : std_logic;
    signal ram_1_out_1      : std_logic;

    signal ram_1_read_done  : std_logic;
    signal ram_1_write_done : std_logic;

    signal ram_1_one_input  : std_logic;

    -- State Logic
    signal state_variable   : std_logic; --For swapping RAM

begin

    ram_0: entity work.ram
        generic map(
            WORD_SIZE => DATA_SIZE,
            WORD_CNT  => FFT_SIZE
        )
        port map(
            clk        => clk,
            reset      => reset,

            write_en   => ram_0_write_en,
            read_en    => ram_0_read_en,

            addr_0     => ram_0_addr_0,
            addr_1     => ram_0_addr_1,

            in_0       => ram_0_in_0,
            in_1       => ram_0_in_1,

            out_0      => ram_0_out_0,
            out_1      => ram_0_out_1,

            read_done  => ram_0_read_done,
            write_done => ram_0_write_done,

            one_input  => ram_0_one_input
        );

    ram_1: entity work.ram
        generic map(
            WORD_SIZE => DATA_SIZE,
            WORD_CNT  => FFT_SIZE
        )
        port map(
            clk        => clk,
            reset      => reset,

            write_en   => ram_1_write_en,
            read_en    => ram_1_read_en,

            addr_0     => ram_1_addr_0,
            addr_1     => ram_1_addr_1,

            in_0       => ram_1_in_0,
            in_1       => ram_1_in_1,

            out_0      => ram_1_out_0,
            out_1      => ram_1_out_1,

            read_done  => ram_1_read_done,
            write_done => ram_1_write_done,

            one_input  => ram_1_one_input
        );

    -- Swap RAM blocks logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- RAM 0
                ram_0_write_en   => fft_write;
                ram_0_read_en    => fft_read;

                ram_0_addr_0     => fft_addr_a;
                ram_0_addr_1     => fft_addr_b;

                ram_0_in_0       => fft_in_a
                ram_0_in_1       => fft_in_b;

                ram_0_out_0      => fft_out_b;
                ram_0_out_1      => fft_out_b;

                ram_0_read_done  => fft_read_done;
                ram_0_write_done => fft_write_done;

                ram_0_one_input  => '0';

                -- RAM 1
                ram_1_write_en   => sample_write;
                ram_1_read_en    => open;

                ram_1_addr_0     => sample_addr;
                ram_1_addr_1     => open;

                ram_1_in_0       => sample_in
                ram_1_in_1       => open;

                ram_1_out_0      => open;
                ram_1_out_1      => open;

                ram_1_read_done  => open;
                ram_1_write_done => open;

                ram_1_one_input  => '1';

                -- State logic
                state_variable   => '0';
                
            elsif swap_block = '1' then
                if state_variable = '0' then
                    -- RAM 0
                    ram_0_write_en   => sample_write;
                    ram_0_read_en    => open;

                    ram_0_addr_0     => sample_addr;
                    ram_0_addr_1     => open;

                    ram_0_in_0       => sample_in
                    ram_0_in_1       => open;

                    ram_0_out_0      => open;
                    ram_0_out_1      => open;

                    ram_0_read_done  => open;
                    ram_0_write_done => open;

                    ram_0_one_input  => '1';

                    -- RAM 1
                    ram_1_write_en   => fft_write;
                    ram_1_read_en    => fft_read;

                    ram_1_addr_0     => fft_addr_a;
                    ram_1_addr_1     => fft_addr_b;

                    ram_1_in_0       => fft_in_a
                    ram_1_in_1       => fft_in_b;

                    ram_1_out_0      => fft_out_b;
                    ram_1_out_1      => fft_out_b;

                    ram_1_read_done  => fft_read_done;
                    ram_1_write_done => fft_write_done;

                    ram_1_one_input  => '0';
                else
                    -- RAM 0
                    ram_0_write_en   => fft_write;
                    ram_0_read_en    => fft_read;

                    ram_0_addr_0     => fft_addr_a;
                    ram_0_addr_1     => fft_addr_b;

                    ram_0_in_0       => fft_in_a
                    ram_0_in_1       => fft_in_b;

                    ram_0_out_0      => fft_out_b;
                    ram_0_out_1      => fft_out_b;

                    ram_0_read_done  => fft_read_done;
                    ram_0_write_done => fft_write_done;

                    ram_0_one_input  => '0';

                    -- RAM 1
                    ram_1_write_en   => sample_write;
                    ram_1_read_en    => open;

                    ram_1_addr_0     => sample_addr;
                    ram_1_addr_1     => open;

                    ram_1_in_0       => sample_in
                    ram_1_in_1       => open;

                    ram_1_out_0      => open;
                    ram_1_out_1      => open;

                    ram_1_read_done  => open;
                    ram_1_write_done => open;

                    ram_1_one_input  => '1';
                end if;

                state_variable <= not state_variable; -- Swap state
            end if;
        end if;

end architecture;