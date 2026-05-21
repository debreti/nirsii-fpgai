library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Rom_SpCnt is
    generic
    (
        FILE_NAME : string  := "";
        CELLS_CNT : natural := 1;
        OUT_WIDTH : natural := 1
    );
    port
    (
        clk      : in  std_logic                                := '0';
        rst      : in  std_logic                                := '0';
        re       : in  std_logic                                := '0';
        out_data : out std_logic_vector(OUT_WIDTH - 1 downto 0) := (others => '0')
    );
end entity;

architecture rtl of Rom_SpCnt is
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃   REGISTERS   ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    signal adr_cnt : natural range 0 to (CELLS_CNT - 1) := 0;
    /* ┏━━━━━━━━━━━━━━━━┓ */
    -- ┃   COMPONENTS   ┃ --
    /* ┗━━━━━━━━━━━━━━━━┛ */
    component V_Rom_Sp
        generic (
            DATA_WIDTH : integer := 8;
            ADR_WIDTH  : integer := 8;
            CELLS_CNT  : integer := 8;
            FILE_PATH  : string  := "rom.mem"
        );
        port (
            clk : in  std_logic;
            adr : in  std_logic_vector(ADR_WIDTH - 1 downto 0);
            q   : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;
begin

    Single_Port_Rom : V_Rom_Sp
        generic map (
            DATA_WIDTH => OUT_WIDTH,
            ADR_WIDTH  => Log2Ceil(CELLS_CNT),
            CELLS_CNT  => CELLS_CNT,
            FILE_PATH  => FILE_NAME
        )
        port map (
            clk => clk,
            adr => std_logic_vector(to_unsigned(adr_cnt, Log2Ceil(CELLS_CNT))),
            q   => out_data
        );

    Adr_Counter_Seq_Logic_Arst : process(clk,rst)
    begin
        if(rst) then
            adr_cnt <= 0;
        elsif(rising_edge(clk)) then
            if(re) then
                if(adr_cnt = (CELLS_CNT - 1)) then
                    adr_cnt <= 0;
                else
                    adr_cnt <= adr_cnt + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;


