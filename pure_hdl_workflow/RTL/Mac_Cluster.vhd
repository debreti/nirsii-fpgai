library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Mac_Cluster is
    generic (
        INST_INX : natural := 0
    );
    port (
        clk             : in     std_logic                                                       := '0';
        rst             : in     std_logic                                                       := '0';
        next_bias       : in     std_logic                                                       := '0';
        mac_in_val      : in     std_logic                                                       := '0';
        next_weight     : in     std_logic                                                       := '0';
        next_mac        : in     std_logic                                                       := '0';
        neuron_data_in  : in     std_logic_vector(NN_CONFIG(INST_INX).Neuron_Width - 1 downto 0) := (others => '0');
        pipe_complete   : out    std_logic                                                       := '0';
        last_mac        : buffer std_logic                                                       := '0';
        mac_out_val     : out    std_logic                                                       := '0';
        neuron_data_out : out    std_logic_vector((NN_CONFIG(INST_INX).Acc_Width - 1) downto 0)  := (others => '0')
    );
end Mac_Cluster;

architecture rtl of Mac_Cluster is
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    CONSTANTS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    -- Pipeline stages
    -- 0) Registered Mac inputs from ROM / Ring Buffer
    -- 1) Registered multiplication result
    -- 2) Accumulated multiplication result
    constant STAGES_CNT       : natural                    := 3;
    constant LAYERS_COUNT     : natural                    := NN_CONFIG(INST_INX).Layers_Cnt;
    constant MAC_COUNT        : natural                    := NN_CONFIG(INST_INX).Mac_Cnt;
    constant WEIGHT_WIDTH     : natural                    := NN_CONFIG(INST_INX).Weight_Width;
    constant NEURON_WIDTH     : natural                    := NN_CONFIG(INST_INX).Neuron_Width;
    constant BIAS_WIDTH       : natural                    := NN_CONFIG(INST_INX).Bias_Width;
    constant ACC_WIDTH        : natural                    := NN_CONFIG(INST_INX).Acc_Width;
    constant W_ROM_SIZE       : natural                    := WeightRomSize(INST_INX);
    constant B_ROM_SIZE       : natural                    := BiasRomSize(INST_INX);
    constant MAC_SELECT_WIDTH : natural                    := Log2Ceil(MAC_COUNT);
    constant MAC_TYPES_MAP    : sl_arr(0 to MAC_COUNT - 1) := MacTypesMapInit(INST_INX);
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    signal sel_mac_rst          : std_logic                                              := '0';
    signal sel_mac_max          : std_logic                                              := '0';
    signal sel_mac_blank        : std_logic                                              := '0';
    signal stage_shr            : std_logic_vector(STAGES_CNT - 1 downto 0)              := (others => '0');
    signal layers_st            : std_logic_vector(LAYERS_COUNT - 3 downto 0)            := (others => '0');
    signal blank_flags          : std_logic_vector(0 to MAC_COUNT - 1)                   := (others => '0');
    signal blank_selected_flags : std_logic_vector(0 to MAC_COUNT - 1)                   := (others => '0');
    signal mac_outputs          : std_logic_vector((ACC_WIDTH * MAC_COUNT - 1) downto 0) := (others => '0');
    signal mac_bus_out          : std_logic_vector(ACC_WIDTH - 1 downto 0)               := (others => '0');
    signal bias_cnt_vector      : std_logic_vector(Log2Ceil(B_ROM_SIZE) - 1 downto 0)    := (others => '0');
    signal weight_cnt_vector    : std_logic_vector(Log2Ceil(W_ROM_SIZE) - 1 downto 0)    := (others => '0');
    signal sel_mac_vector       : std_logic_vector(Log2Ceil(MAC_COUNT) - 1 downto 0)     := (others => '0');
    signal sel_mac              : natural range 0 to (MAC_COUNT - 1)                     := 0;
    signal bias_cnt             : natural range 0 to (B_ROM_SIZE - 1)                    := 0;
    signal weight_cnt           : natural range 0 to (W_ROM_SIZE - 1)                    := 0;
    signal mac_b_inputs         : slv_arr(0 to MAC_COUNT - 1)(BIAS_WIDTH - 1 downto 0)   := (others => (others => '0'));
    signal mac_w_inputs         : slv_arr(0 to MAC_COUNT - 1)(WEIGHT_WIDTH - 1 downto 0) := (others => (others => '0'));
begin

    Mac_Mux : entity work.Mux
        generic map (
            INPUTS_CNT   => MAC_COUNT,
            INPUTS_WIDTH => ACC_WIDTH
        )
        port map (
            sel        => std_logic_vector(to_unsigned(sel_mac, MAC_SELECT_WIDTH)),
            inputs_bus => mac_outputs,
            out_data   => mac_bus_out
        );

    Bias_Rom_Counter : entity work.Counter_Q
        generic map (
            CNT_MAX => B_ROM_SIZE
        )
        port map (
            clk      => clk,
            rst      => rst,
            en       => next_bias,
            out_data => bias_cnt_vector
        );
    bias_cnt <= to_integer(unsigned(bias_cnt_vector));

    Weigth_Rom_Counter : entity work.Counter_Q
        generic map (
            CNT_MAX => W_ROM_SIZE
        )
        port map (
            clk      => clk,
            rst      => rst,
            en       => next_weight,
            out_data => weight_cnt_vector
        );
    weight_cnt <= to_integer(unsigned(weight_cnt_vector));

    Mac_Mux_Select_Counter : entity work.Counter_FlgQSclr
        generic map (
            CNT_MAX => MAC_COUNT
        )
        port map (
            clk      => clk,
            aclr     => rst,
            sclr     => sel_mac_rst,
            en       => next_mac,
            max      => sel_mac_max,
            out_data => sel_mac_vector
        );
    sel_mac <= to_integer(unsigned(sel_mac_vector));

    Mac_Node : for i in 0 to (MAC_COUNT - 1) generate
    begin
        Bias_Rom : entity work.Rom_SpAdr
            generic map (
                FILE_NAME => RomFileName(INST_INX, 'B', i),
                CELLS_CNT => B_ROM_SIZE,
                OUT_WIDTH => BIAS_WIDTH
            )
            port map (
                clk      => clk,
                adr      => std_logic_vector(to_unsigned(bias_cnt, Log2Ceil(B_ROM_SIZE))),
                out_data => mac_b_inputs(i)
            );
        Weight_Rom : entity work.Rom_SpAdr
            generic map (
                FILE_NAME => RomFileName(INST_INX, 'W', i),
                CELLS_CNT => W_ROM_SIZE,
                OUT_WIDTH => WEIGHT_WIDTH
            )
            port map (
                clk      => clk,
                adr      => std_logic_vector(to_unsigned(weight_cnt, Log2Ceil(W_ROM_SIZE))),
                out_data => mac_w_inputs(i)
            );
        Mac_Block : if MAC_TYPES_MAP(i) = '0' generate
        begin
            Simple : entity work.Mac
                generic map (
                    WEIGHT_WIDTH => WEIGHT_WIDTH,
                    NEURON_WIDTH => NEURON_WIDTH,
                    ACC_WIDTH    => ACC_WIDTH,
                    BIAS_WIDTH   => BIAS_WIDTH
                )
                port map (
                    clk         => clk,
                    mul_en      => stage_shr(0),
                    acc_en      => stage_shr(1),
                    acc_sload   => next_bias,
                    neuron_data => neuron_data_in,
                    bias_data   => mac_b_inputs(i),
                    weight_data => mac_w_inputs(i),
                    out_data    => mac_outputs((ACC_WIDTH * (i + 1)) - 1 downto ACC_WIDTH * i)
                );
        else generate
            Blanker : entity work.Mac_Blk
                generic map (
                    WEIGHT_WIDTH => WEIGHT_WIDTH,
                    NEURON_WIDTH => NEURON_WIDTH,
                    ACC_WIDTH    => ACC_WIDTH,
                    BIAS_WIDTH   => BIAS_WIDTH
                )
                port map (
                    clk         => clk,
                    mul_en      => stage_shr(0),
                    acc_en      => stage_shr(1),
                    acc_sload   => next_bias,
                    neuron_data => neuron_data_in,
                    bias_data   => mac_b_inputs(i),
                    weight_data => mac_w_inputs(i),
                    out_data    => mac_outputs((ACC_WIDTH * (i + 1)) - 1 downto ACC_WIDTH * i),
                    nonBlank    => blank_flags(i)
                );
        end generate Mac_Block;
        Blank_Detector : if MAC_TYPES_MAP(i) = '1' generate
            blank_selected_flags(i) <= '1' when (sel_mac = (i - 1) and blank_flags(i) = '0') else '0';
        end generate Blank_Detector;
    end generate MAC_NODE;

    sel_mac_blank <= OR_REDUCE(blank_selected_flags); -- Is next mac is gonna be pre-blank?
    Seq_Logic : process(clk)
    begin
        if(rising_edge(clk)) then
            -- Sel mac counter reset due to blank detection
            sel_mac_rst <= sel_mac_blank;
            -- Out mac data register
            neuron_data_out <= mac_bus_out;
            -- Last valid mac flag register
            last_mac <= sel_mac_blank or sel_mac_max;
            -- Pipe completed flag register
            pipe_complete <= stage_shr(2) and (not stage_shr(1));
        end if;
    end process;

    Seq_Logic_Arst : process(clk, rst)
    begin
        if(rst) then
            mac_out_val <= '0';
            stage_shr   <= (others => '0');
        elsif (rising_edge(clk)) then
            -- Mac_out valid flag
            mac_out_val <= next_mac and (not last_mac);
            -- Advance stage shr
            stage_shr <= stage_shr(stage_shr'high - 1 downto stage_shr'low) & mac_in_val;
        end if;
    end process;

end architecture;