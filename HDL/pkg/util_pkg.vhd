-- utils_pkg.vhd

library ieee;
use ieee.std_logic_1164.all;

package util_pkg is

    function clog2(n : positive) return natural;

end package;


package body util_pkg is

    function clog2(n : positive) return natural is
        variable value  : natural := n - 1;
        variable result : natural := 0;
    begin
        while value > 0 loop
            value := value / 2;
            result := result + 1;
        end loop;

        return result;
    end function;

end package body;