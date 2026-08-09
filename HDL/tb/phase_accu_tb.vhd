library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

entity phase_accu_tb is
end entity phase_accu_tb;

architecture sim of phase_accu_tb is

    constant CLK_PERIOD   : time    := 400 ns; --2.5MHz
    constant ACCU_WIDTH   : integer := 16;

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';

    signal phase_incr     : std_logic_vector(ACCU_WIDTH -1 downto 0);
    signal phase_accu_out : std_logic_vector(ACCU_WIDTH - 1 downto 0);

    signal in_valid       : std_logic;
    signal out_valid      : std_logic;

    file output_file      : text open write_mode is "sim/phase_accu_out.txt";    
begin

    -- Device under test
    dut : entity work.phase_accu
        generic map (
            ACCU_WIDTH => ACCU_WIDTH
        )
        port map (
            clk        => clk,
            reset      => reset,
            phase_incr => phase_incr,
            accu_out   => phase_accu_out,
            in_valid   => in_valid,
            out_valid  => out_valid
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

    -- Input stimulus
    stimulus_process : process
    begin

        -- Hold reset active
        phase_incr <= std_logic_vector(to_signed(2621, 16)); -- ~100kHz
        reset      <= '1';
        in_valid   <= '1';
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        wait;

    end process;

    output_proc : process(clk)
        variable output_line : line;
    begin
        if rising_edge(clk) then

            if out_valid = '1' then

                write(output_line, to_integer(signed(phase_accu_out)));

                writeline(output_file, output_line);

            end if;

        end if;
    end process;

end architecture sim;