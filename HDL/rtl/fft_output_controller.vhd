library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

-- Module should send a read_pulse out with an address
-- Should then recieve the read_done pulse and should assert fft_out_valid and output address (bin)

entity fft_output_controller is
    generic(
        FFT_SIZE   : integer := 1024;
        ADDR_WIDTH : integer := 10;
        DECIM_RATE : integer := 128
    );
    port(
        clk             : in std_logic;
        reset           : in std_logic;

        start           : in std_logic;
        read_done       : in std_logic;

        addr            : out std_logic_vector(ADDR_WIDTH -1 downto 0);
        read_pulse      : out std_logic;
        fft_out_valid   : out std_logic;
        done            : out std_logic
    );
end fft_output_controller;

architecture rtl of fft_output_controller is
    type INPUT_CONT_state_t is (
        IDLE_S,
        READ_PULSE_S,
        READ_WAIT_S,
        OUTPUT_ASSERT_S,
        DONE_S
    );

    signal controller_state  : INPUT_CONT_state_t;

    signal num_samples_cnt   : unsigned(ADDR_WIDTH -1 downto 0);
    signal last_sample       : std_logic;
    signal count_pulse       : std_logic;
    signal decim_cnt         : unsigned(clog2(DECIM_RATE) -1 downto 0);
begin

    -- Decimation counter (for outputting at the decim rate)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                decim_cnt   <= to_unsigned(0, decim_cnt'length);
            else
                if decim_cnt = DECIM_RATE - 1 then
                    decim_cnt <= to_unsigned(0, decim_cnt'length);
                else
                    decim_cnt <= decim_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- Number of samples counter logic
    process(all)
    begin
        last_sample <= '1' when
            controller_state = OUTPUT_ASSERT_S
            and num_samples_cnt = to_unsigned(FFT_SIZE - 1, num_samples_cnt'length)
        else '0';
    end process;

    -- Counter Logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                num_samples_cnt <= (others => '0');
            else
                if controller_state = OUTPUT_ASSERT_S then
                    if last_sample = '0' then
                        num_samples_cnt <= num_samples_cnt 
                                        + to_unsigned(1, num_samples_cnt'length);
                    end if;
                elsif controller_state = DONE_S then
                    num_samples_cnt <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                controller_state <= IDLE_S;
                count_pulse      <= '0';
                read_pulse       <= '0';
                fft_out_valid    <= '0';
                done             <= '0';
            else
                case controller_state is
                    when IDLE_S =>
                        if start = '1' then
                            controller_state <= READ_PULSE_S;
                        end if;
                        count_pulse   <= '0';
                        read_pulse    <= '0';
                        fft_out_valid <= '0';
                        done          <= '0';
                    
                    when READ_PULSE_S =>
                        if decim_cnt = DECIM_RATE - 1 then
                            controller_state <= READ_WAIT_S;
                            count_pulse      <= '0';
                            read_pulse       <= '1';
                            fft_out_valid    <= '0';
                        else
                            controller_state <= READ_PULSE_S;
                            count_pulse      <= '0';
                            read_pulse       <= '0';
                            fft_out_valid    <= '0';
                        end if;
                        done             <= '0';

                    when READ_WAIT_S =>
                        if read_done = '1' then
                            controller_state <= OUTPUT_ASSERT_S;
                        end if;
                        count_pulse      <= '0';
                        read_pulse       <= '0';
                        fft_out_valid    <= '0';
                        done             <= '0';
                    
                    when OUTPUT_ASSERT_S =>
                        if last_sample = '1' then
                            controller_state <= DONE_S;
                        else
                            controller_state <= READ_PULSE_S;
                        end if;
                        read_pulse       <= '0';
                        fft_out_valid    <= '1';
                        done             <= '0';

                    when DONE_S =>
                        if start = '1' then
                            controller_state <= READ_PULSE_S;
                            done             <= '0';
                        else
                            done <= '1';
                        end if;
                        count_pulse   <= '0';
                        read_pulse    <= '0';
                        fft_out_valid <= '0';
                end case;
            end if;
        end if;
    end process;

    addr <= std_logic_vector(num_samples_cnt);

end architecture;