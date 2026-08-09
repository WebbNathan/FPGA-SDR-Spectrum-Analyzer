library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mixer is
    generic(
        CORDIC_STAGE     : integer := 15; -- Amount of stages implemented for the NCO CORDIC algorithim
        AMPLITUDE_WIDTH  : integer := 16 -- Bit width of the input signal
    );

    port(
        clk        : in std_logic;
        reset      : in std_logic;
        phase_incr : in std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);
        signal_in  : in std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);
        
        I_val      : out std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);
        Q_val      : out std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);

        -- Control Signals
        in_valid   : in std_logic;
        out_valid  : out std_logic
    );
end mixer;

architecture rtl of mixer is
    signal NCO_I_val_out        : std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);
    signal NCO_Q_val_out        : std_logic_vector(AMPLITUDE_WIDTH -1 downto 0);

    signal MIXER_I_val_mult_reg : signed((2 * AMPLITUDE_WIDTH) -1 downto 0); -- Size to twice the size due to multiplication
    signal MIXER_Q_val_mult_Reg : signed((2 * AMPLITUDE_WIDTH) -1 downto 0); -- Size to twice the size due to multiplication

    -- Control Signals
    signal NCO_out_valid        : std_logic;
    signal out_valid_reg        : std_logic;
begin

    nco_inst : entity work.nco
    generic map(
        CORDIC_STAGE => CORDIC_STAGE,
        ANGLE_WIDTH  => AMPLITUDE_WIDTH
    )
    port map(
        clk        => clk,
        reset      => reset,
        phase_incr => phase_incr,

        I_val      => NCO_I_val_out,
        Q_val      => NCO_Q_val_out,

        -- Control Signals
        in_valid   => in_valid,
        out_valid  => NCO_out_valid
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                MIXER_I_val_mult_reg <= (others => '0');
                MIXER_Q_val_mult_Reg <= (others => '0');
                out_valid_reg        <= '0';
            elsif NCO_out_valid = '1' then
                MIXER_I_val_mult_reg <= signed(NCO_I_val_out) * signed(signal_in);
                MIXER_Q_val_mult_Reg <= signed(NCO_Q_val_out) * signed(signal_in);
                out_valid_reg        <= '1';
            else
                out_valid_reg        <= '0';
            end if;
        end if;
    end process;

    I_val              <= std_logic_vector(MIXER_I_val_mult_reg(30 downto 15)); -- Bitshift to rescale after multiplication
    Q_val              <= std_logic_vector(MIXER_Q_val_mult_Reg(30 downto 15)); -- Bitshift to rescale after multiplication

    out_valid          <= out_valid_reg;

end architecture;