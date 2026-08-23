library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

-- Package for importing FIR taps via a generic array

package fir_taps is

    type taps_array is array (natural range <>) of signed(15 downto 0);

    function create_sub_tap_array(
        NUM_TAPS   : integer;
        TAPS       : taps_array;
        BRANCH_NUM : integer;
        DECIM_RATE : integer
    ) return taps_array;

    impure function load_taps( -- For use in testbenches
        file_name : string;
        num_taps  : positive
    ) return taps_array;

end package;

package body fir_taps is

    function create_sub_tap_array(
        NUM_TAPS   : integer;
        TAPS       : taps_array;
        BRANCH_NUM : integer;
        DECIM_RATE : integer
    ) return taps_array is

        constant SUB_TAPS : integer :=
            (NUM_TAPS + DECIM_RATE - 1) / DECIM_RATE; -- Ceiling of NUM_TAPS / DECIM_RATE

        variable result : taps_array(0 to SUB_TAPS -1) :=
            (others => (others => '0'));

    begin
        for i in 0 to SUB_TAPS -1 loop
            result(i) := TAPS(DECIM_RATE * i + BRANCH_NUM)
                         when (DECIM_RATE * i + BRANCH_NUM) < NUM_TAPS
                         else (others => '0');
        end loop;

        return result;
    end function;

    impure function load_taps( -- Generated with AI
        file_name : string;
        num_taps  : positive
    ) return taps_array is

        file tap_file : text open read_mode is file_name;

        variable line_buf : line;
        variable value    : integer;

        variable result : taps_array(0 to num_taps -1) :=
            (others => (others => '0'));

        variable i : natural := 0;

    begin

        while not endfile(tap_file) and i < num_taps loop

            readline(tap_file, line_buf);
            read(line_buf, value);

            result(i) := to_signed(value, result(i)'length);

            i := i + 1;

        end loop;

        return result;

    end function;

end package body;