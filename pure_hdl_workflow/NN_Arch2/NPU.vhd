library ieee;
use ieee.std_logic_1164.all;
library work;
use work.NN_package.all;

entity NPU is
	port(
		clk : in std_logic;
		rst : in std_logic;
		-- Master to slave
		m_axi_valid : in  std_logic;
		m_axi_data  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		s_axi_ready : out std_logic;
		-- Slave becomes master (slave-master)
		ns_axi_ready : in  std_logic; -- Next slave
		s_axi_valid  : out std_logic;
		s_axi_data   : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end entity;

architecture rtl of NPU is
	-- Rom
	signal rom_flayer_start : std_logic := '0';
	signal rom_layer_start  : std_logic := '0';
	signal rom_next_val     : std_logic := '0';
	signal rom_bus          : std_logic_vector((MAC_COUNT * DATA_WIDTH) - 1 downto 0);
	-- Mac network
	signal macn_last_mac  : std_logic := '0';
	signal macn_blank_mac : std_logic := '0';
	signal macn_write_en  : std_logic := '0';
	signal macn_w_load    : std_logic := '0';
	signal macn_next_mac  : std_logic := '0';
	-- Activation function
	signal act_func_in  : std_logic_vector((2 * DATA_WIDTH) - 1 downto 0);
	signal act_func_out : std_logic_vector(DATA_WIDTH - 1 downto 0);
	-- Ring buffer	
	signal rbuf_flayer_end : std_logic := '0';
	signal rbuf_layer_end  : std_logic := '0';
	signal rbuf_write_en   : std_logic := '0';
	signal rbuf_read_en    : std_logic := '0';
	signal rbuf_sel_in_val : std_logic := '0';
	signal rbuf_sw_prt     : std_logic := '0';
	signal rbuf_sr_prt     : std_logic := '0';
	signal rbuf_jmp_st     : std_logic := '0';
	signal rbuf_out        : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
	-- NPU
	s_axi_data <= rbuf_out;
	-- FSM 
	FSM_INST : entity work.FSM
		port map (
			clk             => clk,
			rst             => rst,
			axi_m_valid     => m_axi_valid,
			axi_s_ready     => s_axi_ready,
			axi_ns_ready    => ns_axi_ready,
			axi_s_valid     => s_axi_valid,
			rom_ended       => rom_flayer_start,
			rom_layer_start => rom_layer_start,
			rom_next        => rom_next_val,
			mac_blank       => macn_blank_mac,
			mac_last        => macn_last_mac,
			mac_we          => macn_write_en,
			mac_w_load      => macn_w_load,
			mac_next        => macn_next_mac,
			rb_in_layer_end => rbuf_flayer_end,
			rb_layer_end    => rbuf_layer_end,
			rb_write        => rbuf_write_en,
			rb_read         => rbuf_read_en,
			rb_select       => rbuf_sel_in_val,
			rb_sw_prt       => rbuf_sw_prt,
			rb_sr_prt       => rbuf_sr_prt,
			rb_jmp_st       => rbuf_jmp_st
		);
	-- ROM 
	ROM_INST : entity work.ROM
		port map (
			clk          => clk,
			rst          => rst,
			RE           => rom_next_val,
			flayer_start => rom_flayer_start,
			layer_start  => rom_layer_start,
			rom_out      => rom_bus
		);
	-- Mac's and their bus
	MAC_NET_INST : entity work.MAC_Network
		port map (
			clk        => clk,
			rst        => rst,
			WE         => macn_write_en,
			weight_ld  => macn_w_load,
			next_mac   => macn_next_mac,
			neuron_val => rbuf_out,
			rom_val    => rom_bus,
			output     => act_func_in,
			blank_flg  => macn_blank_mac,
			last_mac   => macn_last_mac
		);
	-- Activation function
	ACT_FUNC_INST : entity work.Act_ReLU
		port map (
			input  => act_func_in,
			output => act_func_out
		);
	-- Ring buffer	
	RING_BUF_INST : entity work.Ring_Buffer
		port map (
			clk        => clk,
			rst        => rst,
			WE         => rbuf_write_en,
			RE         => rbuf_read_en,
			sel_data   => rbuf_sel_in_val,
			sav_w_prt  => rbuf_sw_prt,
			sav_r_prt  => rbuf_sr_prt,
			jmp_lstart => rbuf_jmp_st,
			func_data  => act_func_out,
			extr_data  => m_axi_data,
			out_val    => rbuf_out,
			layer_end  => rbuf_layer_end,
			flayer_end => rbuf_flayer_end
		);
end rtl;

