library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.util_pkg.all;
use work.fir_taps.all;

entity fir_decim_sub_tb is
end entity fir_decim_sub_tb;

architecture sim of fir_decim_sub_tb is
    constant CLK_PERIOD       : time    := 8 ns; -- 125MHz
    constant DATA_WIDTH       : integer := 16;
    constant NUM_TAPS         : integer := 5;
    constant TAPS             : taps_array(0 to NUM_TAPS -1) := (
                                                                to_signed(14000, DATA_WIDTH),
                                                                to_signed(16000, DATA_WIDTH),
                                                                to_signed(18000, DATA_WIDTH),
                                                                to_signed(20000, DATA_WIDTH),
                                                                to_signed(22000, DATA_WIDTH)
                                );
    constant DECIM_FACTOR     : integer := 2;
    constant R_WIDTH          : natural := clog2(DECIM_FACTOR);

    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';

    signal signal_in          : std_logic_vector(DATA_WIDTH -1 downto 0);
    signal signal_out         : std_logic_vector(DATA_WIDTH -1 downto 0);

    signal out_valid          : std_logic;

    -- Decimator logic
    signal decim_cnt          : unsigned(R_WIDTH - 1 downto 0); 
    signal decim_pulse        : std_logic; -- in_valid for module
begin

     -- Device under test
    dut : entity work.fir_decim_sub
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            NUM_TAPS   => NUM_TAPS,
            TAPS       => TAPS
        )
        port map (
            clk           => clk,
            reset         => reset,
            signal_in     => signal_in,
            signal_out    => signal_out,
            in_valid      => decim_pulse,
            out_valid     => out_valid
        );

     -- Clock generator
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Decimation counter
    decim_pulse_process : process
    begin
        while true loop
            wait until rising_edge(clk);
            decim_pulse <= '0';
            if reset = '1' then
                decim_cnt   <= (others => '0');
                decim_pulse <= '0';
            else
                if decim_cnt = to_unsigned(DECIM_FACTOR -1, decim_cnt'length) then
                    decim_cnt   <= (others => '0');
                    decim_pulse <= '1';
                else
                    decim_pulse <= '0';
                end if;
                
                decim_cnt <= decim_cnt + 1;
            end if;
        end loop;
    end process;

    -- Input stimulus
    stimulus_proc : process
    begin

        -- Hold reset active
        reset <= '1';
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        signal_in <= std_logic_vector(to_signed(32767, signal_in'length));
        wait for 40*CLK_PERIOD;
        signal_in <= std_logic_vector(to_signed(0, signal_in'length));

    end process;

end architecture;