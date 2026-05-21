library ieee;
use ieee.std_logic_1164.all;
library work;
use work.NPU_Package.all;

entity Control_Unit is
    generic (
        INST_INX : natural := 0
    );
    port(
        clk : in std_logic := '0';
        rst : in std_logic := '0';
        -- Axi Uploader flags in
        axi_last_input : in std_logic := '0';
        -- Mac network flags in
        last_bus_mac      : in std_logic := '0';
        mac_pipe_complete : in std_logic := '0';
        -- Act function flags in
        act_quant_last : in std_logic := '0';
        last_mac_pair  : in std_logic := '0';
        layer_end      : in std_logic := '0';
        last_layer     : in std_logic := '0';
        -- Ring buffer flags in
        rb_layer_end : in std_logic := '0';
        -- Axi Uploader flags out
        start_axi_upload : out std_logic := '0';
        -- Mac network flags out
        next_bias  : out std_logic := '0';
        mac_in_val : out std_logic := '0';
        next_mac   : out std_logic := '0';
        -- Ring buffer flags out
        nxt_mac_args         : out std_logic := '0';
        rb_set_layer_borders : out std_logic := '0';
        rb_jmp_layer_start   : out std_logic := '0'
    );
end entity;

architecture rtl of Control_Unit is
    /* ┏━━━━━━━━━━━┓ */
    -- ┃    FSM    ┃ --
    /* ┗━━━━━━━━━━━┛ */
    type state_type is (
            StartAxiUpload,
            AxiUploadWait,
            BiasLoad,
            MacCompute,
            MacComputeWait,
            ActComputeStart,
            ActQuantWait);
    attribute enum_encoding               : string;
    attribute enum_encoding of state_type : type is "one-hot";
    signal state, next_state              : state_type := StartAxiUpload;
begin

    Seq_Logic_Arts_Fsm_Transition : process(clk, rst)
    begin
        if(rst) then
            state <= StartAxiUpload;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    Comb_Logic_Fsm_Behaviour : process(all)
    begin
        -- Default values
        start_axi_upload     <= '0';
        next_bias            <= '0';
        mac_in_val           <= '0';
        next_mac             <= '0';
        nxt_mac_args         <= '0';
        rb_set_layer_borders <= '0';
        rb_jmp_layer_start   <= '0';
        next_state           <= state;
        -- States logic
        case state is
            when StartAxiUpload =>
                start_axi_upload <= '1'; -- Arm AXI Uploader module
                next_state       <= AxiUploadWait;
            when AxiUploadWait =>
                /* Waiting for last axi value save */
                if (axi_last_input) then
                    rb_set_layer_borders <= '1'; -- Set first layer borders in Ring Buffer
                    next_state           <= BiasLoad;
                end if;
            when BiasLoad =>
                next_bias    <= '1';
                nxt_mac_args <= '1'; --  Pre-advance next weigh and neuron value
                next_state   <= MacCompute;
            when MacCompute =>
                mac_in_val   <= '1';              -- Load data in mac pipe
                nxt_mac_args <= not rb_layer_end; -- ON_RB(RE) and ON_WROM(RE)
                /* Computing last mac */
                if(rb_layer_end) then
                    next_state <= MacComputeWait;
                end if;
            when MacComputeWait =>
                /* Wait for all macs to compute */
                if(mac_pipe_complete) then
                    next_mac   <= '1'; --  Pre-select next mac out
                    next_state <= ActComputeStart;
                end if;
            when ActComputeStart =>
                next_mac           <= not last_bus_mac;                                    -- ON_MAC(Next mac to act_in)
                rb_jmp_layer_start <= last_bus_mac and last_layer and (not last_mac_pair); -- Jump to start of prv layer
                /* Sending last valid mac to act pipe */
                if(last_bus_mac) then
                    -- Is current layer last?
                    if(last_layer) then
                        -- Sended last mac_pair of last layer to act pipe?
                        if(last_mac_pair) then
                            next_state <= StartAxiUpload;
                        else
                            next_state <= BiasLoad;
                        end if;
                    else
                        next_state <= ActQuantWait;
                    end if;
                end if;
            when ActQuantWait =>
                -- Saving last quant act value
                if(act_quant_last) then
                    rb_jmp_layer_start   <= not layer_end; -- RB(jump to layer start)
                    rb_set_layer_borders <= layer_end;     -- RB(save read/write ptr)
                    next_state           <= BiasLoad;
                end if;
            when others =>
                next_state <= StartAxiUpload;
        end case;
    end process;

end architecture;