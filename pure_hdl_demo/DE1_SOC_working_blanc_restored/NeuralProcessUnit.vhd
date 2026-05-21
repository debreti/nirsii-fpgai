library ieee;
use ieee.std_logic_1164.all;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.fixed_float_types.all;
library NPU;
use NPU.NN_package.all;

--  ---------
-- | ENTITY |
--  --------
entity NeuralProcessUnit is
	generic (
		INST_INX    : natural := 0
	);
	port(
		clk : in std_logic;
		rst : in std_logic;
		-- Master to slave
		m_axi_valid : in  std_logic;
		m_axi_data  : in  std_logic_vector(7 downto 0);
		s_axi_ready : out std_logic;
		-- Slave becomes master (slave-master)
		ns_axi_ready : in  std_logic; -- next slave
		s_axi_valid  : out std_logic;
		s_axi_data   : out std_logic_vector(63 downto 0)
	);
end entity;

--  ---------------
-- | ARCHITECTURE |
--  --------------
architecture rtl of NeuralProcessUnit is
	--  ------------
	-- | CONSTANTS |
	-- ------------
	constant NEURON_WIDTH  : natural                              := NN_CONFIG(INST_INX).Neuron_Width;
	constant ACC_WIDTH     : natural                              := NN_CONFIG(INST_INX).Acc_Width;
	constant M_SCALE_WIDTH : natural                              := NN_CONFIG(INST_INX).M_Scale_Width;
	constant LAYERS_COUNT  : natural                              := NN_CONFIG(INST_INX).Layers_Cnt;
	constant LAYERS_MAP    : natural_arr(0 to (LAYERS_COUNT - 1)) := LAYERS_MAP(INST_INX);
	--  --------------
	-- | GLUE SIGNLAS |
	--  --------------
	-- Format: (Sender)_(Recevier)_(Signal name)

	-- Mac network
	-- -----------
	signal macNet_fsm_pipe_empty    : std_logic                                  := '0';
	signal macNet_fsm_last_mac_flag : std_logic                                  := '0';
	signal macNet_act_mac_data      : std_logic_vector((ACC_WIDTH - 1) downto 0) := (others => '0');
	-- Activation function
	-- -------------------
	signal act_rb_neuron_data_valid              : std_logic                                                  := '0';
	signal act_axi_predict_data_valid            : std_logic                                                  := '0';
	signal act_fsm_quant_out_last                : std_logic                                                  := '0';
	signal act_fsm_last_layer_flag               : std_logic                                                  := '0';
	signal act_fsm_transition_to_next_layer_flag : std_logic                                                  := '0';
	signal act_fsm_last_mac_pair                 : std_logic                                                  := '0';
	signal act_rb_neuron_data                    : std_logic_vector((NEURON_WIDTH - 1) downto 0)              := (others => '0');
	signal act_axi_predict_data                  : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0');
	-- Ring buffer	
	-- -----------
	signal rb_fsm_layer_end_flag : std_logic                                     := '0';
	signal rb_macNet_neuron_data : std_logic_vector((NEURON_WIDTH - 1) downto 0) := (others => '0');
	-- Control unit	
	-- --------------------------
	signal fsm_macNet_next_bias_unload : std_logic := '0';
	signal fsm_macNet_mac_inputs_valid : std_logic := '0';
	signal macNet_act_mac_data_valid   : std_logic := '0';
	signal fsm_macNet_next_mac_unload  : std_logic := '0';
	signal fsm_rb_flayer_we            : std_logic := '0';
	signal fsm_next_mac_args           : std_logic := '0';
	signal fsm_rb_set_layer_borders    : std_logic := '0';
	signal fsm_rb_jump_to_layer_start  : std_logic := '0';
	-- AXI Stack	
	-- -----------
	signal axiStack_out_valid               : std_logic                                                  := '0';
	signal axiStack_out_data                : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0');
	attribute noprune                       : boolean;
	attribute noprune of axiStack_out_valid : signal is true;
	attribute noprune of axiStack_out_data  : signal is true;
begin
	--  -------------
	-- | Comb-logic |
	-- -------------
	s_axi_data  <= axiStack_out_data;
	s_axi_valid <= axiStack_out_valid;
	--  ------
	-- | FSM |
	-- ------
	FSM_INST : entity NPU.FSM
		port map (
			clk                  => clk,
			rst                  => rst,
			axi_m_valid          => m_axi_valid,
			axi_s_ready          => s_axi_ready,
			last_mac_pair        => act_fsm_last_mac_pair,
			layer_end            => act_fsm_transition_to_next_layer_flag,
			last_layer           => act_fsm_last_layer_flag,
			next_bias            => fsm_macNet_next_bias_unload,
			mac_in_val           => fsm_macNet_mac_inputs_valid,
			last_bus_mac         => macNet_fsm_last_mac_flag,
			mac_pipe_complete    => macNet_fsm_pipe_empty,
			next_mac             => fsm_macNet_next_mac_unload,
			act_quant_last       => act_fsm_quant_out_last,
			rb_layer_end         => rb_fsm_layer_end_flag,
			rb_flayer_we         => fsm_rb_flayer_we,
			nxt_mac_args         => fsm_next_mac_args,
			rb_set_layer_borders => fsm_rb_set_layer_borders,
			rb_jmp_layer_start   => fsm_rb_jump_to_layer_start
		);
	--  --------------
	-- | Mac Network |
	-- --------------
	MAC_NET_INST : entity NPU.MAC_Network
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
	--  ----------------------
	-- | Activation function |
	-- ----------------------
	ACT_FUNC_INST : entity NPU.Act_ReLU
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
	--  --------------
	-- | Ring buffer |
	-- --------------
	RING_BUF_INST : entity NPU.Ring_Buffer
		port map (
			clk               => clk,
			rst               => rst,
			ext_we            => fsm_rb_flayer_we,
			we                => act_rb_neuron_data_valid,
			re                => fsm_next_mac_args,
			set_layer_borders => fsm_rb_set_layer_borders,
			jmp_layer_start   => fsm_rb_jump_to_layer_start,
			neuron_data       => act_rb_neuron_data,
			flayer_data       => m_axi_data,
			out_data          => rb_macNet_neuron_data,
			layer_end         => rb_fsm_layer_end_flag
		);
	--  ---------------
	-- | AXI Out Stack |
	-- ----------------
	AXI_STACK_INST : entity NPU.RAM(SyncStack)
		generic map (
			CELLS_CNT => LAYERS_MAP(LAYERS_COUNT - 1),
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
end rtl;





