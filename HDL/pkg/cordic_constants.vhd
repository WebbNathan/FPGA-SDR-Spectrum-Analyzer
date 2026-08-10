library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Package for importarting the constant CORDIC angles
-- Normalized by pi
-- Currently setup for N = 15 stages

package cordic_constants is

    constant MAX_CORDIC_STAGES : positive := 15;
    constant ANGLE_WIDTH       : positive := 16;

    type angle_table_t is array (natural range <>) of
        signed(ANGLE_WIDTH - 1 downto 0);

    constant CORDIC_ANGLES :
        angle_table_t(0 to MAX_CORDIC_STAGES - 1) := (
            0  => to_signed(8192, ANGLE_WIDTH),
            1  => to_signed(4836, ANGLE_WIDTH),
            2  => to_signed(2555, ANGLE_WIDTH),
            3  => to_signed(1297, ANGLE_WIDTH),
            4  => to_signed(651,  ANGLE_WIDTH),
            5  => to_signed(326,  ANGLE_WIDTH),
            6  => to_signed(163,  ANGLE_WIDTH),
            7  => to_signed(81,   ANGLE_WIDTH),
            8  => to_signed(41,   ANGLE_WIDTH),
            9  => to_signed(20,   ANGLE_WIDTH),
            10 => to_signed(10,   ANGLE_WIDTH),
            11 => to_signed(5,    ANGLE_WIDTH),
            12 => to_signed(3,    ANGLE_WIDTH),
            13 => to_signed(1,    ANGLE_WIDTH),
            14 => to_signed(1,    ANGLE_WIDTH)
        );

end package;