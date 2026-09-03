library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

-- STATE IDLE: waiting for start command -> INPUTTING (startup condition)
-- STATE RUNNING : counting and sending write pulses -> DONE
-- STATE DONE : alerts the writing has completed and awaits a new start command -> INPUTTING

entity fft_input_controller is
    generic(
        FFT_SIZE   : integer := 1024;
        ADDR_WIDTH : integer := 10 
    );
    port(
        clk             : in std_logic;
        reset           : in std_logic;

        start           : in std_logic;
        in_valid        : in std_logic;

        addr            : out std_logic_vector(ADDR_WIDTH -1 downto 0);
        write_pulse     : out std_logic;
        done            : out std_logic;
    );
end fft_input_controller;

architecture rtl of fft_input_controller is
    type INPUT_CONT_state_t is (
        IDLE_S,
        RUNNING_S,
        DONE_S
    );

    signal num_samples_cnt   : unsigned(ADDR_WIDTH -1 downto 0);
    signal last_sample       : std_logic;

    signal controller_state  : INPUT_CONT_state_t;
begin

    -- To determine if on last sample
    last_sample <= '1' when
        in_valid = '1'
        and controller_state = RUNNING_S
        and num_samples_cnt = to_unsigned(FFT_SIZE - 1, num_samples_cnt'length)
    else '0';

-- Number of samples counter logic
    process(clk)
    begin
        if reset = '1' then
            num_samples_cnt <= (others => '0');
        else
            if in_valid = '1' 
            and controller_state = RUNNING_S
            then
                if last_sample = '1'then
                    num_samples_cnt <= (others => '0');
                else
                    num_samples_cnt <= num_samples_cnt 
                                    + to_unsigned(1, num_samples_cnt'length);
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if reset = '1' then
            controller_state <= IDLE_S;
            write_pulse      <= '0';
            done             <= '0';
        else
            case controller_state is
                when IDLE_S =>
                    if start = '1' then
                        controller_state <= RUNNING_S;
                    end if;
                    write_pulse <= '0';
                    done        <= '0';
                
                when RUNNING_S =>
                    if last_sample = '1' then
                        controller_state <= DONE_S;
                    end if;
                    write_pulse <= '1';
                    done        <= '0';

                when DONE_S =>
                    if start = '1' then
                        controller_state <= RUNNING_S;
                        done             <= '0';
                    else
                        done <= '1';
                    end if;
                    write_pulse <= '0';
            end case;
        end if;
    end process;

    gen_bit_reverse : for i in 0 to ADDR_WIDTH - 1 generate
    begin
        addr(i) <= num_samples_cnt(ADDR_WIDTH - 1 - i);
    end generate;

end architecture;