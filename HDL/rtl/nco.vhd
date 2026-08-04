library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nco is
    generic(
        CORDIC_STAGE : integer := 15;
        ANGLE_WIDTH  : integer := 16
    );

    port(
        clk        : in std_logic;
        reset      : in std_logic;
        phase_incr : in std_logic_vector(ANGLE_WIDTH -1 downto 0);
        
        I_val      : out std_logic_vector(ANGLE_WIDTH -1 downto 0);
        Q_val      : out std_logic_vector(ANGLE_WIDTH -1 downto 0);

        -- Control Signals
        in_valid   : in std_logic;
        out_valid  : out std_logic
    );
end nco;

architecture rtl of nco is
    signal phase_accu_out       : std_logic_vector(ANGLE_WIDTH -1 downto 0);
    signal phase_accu_out_valid : std_logic;
begin

    phase_accu_inst : entity work.phase_accu
    generic map (
        ACCU_WIDTH => ANGLE_WIDTH
    )
    port map (
        clk        => clk,
        reset      => reset,
        phase_incr => phase_incr,
        accu_out   => phase_accu_out,

        -- Control Signals
        in_valid   => in_valid,
        out_valid  => phase_accu_out_valid
    );

    cordic_pipeline_inst : entity work.cordic_pipeline
    generic map (
        N           => CORDIC_STAGE,
        ANGLE_WIDTH => ANGLE_WIDTH
    )
    port map (
        clk           => clk,
        reset         => reset,
        angle_pi_norm => phase_accu_out,
        I_val         => I_val,
        Q_val         => Q_val,

        -- Control Signals
        in_valid      => phase_accu_out_valid,
        out_valid     => out_valid
    );

end architecture;