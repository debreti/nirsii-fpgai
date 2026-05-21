library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Axi_Uploader is
    generic (
        PACKET_SIZE : natural := 8;
        DATA_WIDTH  : natural := 8
    );
    port (
        clk      : in  std_logic                                   := '0';
        rst      : in  std_logic                                   := '0';
        arm      : in  std_logic                                   := '0';
        m_valid  : in  std_logic                                   := '0';
        in_data  : in  std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
        s_ready  : out std_logic                                   := '0';
        out_last : out std_logic                                   := '0';
        out_val  : out std_logic                                   := '0';
        out_data : out std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0')
    );
end entity;

architecture rtl of Axi_Uploader is
    /* ┏━━━━━━━━━━━┓ */
    -- ┃    FSM    ┃ --
    /* ┗━━━━━━━━━━━┛ */
    type t_state is (Idle, ReadySet, MasterWait);
    attribute enum_encoding            : string;
    attribute enum_encoding of t_state : type is "one-hot";
    signal state                       : t_state := Idle;
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    signal ready_set      : std_logic := '0';
    signal ready_reset    : std_logic := '0';
    signal packet_cnt_max : std_logic := '0';
begin

    Packet_Counter : entity work.Counter_Flg
        generic map (
            CNT_MAX => PACKET_SIZE
        )
        port map (
            clk => clk,
            rst => rst,
            en  => ready_reset,
            max => packet_cnt_max
        );

    Seq_Logic_Arst_Fsm : process(clk, rst)
    begin
        if(rst) THEN
            state <= Idle;
        elsif rising_edge(clk) then
            case state is
                when Idle =>
                    -- Starting new packet load
                    if(arm) then
                        state <= ReadySet;
                    end if;
                when ReadySet =>
                    state <= MasterWait;
                when MasterWait =>
                    -- Receving value
                    if(m_valid) then
                        if(not packet_cnt_max) then
                            state <= ReadySet; -- Receving non last value
                        else
                            state <= Idle; -- Receving last value
                        end if;
                    end if;
                when others =>
                    state <= Idle;
            end case;
        end if;
    end process;

    ready_set   <= '1' when state = ReadySet else '0';
    ready_reset <= '1' when (m_valid = '1' and state = MasterWait) else '0';
    Seq_Logic_Arst : process(clk,rst)
    begin
        if(rst) then
            s_ready  <= '0';
            out_val  <= '0';
            out_last <= '0';
        elsif(rising_edge(clk)) then
            -- Last out flag 
            out_last <= ready_reset and packet_cnt_max;
            -- Out valid set
            out_val <= ready_reset;
            -- Slave ready T_ff
            if(ready_set or ready_reset) then
                s_ready <= not s_ready;
            end if;
        end if;
    end process;

    Seq_Logic : process(clk)
    begin
        if rising_edge(clk) then
            out_data <= in_data;
        end if;
    end process;

end architecture;