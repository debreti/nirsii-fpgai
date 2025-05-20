library ieee;
use ieee.std_logic_1164.all;
library work;
use work.NN_package.all;

entity FSM is
	port(
		clk : in std_logic;
		rst : in std_logic ;
		-- Master to slave
		axi_m_valid : in  std_logic;
		axi_s_ready : out std_logic;
		-- Slave becomes master (slave-master)
		axi_ns_ready : in  std_logic; -- Next slave
		axi_s_valid  : out std_logic;
		-- Rom
		rom_ended       : in  std_logic;
		rom_layer_start : in  std_logic;
		rom_next        : out std_logic;
		-- Mac network
		mac_blank  : in  std_logic;
		mac_last   : in  std_logic;
		mac_we     : out std_logic;
		mac_w_load : out std_logic;
		mac_next   : out std_logic;
		-- Ring buffer	
		rb_in_layer_end : in  std_logic;
		rb_layer_end    : in  std_logic;
		rb_write        : out std_logic;
		rb_read         : out std_logic;
		rb_select       : out std_logic;
		rb_sw_prt       : out std_logic;
		rb_sr_prt       : out std_logic;
		rb_jmp_st       : out std_logic
	);
end entity;

architecture rtl of FSM is
	type state_type is (
			FirstLayerLoad,
			BiasLoad,
			MacCompute,
			ActComputeSave,
			ResultsUnload);
	signal state, next_state : state_type := FirstLayerLoad;
begin
	-- State register process
	FSM_STATE_TRANSITIONS : process(clk, rst)
	begin
		if (rst = '1') then
			state <= FirstLayerLoad;
		elsif rising_edge(clk) then
			state <= next_state;
		end if;
	end process;
	-- Next state and output logic
	FSM_STATE_LOGIC : process(
			state,
			axi_m_valid, axi_ns_ready,
			rom_ended, rom_layer_start,
			mac_blank,mac_last,
			rb_in_layer_end, rb_layer_end)
	begin
		-- Default assignments
		next_state   <= state;
		axi_s_ready  <= '0';
		axi_s_valid  <= '0';
		rom_next     <= '0';
		mac_we       <= '0';
		mac_w_load   <= '0'; -- OFF_Mac(acc = bias)
		mac_next     <= '0';
		rb_select    <= '0'; -- OFF_RB(input = extern data)
		rb_write     <= '0';
		rb_read      <= '0';
		rb_sw_prt    <= '0';
		rb_sr_prt    <= '0';
		rb_jmp_st    <= '0';
		-- States logic 
		case state is
			when FirstLayerLoad =>
				axi_s_ready <= '1';                       -- ON_FSM(slave axi_ready)
				rb_write    <= axi_m_valid;               -- ON_RB(WE)
				if (rb_in_layer_end AND axi_m_valid) then -- Saving last flayer val 
					rb_sr_prt  <= '1';                    -- ON_RB(save read ptr)
					rb_sw_prt  <= '1';                    -- ON_RB(save write ptr) 
					next_state <= BiasLoad;
				end if;
			when BiasLoad =>
				mac_we     <= '1'; -- ON_Mac(WE)
				rom_next   <= '1'; -- ON_ROM(RE)
				next_state <= MacCompute;
			when MacCompute =>
				rb_read    <= '1';          -- ON_RB(RE)
				rom_next   <= '1';          -- ON_ROM(RE)
				mac_we     <= '1';          -- ON_Mac(WE)
				mac_w_load <= '1';          -- ON_Mac(acc += weight * rb_val)
				if(rb_layer_end = '1') then -- Computing last mac by previous layer val
					next_state <= ActComputeSave;
				end if;
			when ActComputeSave =>
				rb_select <= '1';                     -- ON_RB(input = activate func data)
				mac_next  <= '1';                     -- ON_MAC(Next mac to act_in)
				rb_write  <= NOT mac_blank;           -- RB(WE)
				if(mac_last OR mac_blank) then        -- Saving last valid mac or blank mac exit   
					rb_sr_prt <= rom_layer_start;     -- RB(save read ptr)
					rb_sw_prt <= rom_layer_start;     -- RB(save write ptr) 
					rb_jmp_st <= NOT rom_layer_start; -- RB(jump to layer start)
					if(rom_ended = '1') then
						next_state <= ResultsUnload;
					else
						next_state <= BiasLoad;
					end if;
				end if;
			when ResultsUnload =>
				axi_s_valid <= '1';                    -- ON_FSM(slave axi_valid)
				rb_read     <= axi_ns_ready;           -- RB(RE)
				if(rb_layer_end AND axi_ns_ready) then -- Outputing last value
					next_state <= FirstLayerLoad;
				end if;
			when others =>
				next_state <= FirstLayerLoad;
		end case;
	end process;
end rtl;