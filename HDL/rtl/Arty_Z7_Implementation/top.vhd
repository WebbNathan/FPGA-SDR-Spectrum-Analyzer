----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/02/2026 12:17:25 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    port(
        clk       : in std_logic;
        reset_btn : in std_logic;
        led       : out std_logic
    );
end top;

architecture Behavioral of top is
    
    signal reset_meta : std_logic := '1';
    signal reset      : std_logic := '1';

    signal sample_in  : std_logic_vector(15 downto 0);
    signal in_valid   : std_logic;
    signal fft_out    : std_logic_vector(31 downto 0);
    signal out_valid  : std_logic;

    signal heartbeat  : unsigned(26 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            reset_meta <= reset_btn;
            reset      <= reset_meta;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                heartbeat <= (others => '0');
            else
                heartbeat <= heartbeat + 1;
            end if;
        end if;
    end process;

    led <= heartbeat(26);

    tone_source : entity work.test_tone_rom
        port map (
            clk        => clk,
            reset      => reset,
            signal_out => sample_in,
            out_valid  => in_valid
        );

    analyzer : entity work.spectrum_analyzer
        port map (
            clk        => clk,
            reset      => reset,
            signal_in  => sample_in,
            in_valid   => in_valid,
            signal_out => fft_out,
            out_valid  => out_valid
        );

end Behavioral;
