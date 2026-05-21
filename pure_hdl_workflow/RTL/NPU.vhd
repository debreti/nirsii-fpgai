library ieee;
use ieee.std_logic_1164.all;
library work;
use work.NPU_Package.all;

entity NPU is
    generic (
        INST_INX : natural := 0
    );
    port(
        clk          : in  std_logic                                                                                          := '0';
        rst          : in  std_logic                                                                                          := '0';
        m_axi_valid  : in  std_logic                                                                                          := '0'; -- Master
        ns_axi_ready : in  std_logic                                                                                          := '0'; -- Next slave
        m_axi_data   : in  std_logic_vector((NN_CONFIG(INST_INX).Neuron_Width - 1) downto 0)                                  := (others => '0');
        s_axi_ready  : out std_logic                                                                                          := '0'; -- Slave
        s_axi_valid  : out std_logic                                                                                          := '0'; -- Slave-master
        s_axi_data   : out std_logic_vector((NN_CONFIG(INST_INX).Acc_Width + NN_CONFIG(INST_INX).M_SCALE_WIDTH - 1) downto 0) := (others => '0')
    );
end entity;

architecture rtl of NPU is
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    CONSTANTS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    constant NEURON_WIDTH     : natural := NN_CONFIG(INST_INX).Neuron_Width;
    constant ACC_WIDTH        : natural := NN_CONFIG(INST_INX).Acc_Width;
    constant M_SCALE_WIDTH    : natural := NN_CONFIG(INST_INX).M_Scale_Width;
    constant LAYERS_COUNT     : natural := NN_CONFIG(INST_INX).Layers_Cnt;
    constant INPUT_LAYER_SIZE : natural := LAYERS_MAP(InputLayerIndex(INST_INX));
    constant OUT_LAYER_SIZE   : natural := LAYERS_MAP(OutputLayerIndex(INST_INX));
    /* ┏━━━━━━━━━━━━━┓ */
    -- ┃    WIRES    ┃ --   Format: (Sender)_(Recevier)_(Signal name)
    /* ┗━━━━━━━━━━━━━┛ */
    -- Axi Input Loader
    signal axiInLoader_rb_inputLayerWrite : std_logic := '0';
    signal axiUpload_lastValue : std_logic := '0';
    signal axiUploader_rb_FirstLayerData : std_logic_vector(NEURON_WIDTH - 1 downto 0) := (others => '0');
    -- Mac Cluster
    signal macNet_fsm_pipe_empty    : std_logic                                  := '0';
    signal macNet_fsm_last_mac_flag : std_logic                                  := '0';
    signal macNet_act_mac_data      : std_logic_vector((ACC_WIDTH - 1) downto 0) := (others => '0');
    -- Activation and Quantization module
    signal act_rb_neuron_data_valid              : std_logic                                                  := '0';
    signal act_axi_predict_data_valid            : std_logic                                                  := '0';
    signal act_fsm_quant_out_last                : std_logic                                                  := '0';
    signal act_fsm_last_layer_flag               : std_logic                                                  := '0';
    signal act_fsm_transition_to_next_layer_flag : std_logic                                                  := '0';
    signal act_fsm_last_mac_pair                 : std_logic                                                  := '0';
    signal act_rb_neuron_data                    : std_logic_vector((NEURON_WIDTH - 1) downto 0)              := (others => '0');
    signal act_axi_predict_data                  : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0');
    -- Layers Buffer
    signal rb_fsm_layer_end_flag : std_logic                                     := '0';
    signal rb_macNet_neuron_data : std_logic_vector((NEURON_WIDTH - 1) downto 0) := (others => '0');
    -- Control unit
    signal fsm_axiInload_arm           : std_logic := '0';
    signal fsm_macNet_next_bias_unload : std_logic := '0';
    signal fsm_macNet_mac_inputs_valid : std_logic := '0';
    signal macNet_act_mac_data_valid   : std_logic := '0';
    signal fsm_macNet_next_mac_unload  : std_logic := '0';
    signal fsm_next_mac_args           : std_logic := '0';
    signal fsm_rb_set_layer_borders    : std_logic := '0';
    signal fsm_rb_jump_to_layer_start  : std_logic := '0';
    -- AXI Unloader
    signal axiStack_out_valid : std_logic                                                  := '0';
    signal axiStack_out_data  : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0');
begin

    Axi_Uploader : entity work.Axi_Uploader
        generic map (
            PACKET_SIZE => INPUT_LAYER_SIZE,
            DATA_WIDTH  => NEURON_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            arm    => fsm_axiInload_arm,
            m_valid  => m_axi_valid,
            s_ready  => s_axi_ready,
            in_data  => m_axi_data,
            out_last => axiUpload_lastValue,
            out_val  => axiInLoader_rb_inputLayerWrite,
            out_data => axiUploader_rb_FirstLayerData
        );

    Control_Unit : entity work.Control_Unit
        generic map (
            INST_INX => INST_INX
        )
        port map (
            clk                  => clk,
            rst                  => rst,
            start_axi_upload     => fsm_axiInload_arm,
            last_mac_pair        => act_fsm_last_mac_pair,
            layer_end            => act_fsm_transition_to_next_layer_flag,
            last_layer           => act_fsm_last_layer_flag,
            next_bias            => fsm_macNet_next_bias_unload,
            mac_in_val           => fsm_macNet_mac_inputs_valid,
            last_bus_mac         => macNet_fsm_last_mac_flag,
            mac_pipe_complete    => macNet_fsm_pipe_empty,
            next_mac             => fsm_macNet_next_mac_unload,
            act_quant_last       => act_fsm_quant_out_last,
            axi_last_input       => axiUpload_lastValue,
            rb_layer_end         => rb_fsm_layer_end_flag,
            nxt_mac_args         => fsm_next_mac_args,
            rb_set_layer_borders => fsm_rb_set_layer_borders,
            rb_jmp_layer_start   => fsm_rb_jump_to_layer_start
        );

    Mac_Cluster : entity work.Mac_Cluster
        generic map (
            INST_INX => INST_INX
        )
        port map (
            clk             => clk,
            rst             => rst,
            next_bias       => fsm_macNet_next_bias_unload,
            mac_in_val      => fsm_macNet_mac_inputs_valid,
            next_weight     => fsm_next_mac_args,
            next_mac        => fsm_macNet_next_mac_unload,
            neuron_data_in  => rb_macNet_neuron_data,
            pipe_complete   => macNet_fsm_pipe_empty,
            last_mac        => macNet_fsm_last_mac_flag,
            mac_out_val     => macNet_act_mac_data_valid,
            neuron_data_out => macNet_act_mac_data
        );

    Act_Quant_Unit : entity work.Act_Quant
        generic map (
            INST_INX => INST_INX
        )
        port map (
            clk              => clk,
            rst              => rst,
            in_mac_val       => macNet_act_mac_data_valid,
            in_mac_data      => macNet_act_mac_data,
            quant_out_last   => act_fsm_quant_out_last,
            layer_end        => act_fsm_transition_to_next_layer_flag,
            last_mac_pair    => act_fsm_last_mac_pair,
            last_layer       => act_fsm_last_layer_flag,
            quant_out_val    => act_rb_neuron_data_valid,
            predict_out_val  => act_axi_predict_data_valid,
            out_quant_data   => act_rb_neuron_data,
            out_predict_data => act_axi_predict_data
        );

    Layers_Buffer : entity work.Layers_Buffer
        generic map (
            INST_INX => INST_INX
        )
        port map (
            clk               => clk,
            rst               => rst,
            ext_we            => axiInLoader_rb_inputLayerWrite,
            we                => act_rb_neuron_data_valid,
            re                => fsm_next_mac_args,
            set_layer_borders => fsm_rb_set_layer_borders,
            jmp_layer_start   => fsm_rb_jump_to_layer_start,
            neuron_data       => act_rb_neuron_data,
            flayer_data       => axiUploader_rb_FirstLayerData,
            out_data          => rb_macNet_neuron_data,
            layer_end         => rb_fsm_layer_end_flag
        );

    Axi_Unloader : entity work.Axi_OutBuffer
        generic map (
            CELLS_CNT => OUT_LAYER_SIZE,
            OUT_WIDTH => ACC_WIDTH + M_SCALE_WIDTH
        )
        port map (
            clk       => clk,
            rst       => rst,
            re        => ns_axi_ready,
            we        => act_axi_predict_data_valid,
            in_data   => act_axi_predict_data,
            out_valid => axiStack_out_valid,
            out_data  => axiStack_out_data
        );
    s_axi_valid <= axiStack_out_valid;
    s_axi_data  <= axiStack_out_data;

end architecture;





