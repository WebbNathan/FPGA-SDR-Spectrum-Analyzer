library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_accu is
    generic(
        ACCU_WIDTH : integer := 16;
        PHASE_INCR : integer := 5243 -- 10Mhz with a 125Mhz clk
    );

    port (
        clk      : in std_logic;
        reset    : in std_logic;
        accu_out : out std_logic_vector(ACCU_WIDTH - 1 downto 0)
    );
end phase_accu;

architecture rtl of phase_accu is
    signal accu : signed(ACCU_WIDTH - 1 downto 0) := (others => '0');
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                accu <= (others => '0');
            else
                accu <= accu + PHASE_INCR;
            end if;
        end if;

    accu_out <= std_logic_vector(accu);
    end process;

end architecture;