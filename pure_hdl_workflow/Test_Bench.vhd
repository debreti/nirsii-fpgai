library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use std.textio.all;
use std.env.all; -- Important also set VHDL-2008
library work;
use work.NPU_Package.all;

entity Test_Bench is
end entity Test_Bench;

architecture tb of Test_Bench is
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    CONSTANTS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    -- Constants
    constant INST_INX      : natural := 0;
    constant pix_width     : natural := 8;
    constant ACC_WIDTH     : natural := NN_CONFIG(INST_INX).Acc_Width;
    constant M_SCALE_WIDTH : natural := NN_CONFIG(INST_INX).M_Scale_Width;
    constant INPUT_FILE    : string  := "FirstLayer2.txt";
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    ---------------------------------
    -- Common signals for modules
    ---------------------------------
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    ---------------------------------
    -- Signals for DUT NPU
    ---------------------------------
    signal npu_ns_axi_ready : std_logic                                                  := '0';
    signal npu_sm_axi_valid : std_logic                                                  := '0';
    signal npu_axi_valid    : std_logic                                                  := '0';
    signal npu_axi_ready    : std_logic                                                  := '0';
    signal npu_in_valid     : std_logic                                                  := '0';
    signal npu_in_pix       : std_logic_vector(pix_width - 1 downto 0)                   := (others => '0');
    signal out_predict      : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0');
    signal fixed_predict    : sfixed(ACC_WIDTH - 1 downto -M_SCALE_WIDTH)                := (others => '0');
begin

    -- Test ROM for feeding NPU input data
    Test_Rom : entity work.Test_ROM(Axi_Feeder)
        generic map (
            FILE_NAME => MIF_FOLDER_PATH & INPUT_FILE,
            CELLS_CNT => 784,
            OUT_WIDTH => pix_width
        )
        port map (
            clk         => clk,
            rst         => rst,
            s_axi_ready => npu_axi_ready,
            m_axi_valid => npu_in_valid,
            out_data    => npu_in_pix
        );

    -- DUT 
    dut_NPU : entity work.NPU
        port map (
            clk => clk,
            rst => rst,
            -- Master to slave
            m_axi_valid => npu_in_valid, --  scaler_axi_valid
            m_axi_data  => npu_in_pix,   -- npu_in_pix,    out_pix
            s_axi_ready => npu_axi_ready,
            -- Slave becomes master (slave-master)
            ns_axi_ready => npu_ns_axi_ready,
            s_axi_valid  => npu_sm_axi_valid,
            s_axi_data   => out_predict
        );

    -- Clock and reset
    clk <= not clk after 1 ns;
    rst <= '0' after 4 ns;
    -- Fixed result conversion
    fixed_predict <= to_sfixed(out_predict, fixed_predict'high, fixed_predict'low);
    ---------------------
    -- Main test process
    ---------------------
    test_proc : process
    begin
        -- Wait for reset release
        wait until rst = '0';
        -- Waiting for predicts output
        for x in 0 to (LAYERS_MAP(OutputLayerIndex(INST_INX)) - 1) loop
            wait until rising_edge(npu_sm_axi_valid);
        end loop;
        wait for 10 ns;
        -- End simulation
        assert false report "Simulation completed successfully" severity note;
        stop;
    end process test_proc;
end architecture;

