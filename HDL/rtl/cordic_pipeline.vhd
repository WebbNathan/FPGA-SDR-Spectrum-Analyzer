library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cordic_constants.all;

entity cordic_pipeline is
    generic(
        N             : integer := 16; -- Number of iterations of the CORDIC algorithim
        K_INV         : integer := 19898; -- Inverse of scaling constant ~1/1.64676025786
        UPPER_BOUND   : integer := 16384; -- Upper angle limit (pi/2 normalized by pi)
        LOWER_BOUND   : integer := -16384; -- Lower angle limit (-pi/2 normalized by pi)
        ANGLE_WIDTH   : integer := 16 -- Bit width of the angles
    );

    port(
        -- Logic Signals In
        clk           : in std_logic;
        reset         : in std_logic;
        angle_pi_norm : in std_logic_vector(ANGLE_WIDTH -1 downto 0);
        
        -- Logic Signals Out
        I_val     : out std_logic_vector(ANGLE_WIDTH -1 downto 0);
        Q_val     : out std_logic_vector(ANGLE_WIDTH -1 downto 0);

        -- Control Signals In
        in_valid   : in  std_logic;

        -- Control Signals Out
        out_valid  : out std_logic
    );
end cordic_pipeline;

architecture rtl of cordic_pipeline is
    type signed_arr_ANGLE_WIDTH_bit is array (natural range <>) of
        signed(ANGLE_WIDTH -1 downto 0);
    
    type logic_arr is array (natural range <>) of
        std_logic;

    -- Initial Stage Internal Logic
    signal g_upper                      : std_logic; -- Input angle is greater than defined upper bound (UPPER_BOUND)
    signal l_lower                      : std_logic; -- Input angle is less than defined lower bound (LOWER_BOUND)
    signal sel                          : std_logic_vector(1 downto 0);
    signal neg_cos                      : std_logic;
    signal lower_bound_angle_shft_wide  : signed(ANGLE_WIDTH downto 0); -- Widened to accomadate bit shift
    signal upper_bound_angle_shft_wide  : signed(ANGLE_WIDTH downto 0); -- Widened to accomadate bit shift
    signal lower_bound_angle_shft       : signed(ANGLE_WIDTH -1 downto 0);
    signal upper_bound_angle_shft       : signed(ANGLE_WIDTH -1 downto 0);

    -- Inital Stage Logic Outputs
    signal angle_pi_norm_corrected      : signed(ANGLE_WIDTH -1 downto 0); -- Angle wrapped into correct quadrant

    -- Pipeline Outputs
    signal I_val_pipeline_out           : signed_arr_ANGLE_WIDTH_bit(0 to N -1);
    signal Q_val_pipeline_out           : signed_arr_ANGLE_WIDTH_bit(0 to N -1);
    signal angle_err_pipeline_out       : signed_arr_ANGLE_WIDTH_bit(0 to N -1);
    
    -- Pipeline Registers
    signal registers_cordic_angle       : signed_arr_ANGLE_WIDTH_bit(0 to N -1);
    signal registers_angle_err          : signed_arr_ANGLE_WIDTH_bit(0 to N -1);
    signal registers_I_vals             : signed_arr_ANGLE_WIDTH_bit(0 to N -1);
    signal registers_Q_vals             : signed_arr_ANGLE_WIDTH_bit(0 to N -1);
    signal registers_neg_cos            : logic_arr(0 to N -1);
    signal registers_out_valid          : logic_arr(0 to N -1);

    -- Pipeline Out Registers
    signal I_val_output_reg             : signed(ANGLE_WIDTH -1 downto 0);
    signal Q_val_output_reg             : signed(ANGLE_WIDTH -1 downto 0);
    signal out_valid_output_reg         : std_logic;
begin

    g_upper <= '1' when to_integer(signed(angle_pi_norm)) > UPPER_BOUND else '0';
    l_lower <= '1' when to_integer(signed(angle_pi_norm)) < LOWER_BOUND else '0';

    sel <= g_upper & l_lower;

    lower_bound_angle_shft_wide <= -resize(signed(angle_pi_norm), 17) + shift_left(to_signed(LOWER_BOUND, 17), 1);
    upper_bound_angle_shft_wide <= -resize(signed(angle_pi_norm), 17) + shift_left(to_signed(UPPER_BOUND, 17), 1);
    lower_bound_angle_shft <= resize(lower_bound_angle_shft_wide, lower_bound_angle_shft'length);
    upper_bound_angle_shft <= resize(upper_bound_angle_shft_wide, upper_bound_angle_shft'length);

    process(angle_pi_norm, lower_bound_angle_shft, 
            upper_bound_angle_shft, sel)
    begin
        case sel is
            when "00"   => angle_pi_norm_corrected <= signed(angle_pi_norm);
            when "01"   => angle_pi_norm_corrected <= lower_bound_angle_shft;
            when "10"   => angle_pi_norm_corrected <= upper_bound_angle_shft;
            when others => angle_pi_norm_corrected <= (others => '0'); -- Not a possible state
        end case;
    end process;

    neg_cos <= g_upper or l_lower;

    gen_modules : for i in 0 to N - 1 generate
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then -- If module is reset
                    registers_cordic_angle(i) <= CORDIC_ANGLES(i);
                    registers_angle_err(i)    <= (others => '0');
                    registers_I_vals(i)       <= (others => '0');
                    registers_Q_vals(i)       <= (others => '0');
                    registers_neg_cos(i)      <= '0';
                    registers_out_valid(i)    <= '0';
                else
                    if i = 0 then -- These registers wire into initial stage of pipeline
                        if in_valid = '0' then -- Input into pipeline must be valid
                            registers_angle_err(i) <= (others => '0');
                            registers_I_vals(i)    <= (others => '0');
                            registers_Q_vals(i)    <= (others => '0');
                            registers_neg_cos(i)   <= '0';
                            registers_out_valid(i) <= '0';
                        else
                            registers_angle_err(i) <= angle_pi_norm_corrected; -- Initial corrected angle
                            registers_I_vals(i)    <= to_signed(K_INV, registers_I_vals(i)'length); -- Initial I val
                            registers_Q_vals(i)    <= (others => '0'); -- Initial Q val
                            registers_neg_cos(i)   <= neg_cos;
                            registers_out_valid(i) <= '1';
                        end if;
                    else -- Pipeline registers wired to a previous pipeline stage
                        registers_angle_err(i) <= angle_err_pipeline_out(i -1);
                        registers_I_vals(i)    <= I_val_pipeline_out(i -1);
                        registers_Q_vals(i)    <= Q_val_pipeline_out(i -1);
                        registers_neg_cos(i)   <= registers_neg_cos(i -1);
                        registers_out_valid(i) <= registers_out_valid(i -1);
                    end if;
                end if;
            end if;

        end process;
        
        process(all)
        begin
            if registers_angle_err(i) > 0 then
                I_val_pipeline_out(i)     <= registers_I_vals(i) + shift_right(registers_Q_vals(i), i);
                Q_val_pipeline_out(i)     <= registers_Q_vals(i) - shift_right(registers_I_vals(i), i);
                angle_err_pipeline_out(i) <= registers_angle_err(i) - registers_cordic_angle(i);
            else
                I_val_pipeline_out(i)     <= registers_I_vals(i) - shift_right(registers_Q_vals(i), i);
                Q_val_pipeline_out(i)     <= registers_Q_vals(i) + shift_right(registers_I_vals(i), i);
                angle_err_pipeline_out(i) <= registers_angle_err(i) + registers_cordic_angle(i);
            end if;
        end process;
    end generate gen_modules;

    process(clk)
    begin
        if rising_edge(clk) then
            I_val_output_reg     <= I_val_pipeline_out(N -1);
            Q_val_output_reg     <= Q_val_pipeline_out(N -1);
            out_valid_output_reg <= registers_out_valid(N -1);
        end if;
    end process;

    I_val     <= std_logic_vector(I_val_output_reg) when registers_neg_cos(N -1) = '0'
                 else std_logic_vector(-I_val_output_reg);
    Q_val     <= std_logic_vector(Q_val_output_reg);
    out_valid <= out_valid_output_reg;


end architecture;