library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity ReLu_nEn is
    generic (
        WORD_WIDTH : natural := 32
    );
    port
    (
        n_en : in  std_logic                                   := '0';
        a    : in  std_logic_vector((WORD_WIDTH - 1) downto 0) := (others => '0');
        q    : out std_logic_vector((WORD_WIDTH - 1) downto 0) := (others => '0')
    );
end entity;

architecture rtl of ReLu_nEn is
    signal en_mask : std_logic_vector((a'high - 1) downto 0);
begin
    en_mask                  <= (others => (not n_en) nand a(a'high));
    q(q'high)                <= n_en and a(a'high);
    q((q'high - 1) downto 0) <= a((a'high - 1) downto 0) and en_mask;
end architecture;