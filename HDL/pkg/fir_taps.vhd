library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

-- Package for importing FIR taps via a generic array

package fir_taps is

    type taps_array is array (natural range <>) of signed(15 downto 0);
    constant NUM_TAPS_ARRAY : integer := 91;

    constant FIR_MOD_1_TAPS : taps_array(0 to NUM_TAPS_ARRAY -1) := (
        0 => x"0005",
        1 => x"0006",
        2 => x"0004",
        3 => x"0001",
        4 => x"FFFA",
        5 => x"FFF2",
        6 => x"FFEA",
        7 => x"FFE4",
        8 => x"FFE5",
        9 => x"FFED",
        10 => x"FFFD",
        11 => x"0015",
        12 => x"0030",
        13 => x"0047",
        14 => x"0053",
        15 => x"004E",
        16 => x"0034",
        17 => x"0006",
        18 => x"FFC8",
        19 => x"FF88",
        20 => x"FF55",
        21 => x"FF3D",
        22 => x"FF4D",
        23 => x"FF8D",
        24 => x"FFF7",
        25 => x"007C",
        26 => x"0104",
        27 => x"016F",
        28 => x"019C",
        29 => x"0174",
        30 => x"00EC",
        31 => x"000D",
        32 => x"FEF4",
        33 => x"FDD4",
        34 => x"FCEB",
        35 => x"FC7E",
        36 => x"FCC5",
        37 => x"FDE9",
        38 => x"FFF1",
        39 => x"02C3",
        40 => x"0623",
        41 => x"09B9",
        42 => x"0D1C",
        43 => x"0FE5",
        44 => x"11B9",
        45 => x"125C",
        46 => x"11B9",
        47 => x"0FE5",
        48 => x"0D1C",
        49 => x"09B9",
        50 => x"0623",
        51 => x"02C3",
        52 => x"FFF1",
        53 => x"FDE9",
        54 => x"FCC5",
        55 => x"FC7E",
        56 => x"FCEB",
        57 => x"FDD4",
        58 => x"FEF4",
        59 => x"000D",
        60 => x"00EC",
        61 => x"0174",
        62 => x"019C",
        63 => x"016F",
        64 => x"0104",
        65 => x"007C",
        66 => x"FFF7",
        67 => x"FF8D",
        68 => x"FF4D",
        69 => x"FF3D",
        70 => x"FF55",
        71 => x"FF88",
        72 => x"FFC8",
        73 => x"0006",
        74 => x"0034",
        75 => x"004E",
        76 => x"0053",
        77 => x"0047",
        78 => x"0030",
        79 => x"0015",
        80 => x"FFFD",
        81 => x"FFED",
        82 => x"FFE5",
        83 => x"FFE4",
        84 => x"FFEA",
        85 => x"FFF2",
        86 => x"FFFA",
        87 => x"0001",
        88 => x"0004",
        89 => x"0006",
        90 => x"0005"
    );

    constant FIR_MOD_2_TAPS : taps_array(0 to NUM_TAPS_ARRAY -1) := (
        0 => x"0005",
        1 => x"0006",
        2 => x"0004",
        3 => x"0001",
        4 => x"FFFA",
        5 => x"FFF2",
        6 => x"FFEA",
        7 => x"FFE4",
        8 => x"FFE5",
        9 => x"FFED",
        10 => x"FFFD",
        11 => x"0015",
        12 => x"0030",
        13 => x"0047",
        14 => x"0053",
        15 => x"004E",
        16 => x"0034",
        17 => x"0006",
        18 => x"FFC8",
        19 => x"FF88",
        20 => x"FF55",
        21 => x"FF3D",
        22 => x"FF4D",
        23 => x"FF8D",
        24 => x"FFF7",
        25 => x"007C",
        26 => x"0104",
        27 => x"016F",
        28 => x"019C",
        29 => x"0174",
        30 => x"00EC",
        31 => x"000D",
        32 => x"FEF4",
        33 => x"FDD4",
        34 => x"FCEB",
        35 => x"FC7E",
        36 => x"FCC5",
        37 => x"FDE9",
        38 => x"FFF1",
        39 => x"02C3",
        40 => x"0623",
        41 => x"09B9",
        42 => x"0D1C",
        43 => x"0FE5",
        44 => x"11B9",
        45 => x"125C",
        46 => x"11B9",
        47 => x"0FE5",
        48 => x"0D1C",
        49 => x"09B9",
        50 => x"0623",
        51 => x"02C3",
        52 => x"FFF1",
        53 => x"FDE9",
        54 => x"FCC5",
        55 => x"FC7E",
        56 => x"FCEB",
        57 => x"FDD4",
        58 => x"FEF4",
        59 => x"000D",
        60 => x"00EC",
        61 => x"0174",
        62 => x"019C",
        63 => x"016F",
        64 => x"0104",
        65 => x"007C",
        66 => x"FFF7",
        67 => x"FF8D",
        68 => x"FF4D",
        69 => x"FF3D",
        70 => x"FF55",
        71 => x"FF88",
        72 => x"FFC8",
        73 => x"0006",
        74 => x"0034",
        75 => x"004E",
        76 => x"0053",
        77 => x"0047",
        78 => x"0030",
        79 => x"0015",
        80 => x"FFFD",
        81 => x"FFED",
        82 => x"FFE5",
        83 => x"FFE4",
        84 => x"FFEA",
        85 => x"FFF2",
        86 => x"FFFA",
        87 => x"0001",
        88 => x"0004",
        89 => x"0006",
        90 => x"0005"
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