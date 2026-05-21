library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Mux is
    generic
    (
        INPUTS_CNT   : natural := 4;
        INPUTS_WIDTH : natural := 32
    );
    Port (
        sel        : in  std_logic_vector(Log2Ceil(INPUTS_CNT) - 1 downto 0)        := (others => '0');
        inputs_bus : in  std_logic_vector((INPUTS_WIDTH * INPUTS_CNT - 1) downto 0) := (others => '0');
        out_data   : out std_logic_vector((INPUTS_WIDTH - 1) downto 0)              := (others => '0')
    );
end Mux;

architecture rtl of Mux is
    signal data_inputs : slv_arr(0 to INPUTS_CNT - 1)(INPUTS_WIDTH - 1 downto 0) := (others => (others => '0'));
begin
    IN_SEL : for i in 0 to (INPUTS_CNT - 1) generate
        data_inputs(i) <= inputs_bus(((INPUTS_WIDTH * (i + 1)) - 1) downto INPUTS_WIDTH * i);
    end generate;
    out_data <= data_inputs(to_integer(unsigned(sel)));
end architecture;