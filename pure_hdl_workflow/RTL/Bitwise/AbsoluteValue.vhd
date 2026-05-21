library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity AbsoluteValue is
    generic (
        WORD_WIDTH : natural := 32
    );
    port
    (
        a : in  std_logic_vector((WORD_WIDTH - 1) downto 0) := (others => '0');
        q : out std_logic_vector((WORD_WIDTH - 1) downto 0) := (others => '0')
    );
end entity;

architecture rtl of AbsoluteValue is
    signal a_unsigned : unsigned(WORD_WIDTH-1 downto 0) := (others => '0');
    signal xor_result : unsigned(WORD_WIDTH-1 downto 0) := (others => '0');
    signal abs_result : unsigned(WORD_WIDTH-1 downto 0) := (others => '0');
    signal msb_vector : unsigned(WORD_WIDTH-1 downto 0) := (others => '0');
    signal carry      : unsigned(WORD_WIDTH-1 downto 0) := (others => '0'); -- MSB of a is saved in LSB
begin
    a_unsigned <= unsigned(a);
    msb_vector <= (others => a(a'high)); -- replicate MSB for XOR
    xor_result <= a_unsigned xor msb_vector;
    carry(0)   <= a(a'high); -- Saving sign as carry / carry <= (0 => a(a'high), others => '0');
    abs_result <= xor_result + carry;
    q          <= std_logic_vector(abs_result);
end architecture;