library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity fft_coordinator is
    port(  
        clk             : in std_logic;
        reset           : in std_logic;

        sample_start    : out std_logic;
        fft_start       : out std_logic;
        output_start    : out std_logic;

        fft_complete    : in std_logic;
        output_complete : in std_logic;
        input_complete  : in std_logic;

        bank_sel        : out std_logic_vector(1 downto 0);

        fft_error       : out std_logic -- If samples complete before processing and outputing assert 1
    );

end fft_coordinator;

architecture rtl of fft_coordinator is
    type coordinator_state_t is (
        WAKE_UP,
        SAMPLING_ONLY_S,
        SAMPLE_AND_PROCESS_S,
        SWAP_BANKS_S,
        PULSE_START_S,
        FULL_WORKING_S,
        SAMPLE_WAIT_S,
        SAMPLE_AND_OUTPUT_WAIT_S
    );

    signal coord_s : coordinator_state_t := WAKE_UP;

    signal sample_and_process_flag : std_logic;
begin

    -- bank_sel Counter
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                bank_sel <= (others => '0');
            else
                if coord_s = SWAP_BANKS_S then
                    if bank_sel = "10" then
                        bank_sel <= "00";
                    else
                        bank_sel <= std_logic_vector(
                                    unsigned(bank_sel) + to_unsigned(1, bank_sel'length)
                                    );
                    end if;
                end if;
            end if;
        end if;

    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                coord_s                 <= WAKE_UP;
                sample_start            <= '0';
                fft_start               <= '0';
                output_start            <= '0'; 
                sample_and_process_flag <= '0';
                fft_error               <= '0';
            else
                case coord_s is
                    when WAKE_UP =>
                        coord_s      <= SAMPLING_ONLY_S;
                        sample_start <= '1';
                        fft_start    <= '0';
                        output_start <= '0';

                    when SAMPLING_ONLY_S =>
                        if input_complete = '1' then
                            coord_s                <= SWAP_BANKS_S;
                            sample_start            <= '0';
                            fft_start               <= '0';
                            output_start            <= '0';
                            sample_and_process_flag <= '1';
                        else
                            coord_s      <= SAMPLING_ONLY_S;
                            sample_start <= '0';
                            fft_start    <= '0';
                            output_start <= '0';
                        end if;

                    when SWAP_BANKS_S =>
                        coord_s      <= PULSE_START_S;
                        sample_start <= '0';
                        fft_start    <= '0';
                        output_start <= '0';

                    when PULSE_START_S =>
                        if sample_and_process_flag = '1' then
                            coord_s <= SAMPLE_AND_PROCESS_S;
                            sample_start            <= '1';
                            fft_start               <= '1';
                            output_start            <= '0';
                            sample_and_process_flag <= '0'; -- Reset flag
                        else
                            coord_s <= FULL_WORKING_S;
                            sample_start <= '1';
                            fft_start    <= '1';
                            output_start <= '1';
                        end if;

                    when SAMPLE_AND_PROCESS_S =>
                        if fft_complete = '1' then
                            coord_s <= SAMPLE_WAIT_S;
                        else
                            coord_s <= SAMPLE_AND_PROCESS_S;
                        end if;

                        sample_start <= '0';
                        fft_start    <= '0';
                        output_start <= '0';

                        if input_complete = '1' and
                            fft_complete = '0' and
                            sample_start = '0'and
                            fft_start = '0' then -- Error condition

                            fft_error    <= '1';
                        end if;

                    when FULL_WORKING_S =>
                        if fft_complete = '1' then
                            coord_s      <= SAMPLE_AND_OUTPUT_WAIT_S;
                        else
                            coord_s      <= FULL_WORKING_S;
                        end if;

                        sample_start <= '0';
                        fft_start    <= '0';
                        output_start <= '0';

                        if input_complete = '1' and
                            (fft_complete = '0' or
                            output_complete = '0') and
                            sample_start = '0'and
                            fft_start = '0' and
                            output_start = '0' then -- Error condition

                            fft_error    <= '1';
                        end if;

                    when SAMPLE_WAIT_S =>
                        if input_complete = '1' then
                            coord_s      <= SWAP_BANKS_S;
                            sample_start <= '0';
                            fft_start    <= '0';
                            output_start <= '0';
                        else
                            coord_s      <= SAMPLE_WAIT_S;
                            sample_start <= '0';
                            fft_start    <= '0';
                            output_start <= '0';
                        end if;

                    when SAMPLE_AND_OUTPUT_WAIT_S =>
                        if input_complete = '1' and output_complete = '1' then
                            coord_s      <= SWAP_BANKS_S;
                            sample_start <= '0';
                            fft_start    <= '0';
                            output_start <= '0';
                        else
                            coord_s      <= SAMPLE_AND_OUTPUT_WAIT_S;
                            sample_start <= '0';
                            fft_start    <= '0';
                            output_start <= '0';
                        end if;

                        if input_complete = '1' and
                                output_complete = '0' then -- Error condition

                            fft_error    <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process;

end architecture;