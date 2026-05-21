library ieee;
use std.textio.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

package NPU_Package is
    /* ┏━━━━━━━━━━━━━┓ */
    -- ┃    TYPES    ┃ --
    /* ┗━━━━━━━━━━━━━┛ */
    type config_type is record
        Mac_Cnt       : natural; -- Кол-во маков
        Layers_Cnt    : natural; -- Кол-во слоев
        Weight_Width  : natural; -- Ширина веса
        Bias_Width    : natural; -- Ширина байса
        Z_Scale_Width : natural; -- Ширина М скейла
        M_Scale_Width : natural; -- Ширина Z скейла
        Acc_Width     : natural; -- Ширина аккомулятора в мак-блоке
        Neuron_Width  : natural; -- Ширина квантовоного значения нейрона
    end record;
    type configs_arr is array (natural range <>) of config_type;
    type natural_arr is array(natural range <>) of natural;
    type sl_arr is array (natural range <>) of std_logic;
    type slv_arr is array(natural range <>) of std_logic_vector;
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    FUNCTIONS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    impure function InputLayerIndex(inst_inx  : natural) return natural;
    impure function OutputLayerIndex(inst_inx : natural) return natural;
    impure function WeightRomSize(inst_inx    : natural) return natural;
    impure function BiasRomSize(inst_inx      : natural) return natural;
    impure function RingBufSize(inst_inx      : natural) return natural;
    impure function M_ScaleRomSize(inst_inx   : natural) return natural;
    impure function MacTypesMapInit(inst_inx  : natural) return sl_arr;
    impure function EdgeMacPairsMap(inst_inx  : natural) return natural_arr;
    impure function ReadHexFile(file_name     : string; depth : natural; width : natural) return slv_arr;
    function RomFileName(inst_inx             : natural; file_prefix : character; file_inx : natural) return string;
    function Log2Ceil(arg                     : natural) return natural;
    function CeilDivide(dividend              : natural; divisor : natural) return natural;
    /* ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ */
    -- ┃    CONSTANTS AUTO-GENERATED    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ */
    -- Path to Rom files folder
    constant MIF_FOLDER_PATH : string := "C:/Users/romac/VHDPlus/Projects/Vivada_Port/NPU/RomFiles/";
    -- Configurations list
    constant NN_CONFIG : configs_arr := (
    0 => (
        Mac_Cnt       => 4,
        Layers_Cnt    => 3,
        Weight_Width  => 8,
        Bias_Width    => 32,
        Z_Scale_Width => 32,
        M_Scale_Width => 32,
        Acc_Width     => 32,
        Neuron_Width  => 8
    )
);
    -- Map of layers for each instance
    constant LAYERS_MAP : natural_arr := (
    784, 128, 10
);
end package;

package body NPU_Package is

    -- Get std_logic_array from hex txt file (Simulation only)
    impure function ReadHexFile( file_name : string; depth : natural; width : natural) return slv_arr is
        file f          : text open read_mode is (MIF_FOLDER_PATH & file_name);
        variable line_v : line;
        variable mem    : slv_arr(0 to depth - 1)(width - 1 downto 0);
        variable tmp    : std_logic_vector(width-1 downto 0);
        variable i      : integer := 0;
    begin
        while not endfile(f) and i < depth loop
            readline(f, line_v);
            hread(line_v, tmp); -- reads HEX string
            mem(i) := tmp;
            i      := i + 1;
        end loop;
        return mem;
    end function;

    -- Get name of Rom file at specific index of current instance
    function RomFileName(inst_inx : natural; file_prefix : character; file_inx : natural) return string is
        -- Must declare a type for variables inside function
        type str_arr_ten is array (0 to 99) of string(1 to 2);
        type str_arr_hundred is array (0 to 999) of string(1 to 3);
        -- Look up tables for file prefixes
        variable ten_lut     : str_arr_ten;
        variable hundred_lut : str_arr_hundred;
    begin
        -- build Instance number 2-digit LUT (00..99)
        for i in 0 to 99 loop
            ten_lut(i) := character'val(character'pos('0') + i / 10)
                & character'val(character'pos('0') + i mod 10);
        end loop;
        -- Build MAC number 3-digit LUT (000..999)
        for i in 0 to 999 loop
            hundred_lut(i) := character'val(character'pos('0') + i / 100)
                & character'val(character'pos('0') + (i / 10) mod 10)
                & character'val(character'pos('0') + i mod 10);
        end loop;
        -- Is Mac ROM?
        if(file_prefix = 'W' or file_prefix = 'B') then
            return MIF_FOLDER_PATH & "I" & ten_lut(inst_inx) & file_prefix & hundred_lut(file_inx) & ".txt";
        else
            return MIF_FOLDER_PATH & "I" & ten_lut(inst_inx) & file_prefix & ".txt";
        end if;
    end function;

    -- Get index of input layer of current instance
    impure function InputLayerIndex(inst_inx : natural) return natural is
        variable input_layer_inx : natural := 0;
    begin
        -- Getting index of input layer of current instance
        for i in 0 to (inst_inx - 1) loop
            input_layer_inx := input_layer_inx + NN_CONFIG(i).Layers_Cnt;
        end loop;
        return input_layer_inx;
    end function;

    -- Get index of output layer of current instance
    impure function OutputLayerIndex(inst_inx : natural) return natural is
        variable output_layer_inx : natural := 0; -- Output layer index of current instance
    begin
        -- Getting index of output layer of current instance
        for i in 0 to inst_inx loop
            output_layer_inx := output_layer_inx + NN_CONFIG(i).Layers_Cnt;
        end loop;
        return output_layer_inx - 1;
    end function;

    -- Gets number cells for M_Scale Map Rom
    impure function M_ScaleRomSize(inst_inx : natural) return natural is
        variable cells_cnt             : natural := 0;                              -- Rom cells count
        constant LAYERS_CNT            : natural := NN_CONFIG(inst_inx).Layers_Cnt; -- Layers count of current instance
        constant FIRST_HIDEN_LAYER_INX : natural := InputLayerIndex(inst_inx) + 1;  -- First hidden layer index of current instance
        constant OUT_LAYER_INX         : natural := OutputLayerIndex(inst_inx);     -- Output layer index of current instance
    begin
        -- Computing M_Scale Rom size skipping first layer
        for i in FIRST_HIDEN_LAYER_INX to OUT_LAYER_INX loop
            cells_cnt := cells_cnt + LAYERS_MAP(i);
        end loop;
        return cells_cnt;
    end function;

    -- Gets number cells for Bias Map Rom
    impure function BiasRomSize(inst_inx : natural) return natural is
        variable cells_cnt             : natural := 0; -- Rom cells count
        variable mac_ops_cnt           : natural := 0;
        constant LAYERS_CNT            : natural := NN_CONFIG(inst_inx).Layers_Cnt; -- Layers count of current instance
        constant FIRST_HIDEN_LAYER_INX : natural := InputLayerIndex(inst_inx) + 1;  -- First hidden layer index of current instance
        constant OUT_LAYER_INX         : natural := OutputLayerIndex(inst_inx);     -- Output layer index of current instance
        constant MAC_CNT               : natural := NN_CONFIG(inst_inx).Mac_Cnt;
    begin
        -- Computing Bias Rom size skipping first layer
        for i in FIRST_HIDEN_LAYER_INX to OUT_LAYER_INX loop
            mac_ops_cnt := CeilDivide(LAYERS_MAP(i), MAC_CNT);
            cells_cnt   := cells_cnt + mac_ops_cnt;
        end loop;
        return cells_cnt;
    end function;

    -- Gets number cells for Weight Map Rom
    impure function WeightRomSize(inst_inx : natural) return natural is
        variable mac_ops_cnt           : natural := 0;
        variable cells_cnt             : natural := 0;
        constant LAYERS_CNT            : natural := NN_CONFIG(inst_inx).Layers_Cnt; -- Layers count of current instance
        constant FIRST_HIDEN_LAYER_INX : natural := InputLayerIndex(inst_inx) + 1;  -- First hidden layer index of current instance
        constant OUT_LAYER_INX         : natural := OutputLayerIndex(inst_inx);     -- Output layer index of current instance
        constant MAC_CNT               : natural := NN_CONFIG(inst_inx).Mac_Cnt;
    begin
        -- Computing Weight Rom size skipping first layer
        for i in FIRST_HIDEN_LAYER_INX to OUT_LAYER_INX loop
            mac_ops_cnt := CeilDivide(LAYERS_MAP(i), MAC_CNT);
            cells_cnt   := cells_cnt + (mac_ops_cnt * LAYERS_MAP(i - 1));
        end loop;
        return cells_cnt;
    end function;

    -- Get number cells for Ring Buffer
    impure function RingBufSize(inst_inx : natural) return natural is
        variable cells_cnt             : natural := 0;
        constant LAYERS_CNT            : natural := NN_CONFIG(inst_inx).Layers_Cnt; -- Layers count of current instance
        constant FIRST_HIDEN_LAYER_INX : natural := InputLayerIndex(inst_inx) + 1;  -- First hidden layer index of current instance
        constant LAST_HIDEN_LAYER_INX  : natural := OutputLayerIndex(inst_inx) - 1; -- Last hidden layer index of current instance
    begin
        -- Computing Ring Buffer size skipping first layer
        for i in FIRST_HIDEN_LAYER_INX to LAST_HIDEN_LAYER_INX loop
            if (LAYERS_MAP(i-1) + LAYERS_MAP(i) > cells_cnt) then
                cells_cnt := LAYERS_MAP(i-1) + LAYERS_MAP(i);
            end if;
        end loop;
        return cells_cnt;
    end function;

    -- Get array of arch type for each mac
    impure function MacTypesMapInit(inst_inx : natural) return sl_arr is
        constant LAYERS_CNT            : natural                  := NN_CONFIG(inst_inx).Layers_Cnt; -- Layers count of current instance
        constant FIRST_HIDEN_LAYER_INX : natural                  := InputLayerIndex(inst_inx) + 1;  -- First hidden layer index of current instance
        constant OUT_LAYER_INX         : natural                  := OutputLayerIndex(inst_inx);     -- Output layer index of current instance
        constant MAC_CNT               : natural                  := NN_CONFIG(inst_inx).Mac_Cnt;
        variable mac_fiting            : natural                  := 0;               -- How accurate mac_pair covers a layer
        variable mac_types             : sl_arr(0 to MAC_CNT - 1) := (others => '0'); -- First mac is always nonBlank
    begin
        -- Computing mac types array (Blank checker or not)
        for i in FIRST_HIDEN_LAYER_INX to OUT_LAYER_INX loop
            mac_fiting := LAYERS_MAP(i);
            -- Computing how many mac-pairs fit in current layer
            while mac_fiting >= MAC_CNT loop
                mac_fiting := mac_fiting - MAC_CNT;
            end loop;
            -- If macs overfit at end of layer -> there are blanks present
            if (mac_fiting /= 0) then
                mac_types(mac_fiting) := '1';
            end if;
        end loop;
        return mac_types;
    end function;

    -- Get array of indexes of each non-first layers's final mac-pair
    impure function EdgeMacPairsMap(inst_inx : natural) return natural_arr is
        constant LAYERS_CNT            : natural                            := NN_CONFIG(inst_inx).Layers_Cnt; -- Layers count of current instance
        constant FIRST_HIDEN_LAYER_INX : natural                            := InputLayerIndex(inst_inx) + 1;  -- First hidden layer index of current instance
        constant OUT_LAYER_INX         : natural                            := OutputLayerIndex(inst_inx);     -- Output layer index of current instance
        constant MAC_CNT               : natural                            := NN_CONFIG(inst_inx).Mac_Cnt;
        variable mac_pair_cnt          : natural                            := 0;
        variable edge_pairs_map        : natural_arr(0 to (LAYERS_CNT - 2)) := (others => 0); -- Exclude first layer
    begin
        -- Computing layers's final mac-pairs
        for i in FIRST_HIDEN_LAYER_INX to OUT_LAYER_INX loop
            mac_pair_cnt          := mac_pair_cnt + CeilDivide(LAYERS_MAP(i), MAC_CNT);
            edge_pairs_map(i - 1) := mac_pair_cnt;
        end loop;
        return edge_pairs_map;
    end function;

    -- Division with positive ceil (dividend must be greater then divisor)
    function CeilDivide(dividend : natural; divisor : natural) return natural is
        variable quotient : natural;
    begin
        quotient := dividend / divisor;
        if (dividend mod divisor /= 0) then
            quotient := quotient + 1;
        end if;
        return quotient;
    end function;

    -- Get bits count needed to represent natural number (min 1 bit)
    function Log2Ceil(arg : natural) return natural is
        variable res : natural := 0;
        variable val : natural;
    begin
        -- Safety: avoid zero-width vectors
        if arg <= 1 then
            return 1;
        end if;
        val := arg - 1;
        while val > 0 loop
            val := val / 2;
            res := res + 1;
        end loop;
        return res;
    end function;

end package body;

