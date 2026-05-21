library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Fifo is
    generic
    (
        INST_INX  : natural := 0;
        FILE_INX  : natural := 0;
        CELLS_CNT : natural := 1;
        OUT_WIDTH : natural := 1
    );
    port
    (
        clk      : in  std_logic                                := '0';
        rst      : in  std_logic                                := '0';
        re       : in  std_logic                                := '0';
        we       : in  std_logic                                := '0';
        in_data  : in  std_logic_vector(OUT_WIDTH - 1 downto 0) := (others => '0');
        out_data : out std_logic_vector(OUT_WIDTH - 1 downto 0) := (others => '0')
    );
end entity;

architecture rtl of Fifo is
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    signal r_ptr : natural range 0 to (CELLS_CNT - 1)                      := 0;
    signal w_ptr : natural range 0 to (CELLS_CNT - 1)                      := 0;
    signal data  : slv_arr(0 to (CELLS_CNT - 1))((OUT_WIDTH - 1) downto 0) := (others => (others => '0'));
begin
    
    Seq_Logic_Arst : process(clk, rst)
    begin
        if(rst) then
            r_ptr <= 0;
            w_ptr <= 0;
        elsif(rising_edge(clk)) then
            -- Read pointer logic
            if(re) then
                if(r_ptr = (CELLS_CNT - 1)) then
                    r_ptr <= 0;
                else
                    r_ptr <= r_ptr + 1;
                end if;
            end if;
            -- Write pointer logic
            if(we) then
                if(w_ptr = (CELLS_CNT - 1)) then
                    w_ptr <= 0;
                else
                    w_ptr <= w_ptr + 1;
                end if;
            end if;
        end if;
    end process;

    Seq_Logic : process(clk)
    begin
        if rising_edge(clk) then
            -- Write op
            if(we) then
                data(w_ptr) <= in_data;
            end if;
            -- Output register read
            out_data <= data(r_ptr);
        end if;
    end process;

end architecture;