library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity Clip is
    generic (
        WORD_WIDTH : natural := 32;
        OUT_WIDTH  : natural := 32
    );
    port
    (
        a : in  std_logic_vector((WORD_WIDTH - 1) downto 0) := (others => '0');
        q : out std_logic_vector((OUT_WIDTH - 1) downto 0)  := (others => '0')
    );
end entity;

architecture rtl of Clip is
    signal clip_neg     : std_logic;
    signal clip_pos     : std_logic;
    signal clip_bounded : std_logic;
    signal clip_filler  : std_logic_vector(OUT_WIDTH - 1 downto 0);
begin
    clip_neg                                   <= AND_REDUCE(a(a'high downto q'high));
    clip_pos                                   <= not OR_REDUCE(a(a'high downto q'high));
    clip_bounded                               <= clip_pos or clip_neg;
    clip_filler(clip_filler'high)              <= a(a'high);
    clip_filler(clip_filler'high - 1 downto 0) <= a(q'high - 1 downto 0) when (clip_bounded = '1') else (others => not a(a'high));
    q                                          <= clip_filler;
end architecture;
