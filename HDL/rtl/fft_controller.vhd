library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity fft_controller is
    generic(
        N     : integer := 1024; -- Number of samples in FFT, should be a power of 2
        LOG_N : integer := 10 -- log2(N) 
    );
    port(
        clk               : in std_logic;
        reset             : in std_logic;

        start             : in std_logic;

        counter_done      : in std_logic;
        get_ab_done       : in std_logic;
        get_twiddle_done  : in std_logic;
        butterfly_done    : in std_logic;
        read_mem_done     : in std_logic;
        write_mem_done    : in std_logic;

        counter_pulse     : out std_logic;
        get_ab_pulse      : out std_logic;
        get_twiddle_pulse : out std_logic;
        butterfly_pulse   : out std_logic;
        read_mem_pulse    : out std_logic;
        write_mem_pulse   : out std_logic;

        i                 : in std_logic_vector(clog2(LOG_N + 1) -1 downto 0); -- Stage counter
        j                 : in std_logic_vector(clog2(N/2) -1 downto 0); -- Butterfly counter

        done              : out std_logic
    );
end fft_controller;

architecture rtl of fft_controller is
    constant I_MAX : integer := LOG_N -1;
    constant J_MAX : integer := (N/2) -1;

    type state_t is (
        IDLE,
        COUNTER,
        COUNTER_WAIT,
        GET_AB,
        GET_AB_WAIT,
        READ_MEM,
        READ_MEM_WAIT,
        GET_W,
        GET_W_WAIT,
        BUTTERFLY,
        BUTTERFLY_WAIT,
        WRITE_MEM,
        WRITE_MEM_WAIT,
        FFT_DONE
    );

    signal state : state_t := IDLE;
begin
    process(clk)
    begin
        if reset = '1' then
            state             <= IDLE;
            done              <= '0';
            counter_pulse     <= '0';
            get_ab_pulse      <= '0';
            get_twiddle_pulse <= '0';
            butterfly_pulse   <= '0';
            read_mem_pulse    <= '0';
            write_mem_pulse   <= '0';
        else
            case state is
                when IDLE =>
                    done <= '0';
                    if start ='1' then  
                        state <= COUNTER;
                    end if;
                
                when COUNTER =>
                    counter_pulse <= '1';
                    state         <= COUNTER_WAIT;
                
                when COUNTER_WAIT =>
                    counter_pulse <= '0';
                    if counter_done = '1' then
                        state <= GET_AB;
                    end if;

                when GET_AB =>
                    get_ab_pulse <= '1';
                    state        <= GET_AB_WAIT;
                
                when GET_AB_WAIT =>
                    get_ab_pulse <= '0';
                    if get_ab_done = '1' then
                        state <= READ_MEM;
                    end if;

                when READ_MEM =>
                    read_mem_pulse <= '1';
                    state          <= READ_MEM_WAIT;

                when READ_MEM_WAIT =>
                    read_mem_pulse <= '0';
                    if read_mem_done = '1' then
                        state <= GET_W;
                    end if;

                when GET_W =>
                    get_twiddle_pulse <= '1';
                    state <= GET_W_WAIT;
                
                when GET_W_WAIT =>
                    get_twiddle_pulse <= '0';
                    if get_twiddle_done = '1' then 
                        state <= BUTTERFLY;
                    end if;
                
                when BUTTERFLY =>
                    butterfly_pulse <= '1';
                    state           <= BUTTERFLY_WAIT;

                when BUTTERFLY_WAIT =>
                    butterfly_pulse <= '0';
                    if butterfly_done = '1' then
                        state <= WRITE_MEM;
                    end if;

                when WRITE_MEM =>
                    write_mem_pulse <= '1';
                    state           <= WRITE_MEM_WAIT;

                when WRITE_MEM_WAIT =>
                    write_mem_pulse <= '0';
                    if write_mem_done = '1' then
                        state <= FFT_DONE;
                    end if;

                when FFT_DONE =>
                    if unsigned(i) = to_unsigned(I_MAX, i'length)
                        and unsigned(j) = to_unsigned(J_MAX, j'length)
                        then
                        done  <= '1';
                        state <= IDLE;
                    else
                        state <= COUNTER;
                    end if;
            end case;
        end if;
    end process;
end architecture;