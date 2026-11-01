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
        clk               : in std_logic;
        reset             : in std_logic;

        -- Swap signal
        bank_sel          : in std_logic_vector(1 downto 0);

        -- FFT input addresses
        fft_addr_a        : in std_logic_vector(LOG_FFT_SIZE -1 downto 0);
        fft_addr_b        : in std_logic_vector(LOG_FFT_SIZE -1 downto 0);

        -- FFT input values
        fft_in_a          : in std_logic_vector(DATA_SIZE -1 downto 0);
        fft_in_b          : in std_logic_vector(DATA_SIZE -1 downto 0);

        -- FFT read and write pulse
        fft_read          : in std_logic;
        fft_write         : in std_logic;

        -- FFT output values
        fft_out_a         : out std_logic_vector(DATA_SIZE -1 downto 0);
        fft_out_b         : out std_logic_vector(DATA_SIZE -1 downto 0);
        fft_read_done     : out std_logic;
        fft_write_done    : out std_logic;

        -- Output address
        output_addr       : in std_logic_vector(LOG_FFT_SIZE -1 downto 0);

        -- Output read pulse
        output_read       : in std_logic;

        -- Ouput read value
        output_out_val    : out std_logic_vector(DATA_SIZE -1 downto 0);
        output_read_done  : out std_logic;

        -- Sample input address
        sample_addr       : in std_logic_vector(LOG_FFT_SIZE -1 downto 0);

        -- Sample input value
        sample_in         : in std_logic_vector(DATA_SIZE -1 downto 0);

        -- Sample write pulse
        sample_write      : in std_logic;

        -- Sample Out
        sample_write_done : out std_logic
    );
end fft_ram;

architecture rtl of fft_ram is

    -- RAM_0 logic
    signal ram_0_write_en   : std_logic;
    signal ram_0_read_en    : std_logic;

    signal ram_0_addr_0     : std_logic_vector(LOG_FFT_SIZE -1 downto 0);
    signal ram_0_addr_1     : std_logic_vector(LOG_FFT_SIZE -1 downto 0);

    signal ram_0_in_0       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_0_in_1       : std_logic_vector(DATA_SIZE -1 downto 0);

    signal ram_0_out_0      : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_0_out_1      : std_logic_vector(DATA_SIZE -1 downto 0);

    signal ram_0_read_done  : std_logic;
    signal ram_0_write_done : std_logic;

    signal ram_0_one_input  : std_logic;

    signal ram_0_dump_out   : std_logic;

    -- RAM_1 logic
    signal ram_1_write_en   : std_logic;
    signal ram_1_read_en    : std_logic;

    signal ram_1_addr_0     : std_logic_vector(LOG_FFT_SIZE -1 downto 0);
    signal ram_1_addr_1     : std_logic_vector(LOG_FFT_SIZE -1 downto 0);

    signal ram_1_in_0       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_1_in_1       : std_logic_vector(DATA_SIZE -1 downto 0);

    signal ram_1_out_0      : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_1_out_1      : std_logic_vector(DATA_SIZE -1 downto 0);

    signal ram_1_read_done  : std_logic;
    signal ram_1_write_done : std_logic;

    signal ram_1_one_input  : std_logic;

    signal ram_1_dump_out   : std_logic;

    -- RAM_2 logic
    signal ram_2_write_en   : std_logic;
    signal ram_2_read_en    : std_logic;

    signal ram_2_addr_0     : std_logic_vector(LOG_FFT_SIZE -1 downto 0);
    signal ram_2_addr_1     : std_logic_vector(LOG_FFT_SIZE -1 downto 0);

    signal ram_2_in_0       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_2_in_1       : std_logic_vector(DATA_SIZE -1 downto 0);

    signal ram_2_out_0      : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_2_out_1      : std_logic_vector(DATA_SIZE -1 downto 0);

    signal ram_2_read_done  : std_logic;
    signal ram_2_write_done : std_logic;

    signal ram_2_one_input  : std_logic;

    signal ram_2_dump_out   : std_logic;

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

            one_input  => ram_0_one_input,

            dump_out   => ram_0_dump_out
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

            one_input  => ram_1_one_input,

            dump_out   => ram_1_dump_out
        );

    ram_2: entity work.ram
        generic map(
            WORD_SIZE => DATA_SIZE,
            WORD_CNT  => FFT_SIZE
        )
        port map(
            clk        => clk,
            reset      => reset,

            write_en   => ram_2_write_en,
            read_en    => ram_2_read_en,

            addr_0     => ram_2_addr_0,
            addr_1     => ram_2_addr_1,

            in_0       => ram_2_in_0,
            in_1       => ram_2_in_1,

            out_0      => ram_2_out_0,
            out_1      => ram_2_out_1,

            read_done  => ram_2_read_done,
            write_done => ram_2_write_done,

            one_input  => ram_2_one_input,

            dump_out   => ram_2_dump_out
        );

    -- Swap RAM blocks logic
    process(all)
    begin
        -- RAM_0 (Sample -> FFT -> Output)
        ram_0_write_en   <= sample_write when bank_sel = "00" else 
                            fft_write when bank_sel = "01" else
                            '0' when bank_sel = "10" else
                            '0';

        ram_0_read_en    <= '0' when bank_sel = "00" else 
                            fft_read when bank_sel = "01" else
                            output_read when bank_sel = "10" else
                            '0';

        ram_0_addr_0     <= sample_addr when bank_sel = "00" else
                            fft_addr_a when bank_sel = "01" else
                            output_addr when bank_sel = "10" else
                            (ram_0_addr_0'range => '0');

        ram_0_addr_1     <= (ram_0_addr_1'range => '0') when bank_sel = "00" else
                            fft_addr_b when bank_sel = "01" else
                            (ram_0_addr_1'range => '0')  when bank_sel = "10" else
                            (ram_0_addr_1'range => '0');

        ram_0_in_0       <= sample_in when bank_sel = "00" else
                            fft_in_a when bank_sel = "01" else
                            (ram_0_in_0'range => '0') when bank_sel = "10" else
                            (ram_0_in_0'range => '0');

        ram_0_in_1       <= (ram_0_in_1'range => '0') when bank_sel = "00" else
                            fft_in_b when bank_sel = "01" else
                            (ram_0_in_1'range => '0') when bank_sel = "10" else
                            (ram_0_in_1'range => '0');

        ram_0_one_input  <= '1' when bank_sel = "00" else
                            '0' when bank_sel = "01" else
                            '1' when bank_sel = "10" else
                            '0';

        -- RAM_1 (FFT -> Output -> Sample)
        ram_1_write_en   <= sample_write when bank_sel = "10" else 
                            fft_write when bank_sel = "00" else
                            '0' when bank_sel = "01" else
                            '0';

        ram_1_read_en    <= '0' when bank_sel = "10" else 
                            fft_read when bank_sel = "00" else
                            output_read when bank_sel = "01" else
                            '0';

        ram_1_addr_0     <= sample_addr when bank_sel = "10" else
                            fft_addr_a when bank_sel = "00" else
                            output_addr when bank_sel = "01" else
                            (ram_1_addr_0'range => '0');

        ram_1_addr_1     <= (ram_1_addr_1'range => '0') when bank_sel = "10" else
                            fft_addr_b when bank_sel = "00" else
                            (ram_1_addr_1'range => '0') when bank_sel = "01" else
                            (ram_1_addr_1'range => '0');

        ram_1_in_0       <= sample_in when bank_sel = "10" else
                            fft_in_a when bank_sel = "00" else
                            (ram_1_in_0'range => '0') when bank_sel = "01" else
                            (ram_1_in_0'range => '0');

        ram_1_in_1       <= (ram_1_in_1'range => '0') when bank_sel = "10" else
                            fft_in_b when bank_sel = "00" else
                            (ram_1_in_1'range => '0') when bank_sel = "01" else
                            (ram_1_in_1'range => '0');

        ram_1_one_input  <= '1' when bank_sel = "10" else
                            '0' when bank_sel = "00" else
                            '1' when bank_sel = "01" else
                            '0';

        -- RAM_2 (Output -> Sample -> FFT)
        ram_2_write_en   <= sample_write when bank_sel = "01" else 
                            fft_write when bank_sel = "10" else
                            '0' when bank_sel = "00" else
                            '0';

        ram_2_read_en    <= '0' when bank_sel = "01" else 
                            fft_read when bank_sel = "10" else
                            output_read when bank_sel = "00" else
                            '0';

        ram_2_addr_0     <= sample_addr when bank_sel = "01" else
                            fft_addr_a when bank_sel = "10" else
                            output_addr when bank_sel = "00" else
                            (ram_2_addr_0'range => '0');

        ram_2_addr_1     <= (ram_2_addr_1'range => '0') when bank_sel = "01" else
                            fft_addr_b when bank_sel = "10" else
                            (ram_2_addr_1'range => '0') when bank_sel = "00" else
                            (ram_2_addr_1'range => '0');

        ram_2_in_0       <= sample_in when bank_sel = "01" else
                            fft_in_a when bank_sel = "10" else
                            (ram_2_in_0'range => '0') when bank_sel = "00" else
                            (ram_2_in_0'range => '0');

        ram_2_in_1       <= (ram_2_in_1'range => '0') when bank_sel = "01" else
                            fft_in_b when bank_sel = "10" else
                            (ram_2_in_1'range => '0') when bank_sel = "00" else
                            (ram_2_in_1'range => '0');

        ram_2_one_input  <= '1' when bank_sel = "01" else
                            '0' when bank_sel = "10" else
                            '1' when bank_sel = "00" else
                            '0';

        fft_out_a         <= ram_0_out_0 when bank_sel = "01" else
                             ram_1_out_0 when bank_sel = "00" else
                             ram_2_out_0 when bank_sel = "10" else
                             (fft_out_a'range => '0');

        fft_out_b         <= ram_0_out_1 when bank_sel = "01" else
                             ram_1_out_1 when bank_sel = "00" else
                             ram_2_out_1 when bank_sel = "10" else
                             (fft_out_b'range => '0');

        fft_read_done     <= ram_0_read_done when bank_sel = "01" else
                             ram_1_read_done when bank_sel = "00" else
                             ram_2_read_done when bank_sel = "10" else
                             '0';

        fft_write_done    <= ram_0_write_done when bank_sel = "01" else
                             ram_1_write_done when bank_sel = "00" else
                             ram_2_write_done when bank_sel = "10" else
                             '0';

        output_out_val    <= ram_0_out_0 when bank_sel = "10" else
                             ram_1_out_0 when bank_sel = "01" else
                             ram_2_out_0 when bank_sel = "00" else
                             (output_out_val'range => '0');

        output_read_done  <= ram_0_read_done when bank_sel = "10" else
                             ram_1_read_done when bank_sel = "01" else
                             ram_2_read_done when bank_sel = "00" else
                             '0';

        sample_write_done <= ram_2_write_done when bank_sel = "00" else
                             ram_2_write_done when bank_sel = "10" else
                             ram_2_write_done when bank_sel = "01" else
                             '0';
        
    end process;

    ram_0_dump_out <= '1' when bank_sel = "01" else '0';

    ram_1_dump_out <= '1' when bank_sel = "00" else '0';

    ram_2_dump_out <= '1' when bank_sel = "10" else '0';

end architecture;