library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity fft_full_system is
    generic(
        FFT_SIZE   : integer := 1024;
        DATA_SIZE  : integer := 32;
        DECIM_RATE : integer := 128 
    );
    port(
        clk             : in std_logic;
        reset           : in std_logic;

        signal_in       : in std_logic_vector(DATA_SIZE -1 downto 0);
        signal_out      : out std_logic_vector(DATA_SIZE -1 downto 0);

        -- Control signals
        in_valid        : in std_logic;
        out_valid       : out std_logic; -- From output controller
        fft_output_done : out std_logic;

        fft_error       : out std_logic
    );
end fft_full_system;

architecture rtl of fft_full_system is
    constant LOG_FFT_SIZE : integer := clog2(FFT_SIZE);

    -- FFT Module
    signal ab_addr_a          : std_logic_vector(LOG_FFT_SIZE -1 downto 0);
    signal ab_addr_b          : std_logic_vector(LOG_FFT_SIZE -1 downto 0);

    signal read_mem_pulse     : std_logic;
    signal write_mem_pulse    : std_logic;

    signal fft_complete       : std_logic;

    -- FFT Ram
    signal fft_ram_out_0      : std_logic_vector(DATA_SIZE -1 downto 0);
    signal fft_ram_out_1      : std_logic_vector(DATA_SIZE -1 downto 0);

    signal fft_ram_in_0       : std_logic_vector(DATA_SIZE -1 downto 0);
    signal fft_ram_in_1       : std_logic_vector(DATA_SIZE -1 downto 0);

    signal fft_read_done      : std_logic;
    signal fft_write_done     : std_logic;

    -- Input Controller
    signal input_complete     : std_logic;
    signal sample_addr        : std_logic_vector(LOG_FFT_SIZE -1 downto 0);
    signal sample_write_pulse : std_logic;
    signal sample_write_done  : std_logic;
    signal signal_in_latch    : std_logic_vector(DATA_SIZE -1 downto 0);

    -- Output Controller
    signal output_complete    : std_logic;
    signal output_address     : std_logic_vector(LOG_FFT_SIZE -1 downto 0);
    signal output_read_pulse  : std_logic;
    signal output_out_val     : std_logic_vector(DATA_SIZE -1 downto 0);
    signal output_read_done   : std_logic;

    -- Coordinator Logic
    signal sample_start       : std_logic;
    signal fft_start          : std_logic;
    signal output_start       : std_logic;
    
    signal bank_sel           : std_logic_vector(1 downto 0);
begin

    fft_module: entity work.fft
        generic map(
            FFT_SIZE  => FFT_SIZE,
            LOG_FFT_SIZE => LOG_FFT_SIZE,
            DATA_SIZE => DATA_SIZE
        )
        port map(
            clk              => clk,
            reset            => reset,

            read_mem_done    => fft_read_done,
            write_mem_done   => fft_write_done,

            ram_out_0        => fft_ram_out_0,
            ram_out_1        => fft_ram_out_1,

            ab_addr_a        => ab_addr_a,
            ab_addr_b        => ab_addr_b,

            read_mem_pulse   => read_mem_pulse,
            write_mem_pulse  => write_mem_pulse,

            butterfly_out_a  => fft_ram_in_0,
            butterfly_out_b  => fft_ram_in_1,

            fft_complete     => fft_complete,

            start            => fft_start
        );

    fft_ram: entity work.fft_ram
        generic map(
            FFT_SIZE     => FFT_SIZE,
            LOG_FFT_SIZE => LOG_FFT_SIZE,
            DATA_SIZE    => DATA_SIZE
        )
        port map(
            clk              => clk,
            reset            => reset,

            -- Swap signal
            bank_sel         => bank_sel,

            -- FFT input addresses
            fft_addr_a       => ab_addr_a,
            fft_addr_b       => ab_addr_b,

            -- FFT input values
            fft_in_a          => fft_ram_in_0,
            fft_in_b          => fft_ram_in_1,

            -- FFT read and write pulse
            fft_read          => read_mem_pulse,
            fft_write         => write_mem_pulse,

            -- FFT output values
            fft_out_a         => fft_ram_out_0,
            fft_out_b         => fft_ram_out_1,
            fft_read_done     => fft_read_done,
            fft_write_done    => fft_write_done,

            -- Output address
            output_addr       => output_address,
 
            -- Output read pulse
            output_read       => output_read_pulse,

            -- Ouput read value
            output_out_val    => output_out_val,
            output_read_done  => output_read_done,

            -- Sample input address
            sample_addr       => sample_addr,

            -- Sample input value
            sample_in         => signal_in_latch,

            -- Sample write pulse
            sample_write      => sample_write_pulse,

            -- Sample Out
            sample_write_done => sample_write_done
        );

    fft_coord: entity work.fft_coordinator
        port map(
            clk             => clk,
            reset           => reset,

            sample_start    => sample_start,
            fft_start       => fft_start,
            output_start    => output_start,

            fft_complete    => fft_complete,
            output_complete => output_complete,
            input_complete  => input_complete,

            bank_sel        => bank_sel,

            fft_error       => fft_error
        );

    fft_input_contr: entity work.fft_input_controller
        generic map(
            FFT_SIZE   => FFT_SIZE,
            ADDR_WIDTH => LOG_FFT_SIZE
        )
        port map(
            clk             => clk,
            reset           => reset,

            start           => sample_start,
            in_valid        => in_valid,

            addr            => sample_addr,
            write_pulse     => sample_write_pulse,
            done            => input_complete
        );

    fft_output_contr: entity work.fft_output_controller
        generic map(
            FFT_SIZE   => FFT_SIZE,
            ADDR_WIDTH => LOG_FFT_SIZE,
            DECIM_RATE => DECIM_RATE
        )
        port map(
            clk             => clk,
            reset           => reset,

            start           => output_start,
            read_done       => output_read_done,

            addr            => output_address,
            read_pulse      => output_read_pulse,
            fft_out_valid   => out_valid,
            done            => output_complete
        );

    process(clk) 
    begin
        if rising_edge(clk) then
            if reset = '1' then
                signal_in_latch <= (others => '0');
            else
                if in_valid = '1' then
                    signal_in_latch <= signal_in;
                end if;
            end if;
        end if;    
    end process;

    signal_out      <= output_out_val;
    fft_output_done <= output_complete;

end architecture;