library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Counter_Q is
    generic
    (
        CNT_MAX : natural := 1
    );
    port
    (
        clk      : in  std_logic                                        := '0';
        rst      : in  std_logic                                        := '0';
        en       : in  std_logic                                        := '0';
        out_data : out std_logic_vector(Log2Ceil(CNT_MAX) - 1 downto 0) := (others => '0')
    );
end entity;

architecture rtl of Counter_Q is
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    signal max : std_logic                        := '0';
    signal cnt : natural range 0 to (CNT_MAX - 1) := 0;
begin

    max      <= '1' when cnt = (CNT_MAX - 1) else '0';
    out_data <= std_logic_vector(to_unsigned(cnt, Log2Ceil(CNT_MAX)));

    Seq_Logic_Arst : process(clk, rst)
    begin
        if(rst) then
            cnt <= 0;
        elsif(rising_edge(clk)) then
            if(en) then
                if(max) then
                    cnt <= 0;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;