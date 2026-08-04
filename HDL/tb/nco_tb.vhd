library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nco_tb is
end entity nco_tb;

architecture sim of nco_tb is

    constant CLK_PERIOD   : time    := 10 ns;
    constant ANGLE_WIDTH  : integer := 16;
    constant PHASE_INCR   : integer := 5243; -- ~10MHz
    constant CORDIC_STAGE : integer := 15;

    signal phase_incr_in  : std_logic_vector(ANGLE_WIDTH -1 downto 0);

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';

    signal in_valid       : std_logic;
    signal out_valid      : std_logic;

    signal I_val          : std_logic_vector(ANGLE_WIDTH -1 downto 0);
    signal Q_val          : std_logic_vector(ANGLE_WIDTH -1 downto 0);

begin

    -- Device under test
    dut : entity work.nco
        generic map (
            ANGLE_WIDTH  => ANGLE_WIDTH,
            CORDIC_STAGE => CORDIC_STAGE
        )
        port map (
            clk        => clk,
            reset      => reset,
            phase_incr => phase_incr_in,
            I_val      => I_val,
            Q_val      => Q_val,
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
        reset         <= '1';
        in_valid      <= '1';
        phase_incr_in <= std_logic_vector(to_signed(PHASE_INCR, phase_incr_in'length));
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        wait;

    end process;
end architecture;