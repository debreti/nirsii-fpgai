library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.fixed_pkg.all;
use IEEE.fixed_float_types.all;
library work;
use work.NN_package.all;

entity Act_ReLU is
	Port (
		input  : in  std_logic_vector((2 * DATA_WIDTH) - 1 downto 0);
		output : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end Act_ReLU;

architecture rtl of Act_ReLU is
	signal mac_fx     : sfixed(31 downto 0);   -- I32.F0 
	signal scale_fx   : sfixed(-1 downto -32); -- I0.F32 
	signal scaled     : sfixed(31 downto -32); -- I32.F32 (raw product)
	signal quant_fx   : sfixed(7 downto 0);    -- I8.F0 (quantized mac)
	signal scales_rom : act_fx_scales(0 to LAYERS_COUNT - 1)(-1 downto (-1 * SCALE_WIDTH)) := FxScales;
begin
	-- Convert inputs to fixed-point
	--mac_fx   <= to_sfixed(mac_result, mac_fx);
	--scale_fx <= to_sfixed(scale, scale_fx);
	-- Multiply and rescale
	--scaled <= mac_fx * scale_fx;
	-- Quantize to 8-bit with saturation
	--quant_fx <= resize(
	--		arg         => scaled,
	--		left_index  => quant_fx'high, -- 7 (I8)
	--		right_index => quant_fx'low,  -- 0 (F0)
	--		round_style => fixed_round,
	--		overflow    => fixed_saturate
	-- );
	-- ReLU 	
	output <= (others => '0') when (input(input'high) = '1')
	else (others => '1'); --to_slv(quant_fx);

end rtl;