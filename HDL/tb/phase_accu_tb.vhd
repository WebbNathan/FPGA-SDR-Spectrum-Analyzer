library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_accu_tb is
end entity phase_accu_tb;

architecture sim of phase_accu_tb is

    constant CLK_PERIOD : time    := 10 ns;
    constant ACCU_WIDTH : integer := 16;
    constant PHASE_INCR : integer := 5243;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';

    signal phase_accu_out : std_logic_vector(ACCU_WIDTH - 1 downto 0);

begin

    -- Device under test
    dut : entity work.phase_accu
        generic map (
            ACCU_WIDTH => ACCU_WIDTH,
            PHASE_INCR => PHASE_INCR
        )
        port map (
            clk      => clk,
            reset    => reset,
            accu_out => phase_accu_out
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
        reset <= '1';
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        wait;

    end process;

end architecture sim;