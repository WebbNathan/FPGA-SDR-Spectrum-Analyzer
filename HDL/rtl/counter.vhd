library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

-- Module to keep track of current stage and butterfly

entity counter is
    generic(
        N     : integer := 1024; -- Number of samples in FFT, should be a power of 2
        LOG_N : integer := 10 -- log2(N) 
    );
    port(
        clk       : in std_logic;
        reset     : in std_logic;
        
        pulse_in  : in std_logic; -- Pulse 1 to increment counter
        pulse_out : out std_logic; -- Output 1 if increment complete

        i_out     : out std_logic_vector(clog2(LOG_N + 1) -1 downto 0); -- Stage counter
        j_out     : out std_logic_vector(clog2(N/2) -1 downto 0) -- Butterfly counter
    );
end counter;

architecture rtl of counter is
    constant J_OUT_TERM_VAL : integer := (N/2) -1;
begin

    -- Counter logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pulse_out <= '1';
                i_out     <= (others => '0');
                j_out     <= (others => '0');
            else
                if pulse_in = '1' then
                    if unsigned(j_out) = to_unsigned(J_OUT_TERM_VAL, j_out'length) then
                        i_out     <= std_logic_vector(unsigned(i_out) +1);
                    end if;
                    j_out     <= std_logic_vector(unsigned(j_out) +1);
                    pulse_out <= '1';
                else
                    pulse_out <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture;