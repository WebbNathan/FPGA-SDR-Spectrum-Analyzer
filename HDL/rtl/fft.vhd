library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;
use twiddle_factors.all;

entity fft is
    generic(
        FFT_SIZE  : integer := 1024;
        DATA_SIZE : integer := 32 
    );
    port(
        clk       : in std_logic;
        reset     : in std_logic;

        signal_in : in std_logic_vector(DATA_SIZE -1 downto 0);

        -- Control signals
        in_valid  : in std_logic;

        fft_RAM_error : out std_logic;
    );
end fft;

architecture rtl of fft is

    -- States for the two RAM blocks either INPUT state or PROCESSING state or IDLE at startup
    type RAM_state_t is (
        INPUT_S,
        PROCESSING_S
        IDLE_S
    );

    type Input_state_t is(
        INPUTING_S,
        DONE_S
    );

    type Processing_state_t is(
        PROCESSING_S,
        OUTPUTING_S,
        DONE_S
    );

    constant WORD_SIZE       : integer := 32;
    constant LOG_FFT_SIZE    : integer := clog2(FFT_SIZE);

    -- Ram steering logic
    signal ram_sel           : std_logic;

    signal ram_0_write_en    : std_logic;
    signal ram_0_read_en     : std_logic;
    signal ram_0_addr_0      : std_logic_vector(clog2(FFT_SIZE) -1 downto 0);
    signal ram_0_addr_1      : std_logic_vector(clog2(FFT_SIZE) -1 downto 0);
    signal ram_0_in_0        : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_0_in_1        : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_0_out_0       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_0_out_1       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_0_read_done   : std_logic;
    signal ram_0_write_done  : std_logic;

    signal ram_1_write_en    : std_logic;
    signal ram_1_read_en     : std_logic;
    signal ram_1_addr_0      : std_logic_vector(clog2(FFT_SIZE) -1 downto 0);
    signal ram_1_addr_1      : std_logic_vector(clog2(FFT_SIZE) -1 downto 0);
    signal ram_1_in_0        : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_1_in_1        : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_1_out_0       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_1_out_1       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal ram_1_read_done   : std_logic;
    signal ram_1_write_done  : std_logic;

    signal proc_write_en     : std_logic;
    signal proc_read_en      : std_logic;
    signal proc_addr_0       : std_logic_vector(clog2(FFT_SIZE) -1 downto 0);
    signal proc_addr_1       : std_logic_vector(clog2(FFT_SIZE) -1 downto 0);
    signal proc_in_0         : std_logic_vector(DATA_SIZE -1 downto 0);
    signal proc_in_1         : std_logic_vector(DATA_SIZE -1 downto 0);
    signal proc_out_0        : std_logic_vector(DATA_SIZE -1 downto 0);
    signal proc_out_1        : std_logic_vector(DATA_SIZE -1 downto 0);
    signal proc_read_done    : std_logic;
    signal proc_write_done   : std_logic;

    -- Controller logic
    signal fft_begin         : std_logic;
    signal counter_done      : std_logic;
    signal get_ab_done       : std_logic;
    signal get_twiddle_done  : std_logic;
    signal butterfly_done    : std_logic;
    signal read_mem_done     : std_logic;
    signal write_mem_done    : std_logic;

    signal counter_pulse     : std_logic;
    signal get_ab_pulse      : std_logic;
    signal get_twiddle_pulse : std_logic;
    signal butterfly_pulse   : std_logic;
    signal read_mem_pulse    : std_logic;
    signal write_mem_pulse   : std_logic;

    -- RAM Logic
    signal ram_0_state       : RAM_state_t := INPUT_S;
    signal ram_1_state       : RAM_state_t := IDLE_S;
    signal ram_sel           : std_logic;
    signal signal_in_to_RAM  : std_logic_vector(DATA_SIZE -1 downto 0);
    signal 

    -- Counter Logic
    signal counter_i_out : std_logic_vector(clog2(LOG_FFT_SIZE + 1) -1 downto 0);
    signal counter_j_out : std_logic_vector(clog2(FFT_SIZE/2) -1 downto 0);
begin

    fft_contr : entity work.fft_controller
        generic map(
            N     => FFT_SIZE,
            LOG_N => LOG_FFT_SIZE
        )
        port map(
            clk               => clk,
            reset             => reset,

            start             => fft_begin, -- This will be the logic that swaps RAM

            counter_done      => counter_done,
            get_ab_done       => get_ab_done,
            get_twiddle_done  => get_twiddle_done,
            butterfly_done    => butterfly_done,
            read_mem_done     => read_mem_done,
            write_mem_done    => write_mem_done,

            counter_pulse     => counter_pulse,
            get_ab_pulse      => get_ab_pulse,
            get_twiddle_pulse => get_twiddle_pulse,
            butterfly_pulse   => butterfly_pulse,
            read_mem_pulse    => read_mem_pulse,
            write_mem_pulse   => write_mem_pulse,

            i                 => counter_i_out,
            j                 => counter_j_out,

            done              : out std_logic
        );

    ram_0 : entity work.ram
        generic map(
            WORD_SIZE => WORD_SIZE,
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
            write_done => ram_0_write_done
        );

    ram_1 : entity work.ram
        generic map(
            WORD_SIZE => WORD_SIZE,
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
            write_done => ram_1_write_done
        );

    fft_counter : entity counter.ram
        generic map(
            N     => FFT_SIZE,
            LOG_N => LOG_FFT_SIZE
        )
        port map(
            clk       => clk,
            reset     => reset,
            
            pulse_in  => counter_pulse,
            pulse_out => counter_done,

            i_out     => counter_i_out,
            j_out     => counter_j_out
        );

        -- Ram steering logic
        process(clk)
        begin
            if reset = '1' then
                ram_sel <= '0';
            else
                 
            end if;
        end process;

        process(all)
        begin
            if ram_sel = '0' then
                ram_0_state <= INPUT_S;
                ram_1_state <= PROCESSING_S; -- Need some sort of IDLE state

                ram_0_write_en    <=
                ram_0_read_en     <=
                ram_0_addr_0      <=
                ram_0_addr_1      <=
                ram_0_in_0        <=
                ram_0_in_1        <=
                ram_0_out_0       <=
                ram_0_out_1       <=
                ram_0_read_done   <=
                ram_0_write_done  <=

                ram_1_write_en    <= proc_write_en;
                ram_1_read_en     <= proc_read_en;
                ram_1_addr_0      <= proc_addr_0;
                ram_1_addr_1      <= proc_addr_1;
                ram_1_in_0        <= proc_in_0;
                ram_1_in_1        <= proc_in_1;
                ram_1_out_0       <= proc_out_0;
                ram_1_out_1       <= proc_out_1;
                ram_1_read_done   <= proc_read_done;
                ram_1_write_done  <= proc_write_done;
            end if;
        end process;

end architecture;