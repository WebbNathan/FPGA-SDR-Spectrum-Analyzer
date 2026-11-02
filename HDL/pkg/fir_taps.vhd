library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

-- Package for importing FIR taps via a generic array

package fir_taps is

    type taps_array is array (natural range <>) of signed(15 downto 0);
    constant NUM_TAPS_ARRAY : integer := 39;

    constant FIR_MOD_1_TAPS : taps_array(0 to NUM_TAPS_ARRAY -1) := (
        0 => x"FFF6",
        1 => x"FFEF",
        2 => x"0012",
        3 => x"0043",
        4 => x"0011",
        5 => x"FF7D",
        6 => x"FF70",
        7 => x"0084",
        8 => x"016E",
        9 => x"0037",
        10 => x"FDBE",
        11 => x"FDE9",
        12 => x"021F",
        13 => x"0512",
        14 => x"0062",
        15 => x"F77F",
        16 => x"F82B",
        17 => x"0B46",
        18 => x"269E",
        19 => x"33AB",
        20 => x"269E",
        21 => x"0B46",
        22 => x"F82B",
        23 => x"F77F",
        24 => x"0062",
        25 => x"0512",
        26 => x"021F",
        27 => x"FDE9",
        28 => x"FDBE",
        29 => x"0037",
        30 => x"016E",
        31 => x"0084",
        32 => x"FF70",
        33 => x"FF7D",
        34 => x"0011",
        35 => x"0043",
        36 => x"0012",
        37 => x"FFEF",
        38 => x"FFF6"
    );

    constant FIR_MOD_2_TAPS : taps_array(0 to NUM_TAPS_ARRAY -1) := (
        0 => x"FFF6",
        1 => x"FFEF",
        2 => x"0012",
        3 => x"0043",
        4 => x"0011",
        5 => x"FF7D",
        6 => x"FF70",
        7 => x"0084",
        8 => x"016E",
        9 => x"0037",
        10 => x"FDBE",
        11 => x"FDE9",
        12 => x"021F",
        13 => x"0512",
        14 => x"0062",
        15 => x"F77F",
        16 => x"F82B",
        17 => x"0B46",
        18 => x"269E",
        19 => x"33AB",
        20 => x"269E",
        21 => x"0B46",
        22 => x"F82B",
        23 => x"F77F",
        24 => x"0062",
        25 => x"0512",
        26 => x"021F",
        27 => x"FDE9",
        28 => x"FDBE",
        29 => x"0037",
        30 => x"016E",
        31 => x"0084",
        32 => x"FF70",
        33 => x"FF7D",
        34 => x"0011",
        35 => x"0043",
        36 => x"0012",
        37 => x"FFEF",
        38 => x"FFF6"
    );

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