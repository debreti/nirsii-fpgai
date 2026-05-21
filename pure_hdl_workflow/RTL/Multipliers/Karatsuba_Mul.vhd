library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity Karatsuba_Mul is
    generic (
        C_WIDTH : natural := 32
    );
    port (
        clk      : in  std_logic                                  := '0';
        a        : in  std_logic_vector(C_WIDTH - 1 downto 0)     := (others => '0');
        b        : in  std_logic_vector(C_WIDTH - 1 downto 0)     := (others => '0');
        data_out : out std_logic_vector((2*C_WIDTH) - 1 downto 0) := (others => '0')
    );
end Karatsuba_Mul;

architecture rtl of Karatsuba_Mul is
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    CONSTANTS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    constant s  : unsigned(C_WIDTH/2 - 1 downto 0) := (others => '0');
    constant s2 : unsigned(C_WIDTH - 1 downto 0)   := (others => '0');
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    REGISTERS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    signal a_right          : unsigned(C_WIDTH / 2 - 1 downto 0)          := (others => '0');
    signal a_left           : unsigned(C_WIDTH / 2 - 1 downto 0)          := (others => '0');
    signal b_right          : unsigned(C_WIDTH / 2 - 1 downto 0)          := (others => '0');
    signal b_left           : unsigned(C_WIDTH / 2 - 1 downto 0)          := (others => '0');
    signal X                : unsigned(C_WIDTH - 1 downto 0)              := (others => '0');
    signal Y                : unsigned(C_WIDTH - 1 downto 0)              := (others => '0');
    signal x_add_y          : unsigned(C_WIDTH downto 0)                  := (others => '0');
    signal T0               : unsigned(C_WIDTH/2 downto 0)                := (others => '0');
    signal T1               : unsigned(C_WIDTH/2 downto 0)                := (others => '0');
    signal z                : unsigned(C_WIDTH + 1 downto 0)              := (others => '0');
    signal xs2_y, xs2_y_dff : unsigned(X'length + C_WIDTH-1 downto 0)     := (others => '0');
    signal zs               : unsigned(Z'length + C_WIDTH/2 - 1 downto 0) := (others => '0');
begin
    Seq_Logic : process(clk) begin
        if rising_edge(clk) then
            a_right   <= unsigned(a(a'length / 2 - 1 downto 0));
            a_left    <= unsigned(a(a'length - 1 downto a'length / 2));
            b_right   <= unsigned(b(b'length / 2 - 1 downto 0));
            b_left    <= unsigned(b(b'length - 1 downto b'length / 2));
            X         <= a_left * b_left;
            Y         <= a_right * b_right;
            T0        <= ('0' & a_left) + ('0'& a_right);
            T1        <= ('0' & b_left) + ('0'& b_right);
            z         <= T0 * T1;
            x_add_y   <= ('0' & X) + ('0' & Y);
            xs2_y     <= (x & s2 ) + Y;
            zs        <= (z - x_add_y)&s;
            xs2_y_dff <= xs2_y;
            data_out  <= std_logic_vector(zs + xs2_y_dff);
        end if;
    end process;
end architecture;

