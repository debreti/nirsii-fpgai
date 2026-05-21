library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Test_ROM is
    generic
    (
        FILE_NAME : string  := "";
        CELLS_CNT : natural := 1;
        OUT_WIDTH : natural := 1
    );
    port
    (
        clk         : in  std_logic                                := '0';
        rst         : in  std_logic                                := '0';
        s_axi_ready : in  std_logic                                := '0';
        m_axi_valid : out std_logic                                := '0';
        out_data    : out std_logic_vector(OUT_WIDTH - 1 downto 0) := (others => '0')
    );
end entity;

architecture Axi_Feeder of Test_ROM is
    /* ┏━━━━━━━━━━━┓ */
    -- ┃    FSM    ┃ --
    /* ┗━━━━━━━━━━━┛ */
    type t_state is (ValidSet, SlaveWait, Rom_Empty);
    signal state : t_state := ValidSet;
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
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

    Seq_Logic_Fsm_Arst : process(clk, rst)
    begin
        if(rst) THEN
            m_axi_valid <= '0';
            adr_cnt     <= 0;
            state       <= ValidSet;
        elsif rising_edge(clk) then
            case state is
                when ValidSet =>
                    m_axi_valid <= '1';
                    state       <= SlaveWait;
                when SlaveWait =>
                    -- Axi shake
                    if(s_axi_ready) then
                        m_axi_valid <= '0';
                        if(adr_cnt = (CELLS_CNT - 1)) then
                            state <= Rom_Empty; -- Sending last value
                        else
                            adr_cnt <= adr_cnt + 1;
                            state   <= ValidSet; -- Sending non last value
                        end if;
                    end if;
                when Rom_Empty =>
                -- Deadlock
                when others =>
                    state <= ValidSet;
            end case;
        end if;
    end process;

end architecture;