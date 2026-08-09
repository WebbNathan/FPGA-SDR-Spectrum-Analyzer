library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

entity mixer_tb is
end entity mixer_tb;

architecture sim of mixer_tb is

    constant CLK_PERIOD       : time    := 400 ns; --2.5MHz
    constant AMPLITUDE_WIDTH  : integer := 16;
    constant PHASE_INCR       : integer := 2621; -- ~100kHz
    constant CORDIC_STAGE     : integer := 15;

    signal phase_incr_in      : std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);
    signal signal_in          : std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);

    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';

    signal in_valid           : std_logic;
    signal out_valid          : std_logic;

    signal I_val              : std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);
    signal Q_val              : std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);

    file input_file           : text open read_mode  is "sim/mixer_in.txt";
    file output_file          : text open write_mode is "sim/mixer_out.txt";        

begin

    -- Device under test
    dut : entity work.mixer
        generic map (
            AMPLITUDE_WIDTH  => AMPLITUDE_WIDTH,
            CORDIC_STAGE     => CORDIC_STAGE
        )
        port map (
            clk        => clk,
            reset      => reset,
            phase_incr => phase_incr_in,
            signal_in  => signal_in,
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

    stim_proc : process
        variable input_line : line;
        variable sample_int : integer;
    begin

        -- Hold reset active
        reset         <= '1';
        phase_incr_in <= std_logic_vector(to_signed(PHASE_INCR, phase_incr_in'length));
        wait for 2 * CLK_PERIOD;

        -- Release reset near a clock edge
        wait until falling_edge(clk);
        reset <= '0';

        while not endfile(input_file) loop

            readline(input_file, input_line);
            read(input_line, sample_int);

            signal_in <= std_logic_vector(to_signed(sample_int, signal_in'length));
            in_valid  <= '1';

            wait until rising_edge(clk);

        end loop;

        in_valid <= '0';

        wait;
    end process;

    output_proc : process(clk)
        variable output_line : line;
    begin
        if rising_edge(clk) then

            if out_valid = '1' then

                write(output_line, to_integer(signed(I_val)));

                write(output_line, string'(" "));

                write(output_line, to_integer(signed(Q_val)));

                writeline(output_file, output_line);

            end if;

        end if;
    end process;

end architecture;