library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cordic_pipeline_tb is
end entity cordic_pipeline_tb;

architecture sim of cordic_pipeline_tb is

    constant CLK_PERIOD  : time    := 10 ns;
    constant ANGLE_WIDTH : integer := 16;
    constant N           : integer := 15;
    constant PHASE_INCR  : integer := 5243;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';

    signal angle_in      : std_logic_vector(ANGLE_WIDTH -1 downto 0);

    signal I_val_out     : std_logic_vector(ANGLE_WIDTH -1 downto 0);
    signal Q_val_out     : std_logic_vector(ANGLE_WIDTH -1 downto 0);

    signal in_valid      : std_logic;
    signal out_valid     : std_logic;

begin

    -- Device under test
    dut : entity work.cordic_pipeline
        generic map (
            N           => N,
            ANGLE_WIDTH => ANGLE_WIDTH
        )
        port map (
            clk           => clk,
            reset         => reset,
            angle_pi_norm => angle_in,
            I_val         => I_val_out,
            Q_val         => Q_val_out,
            in_valid      => in_valid,
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

    -- Input stimulus
    stimulus_process : process
    begin

        angle_in <= std_logic_vector(to_signed(4000, 16)); -- Test with 4000

        -- Hold reset active
        reset <= '1';
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        wait for 2 * CLK_PERIOD; -- Ensure no output before in_valid = '1'
        in_valid <= '1';

        wait;

    end process;

end architecture sim;