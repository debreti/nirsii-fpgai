library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NPU_Package.all;

entity Act_Quant is
    generic (
        INST_INX : natural := 0
    );
    Port (
        clk              : in     std_logic                                                                                          := '0';
        rst              : in     std_logic                                                                                          := '0';
        in_mac_val       : in     std_logic                                                                                          := '0';
        in_mac_data      : in     std_logic_vector((NN_CONFIG(INST_INX).Acc_Width - 1) downto 0)                                     := (others => '0');
        last_layer       : buffer std_logic                                                                                          := '0';
        layer_end        : out    std_logic                                                                                          := '0';
        last_mac_pair    : out    std_logic                                                                                          := '0';
        quant_out_last   : out    std_logic                                                                                          := '0';
        quant_out_val    : out    std_logic                                                                                          := '0';
        predict_out_val  : out    std_logic                                                                                          := '0';
        out_quant_data   : out    std_logic_vector((NN_CONFIG(INST_INX).Neuron_Width - 1) downto 0)                                  := (others => '0');
        out_predict_data : out    std_logic_vector((NN_CONFIG(INST_INX).Acc_Width + NN_CONFIG(INST_INX).M_Scale_Width - 1) downto 0) := (others => '0')
    );
end entity;

architecture rtl of Act_Quant is
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    CONSTANTS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    -- Pipeline stages
    -- 0) Act / Neuron value save
    -- 1) Karatsuba Stage 0 - inputs save
    -- 2) Karatsuba Stage 1
    -- 3) Karatsuba Stage 2
    -- 4) Karatsuba Stage 3
    -- 5) Karatsuba result out
    -- 6) Twos Complement result / Predict out
    -- 7) Sum with Z_Scale
    -- 8) Clip and Quant valid data
    constant MUL_STAGES_CNT     : natural                              := 5;                  -- Karatsuba multiplier stages count
    constant PREDIC_STAGES_CNT  : natural                              := 2 + MUL_STAGES_CNT; -- Predict stages count
    constant QUANT_STAGES_CNT   : natural                              := 2;                  -- Quantization stages count
    constant LAYERS_COUNT       : natural                              := NN_CONFIG(INST_INX).Layers_Cnt;
    constant NEURON_WIDTH       : natural                              := NN_CONFIG(INST_INX).Neuron_Width;
    constant ACC_WIDTH          : natural                              := NN_CONFIG(INST_INX).Acc_Width;
    constant Z_SCALE_WIDTH      : natural                              := NN_CONFIG(INST_INX).Z_Scale_Width;
    constant Z_ROM_SIZE         : natural                              := LAYERS_COUNT - 2; -- Excluding first and final layers
    constant M_SCALE_WIDTH      : natural                              := NN_CONFIG(INST_INX).M_Scale_Width;
    constant M_ROM_SIZE         : natural                              := M_ScaleRomSize(INST_INX);
    constant LAST_MAC_PAIRS_MAP : natural_arr(0 to (LAYERS_COUNT - 2)) := EdgeMacPairsMap(INST_INX);
    constant MAC_PAIR_CNT       : natural                              := LAST_MAC_PAIRS_MAP(LAST_MAC_PAIRS_MAP'high);
    constant LAST_HID_MAC_PAIR  : natural                              := LAST_MAC_PAIRS_MAP(LAST_MAC_PAIRS_MAP'high - 1) - 1;
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    signal predict_out_val_nxt  : std_logic                                                  := '0';
    signal quant_out_val_nxt    : std_logic                                                  := '0';
    signal last_layer_nxt       : std_logic                                                  := '0';
    signal quant_out_last_nxt   : std_logic                                                  := '0';
    signal layer_end_nxt        : std_logic                                                  := '0';
    signal re_z_scale           : std_logic                                                  := '0';
    signal last_predict_out     : std_logic                                                  := '0';
    signal mac_pair_cnt_max     : std_logic                                                  := '0';
    signal layers_end_vct       : std_logic_vector((LAYERS_COUNT - 2) downto 0)              := (others => '0');
    signal clip_data            : std_logic_vector((NEURON_WIDTH - 1) downto 0)              := (others => '0');
    signal act_data             : std_logic_vector((ACC_WIDTH - 1) downto 0)                 := (others => '0');
    signal m_scale              : std_logic_vector((M_SCALE_WIDTH - 1) downto 0)             := (others => '0');
    signal z_scale              : std_logic_vector((Z_SCALE_WIDTH - 1) downto 0)             := (others => '0');
    signal sign_shr             : std_logic_vector(MUL_STAGES_CNT - 1 downto 0)              := (others => '0');
    signal act_reg              : std_logic_vector((ACC_WIDTH - 1) downto 0)                 := (others => '0'); -- Act func register
    signal mul_m_reg_nxt        : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0');
    signal mul_m_reg            : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0'); -- Mul M_Scale register
    signal sum_z_reg            : std_logic_vector((ACC_WIDTH - 1) downto 0)                 := (others => '0'); -- Sum Z_Scale register
    signal act_res              : std_logic_vector((ACC_WIDTH - 1) downto 0)                 := (others => '0'); --  Act comb-result
    signal mul_res              : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0'); -- I(x1).F(x2) (raw product)
    signal signed_mul_res       : std_logic_vector((ACC_WIDTH + M_SCALE_WIDTH - 1) downto 0) := (others => '0'); -- I(x1).F(x2) (raw product)
    signal shared_stg_shr       : std_logic_vector(PREDIC_STAGES_CNT - 1 downto 0)           := (others => '0');
    signal mac_pairs_cnt_vector : std_logic_vector(Log2Ceil(MAC_PAIR_CNT) - 1 downto 0)      := (others => '0');
    signal quant_stg_shr        : std_logic_vector(QUANT_STAGES_CNT - 1 downto 0)            := (others => '0');
    signal sum_z_res            : signed((ACC_WIDTH - 1) downto 0)                           := (others => '0');
    signal mac_pairs_cnt        : natural range 0 to (MAC_PAIR_CNT - 1)                      := 0; -- Computed mac_pairs counter
begin

    Mac_Pair_Counter : entity work.Counter_FlgQ
        generic map (
            CNT_MAX => MAC_PAIR_CNT
        )
        port map (
            clk      => clk,
            rst      => rst,
            max      => mac_pair_cnt_max,
            en       => quant_out_last_nxt or last_predict_out,
            out_data => mac_pairs_cnt_vector
        );
    mac_pairs_cnt <= to_integer(unsigned(mac_pairs_cnt_vector));

    Z_Scale_Rom : entity work.Rom_SpCnt
        generic map (
            FILE_NAME => RomFileName(INST_INX, 'Z', 0),
            CELLS_CNT => Z_ROM_SIZE,
            OUT_WIDTH => Z_SCALE_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            re       => re_z_scale,
            out_data => z_scale
        );

    M_Scale_Rom : entity work.Rom_SpCnt
        generic map (
            FILE_NAME => RomFileName(INST_INX, 'M', 0),
            CELLS_CNT => M_ROM_SIZE,
            OUT_WIDTH => M_SCALE_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            re       => in_mac_val,
            out_data => m_scale
        );

    Karatsuba : entity work.Karatsuba_Mul
        generic map (
            C_WIDTH => ACC_WIDTH
        )
        port map (
            clk      => clk,
            a        => act_data,
            b        => m_scale,
            data_out => mul_res
        );

    ReLU : entity work.ReLu_nEn
        generic map (
            WORD_WIDTH => ACC_WIDTH
        )
        port map (
            n_en => last_layer,
            a    => in_mac_data,
            q    => act_res
        );

    AbsOp : entity work.AbsoluteValue
        generic map (
            WORD_WIDTH => ACC_WIDTH
        )
        port map (
            a => act_reg,
            q => act_data
        );

    ClipOp : entity work.Clip
        generic map (
            WORD_WIDTH => ACC_WIDTH,
            OUT_WIDTH  => NEURON_WIDTH
        )
        port map (
            a => sum_z_reg,
            q => clip_data
        );

    TwoComplement : entity work.TwosComplement
        generic map (
            WORD_WIDTH => mul_res'high + 1
        )
        port map (
            a => mul_res,
            q => signed_mul_res
        );

    -- Generating layers end detection comparators
    LAYERS_END_PAIRS : for i in 0 to (LAYERS_COUNT - 3) generate
    begin
        layers_end_vct(i) <= '1' when mac_pairs_cnt = (LAST_MAC_PAIRS_MAP(i) - 1) else '0';
    end generate;
    layers_end_vct(LAYERS_COUNT - 2) <= mac_pair_cnt_max; -- Last layer end
    layer_end_nxt                    <= OR_REDUCE(layers_end_vct);

    -- Z_rom read enable
    re_z_scale <= quant_out_last_nxt and layer_end_nxt;
    -- Last layer flag 
    last_layer_nxt <= '1' when (mac_pairs_cnt > LAST_HID_MAC_PAIR) else '0';
    -- Mul register data save select  
    mul_m_reg_nxt <= signed_mul_res when sign_shr(sign_shr'high) else mul_res;
    -- Out predict valid
    out_predict_data <= mul_m_reg;
    -- Add Z_Scale to int part
    sum_z_res <= signed(mul_m_reg(mul_m_reg'high downto (mul_m_reg'high - ACC_WIDTH + 1))) + signed(z_scale);
    -- Pipline shr logic
    quant_out_val_nxt   <= quant_stg_shr(0);
    quant_out_last_nxt  <= quant_stg_shr(0) and (not shared_stg_shr(6));
    predict_out_val_nxt <= shared_stg_shr(5) and last_layer;
    last_predict_out    <= predict_out_val_nxt and (not shared_stg_shr(4));


    Seq_Logic_Arst : process(clk, rst)
    begin
        if(rst) then
            shared_stg_shr <= (others => '0');
            quant_stg_shr  <= (others => '0');
        elsif rising_edge(clk) then
            -- Advance shared stage pipe
            shared_stg_shr <= shared_stg_shr(shared_stg_shr'high - 1 downto 0) & in_mac_val;
            -- Advance quant stage pipe
            if(not last_layer) then
                quant_stg_shr <= quant_stg_shr(quant_stg_shr'high - 1 downto 0) & shared_stg_shr(shared_stg_shr'high);
            end if;
        end if;
    end process;

    Seq_Logic : process(clk)
    begin
        if rising_edge(clk) then
            -- Advance sign stage shr
            sign_shr <= sign_shr(sign_shr'high - 1 downto 0) & act_reg(act_reg'high);
            -- Layers flags
            layer_end     <= layer_end_nxt;
            last_mac_pair <= layers_end_vct(layers_end_vct'high);
            last_layer    <= last_layer_nxt;
            -- Pipline
            predict_out_val <= predict_out_val_nxt;
            quant_out_val   <= quant_stg_shr(0);
            quant_out_last  <= quant_out_last_nxt;
            act_reg         <= act_res;
            mul_m_reg       <= mul_m_reg_nxt;
            sum_z_reg       <= std_logic_vector(sum_z_res);
            out_quant_data  <= clip_data;
        end if;
    end process;

end architecture;