library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.NN_package.all;

entity MAC_Network is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        WE          : in  std_logic;
        weight_load : in  std_logic;
        next_mac    : in  std_logic;
        neuron_val  : in  std_logic_vector(WEIGHT_WIDTH - 1 downto 0);
        rom_b_bus   : in  std_logic_vector(MAC_COUNT * BIAS_WIDTH - 1 downto 0);
        rom_w_bus   : in  std_logic_vector(MAC_COUNT * WEIGHT_WIDTH - 1 downto 0);
        output      : out std_logic_vector(2 * WEIGHT_WIDTH - 1 downto 0);
        blank_flg   : out std_logic;
        last_mac    : out std_logic
    );
end MAC_Network;

architecture structural of MAC_Network is
    signal sel_ended    : std_logic := '0';
    signal sel_mac      : natural range 0 to (MAC_COUNT - 1);
    signal blank_flags  : sl_arr(0 to MAC_COUNT - 1);
    signal mac_outputs  : slve_arr(0 to MAC_COUNT - 1)(ACC_WIDTH - 1 downto 0);
    signal mac_b_inputs : slve_arr(0 to MAC_COUNT - 1)(BIAS_WIDTH - 1 downto 0);
    signal mac_w_inputs : slve_arr(0 to MAC_COUNT - 1)(WEIGHT_WIDTH - 1 downto 0);
begin

    blank_flg <= blank_flags(sel_mac);
    last_mac  <= to_std_logic(sel_mac = (MAC_COUNT - 1)); -- Last mac is on bus
    output    <= mac_outputs(sel_mac)((ACC_WIDTH - 1) downto (ACC_WIDTH - 2 * WEIGHT_WIDTH));

    -- Mac selector logic
    process(clk,rst)
    begin
        if(rst = '1') then
            sel_mac <= 0;
        elsif (rising_edge(clk)) then
            -- Current mac is blank or last
            if(next_mac = '1') then
                if(last_mac OR blank_flg) then
                    sel_mac <= 0;
                else
                    sel_mac <= sel_mac + 1;
                end if;
            end if;
        end if;
    end process;

    -- Split rom_net weight bus into sub-busses
    process(rom_w_bus)
    begin
        for i in 0 to MAC_COUNT - 1 loop
            mac_w_inputs(i) <= rom_w_bus(((i + 1) * WEIGHT_WIDTH) - 1 downto i * WEIGHT_WIDTH);
        end loop;
    end process;

    -- Split rom_net bias bus into sub-busses
    process(rom_b_bus)
    begin
        for i in 0 to MAC_COUNT - 1 loop
            mac_b_inputs(i) <= rom_b_bus(((i + 1) * BIAS_WIDTH) - 1 downto i * BIAS_WIDTH);
        end loop;
    end process;

    -- Instantiate first MAC block 
    FIRST_MAC : entity work.MAC_block(FirstMac)
        port map (
            clk         => clk,
            rst         => rst,
            WE          => WE,
            weight_load => weight_load,
            isBlank     => blank_flags(0),
            neuron_val  => neuron_val,
            bias_val    => mac_b_inputs(0),
            weight_val  => mac_w_inputs(0),
            acc_out     => mac_outputs(0)
        );

    -- Instantiate other MAC blocks
    GEN_SMACS : for i in 1 to (MAC_COUNT - 1) generate
    begin
        SUB_MAC : entity work.MAC_block
            port map (
                clk         => clk,
                rst         => rst,
                WE          => WE,
                weight_load => weight_load,
                isBlank     => blank_flags(i),
                neuron_val  => neuron_val,
                bias_val    => mac_b_inputs(i),
                weight_val  => mac_w_inputs(i),
                acc_out     => mac_outputs(i)
            );
    end generate;

end structural;