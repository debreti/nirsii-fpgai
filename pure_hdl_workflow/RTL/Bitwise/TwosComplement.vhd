library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity TwosComplement is
    generic (
        WORD_WIDTH : natural := 32
    );
    port
    (
        a : in  std_logic_vector((WORD_WIDTH - 1) downto 0) := (others => '0');
        q : out std_logic_vector((WORD_WIDTH - 1) downto 0) := (others => '0')
    ); 
end entity;

architecture rtl of TwosComplement is
begin
    q <= std_logic_vector(-signed(a));
end architecture;