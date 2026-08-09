library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_accu is
    generic(
        ACCU_WIDTH : integer := 16
    );

    port (
        clk        : in std_logic;
        reset      : in std_logic;
        phase_incr : in std_logic_vector(ACCU_WIDTH -1 downto 0);
        accu_out   : out std_logic_vector(ACCU_WIDTH - 1 downto 0);

        -- Control Signals
        in_valid   : in std_logic;
        out_valid  : out std_logic
    );
end phase_accu;

architecture rtl of phase_accu is
    signal accu           : signed(ACCU_WIDTH - 1 downto 0) := (others => '0');
    signal phase_incr_reg : signed(ACCU_WIDTH - 1 downto 0) := (others => '0');
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                accu      <= (others => '0');
                out_valid <= '0';
            elsif(in_valid = '1') then
                phase_incr_reg <= signed(phase_incr);
                accu           <= accu + phase_incr_reg;
                out_valid      <= '1';
            else
                out_valid      <= '0';
            end if;
        end if;

    accu_out <= std_logic_vector(accu);
    end process;

end architecture;