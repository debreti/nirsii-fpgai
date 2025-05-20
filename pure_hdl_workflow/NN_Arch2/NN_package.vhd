library ieee;
use std.textio.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
--library ieee_proposed;
--use ieee_proposed.fixed_float_types.all;
--use ieee_proposed.fixed_pkg.all;
--use ieee_proposed.float_pkg.all; 

package NN_package is

	-- Types declarations
	type natural_arr is array(natural range <>) of natural;
	type slve_arr is array(natural range <>) of std_logic_vector;
	type slve_2D_arr is array (natural range <>, natural range <>) of std_logic_vector;
	type sl_arr is array (natural range <>) of std_logic;
	type real_arr is array (natural range <>) of real;
	--type act_fx_scales is array (natural range <>) of sfixed;

	-- Constants declarations
	constant BIAS_FILE      : string;
	constant WEIGHT_FILE    : string;
	constant BIAS_WIDTH     : natural;
	constant WEIGHT_WIDTH   : natural;
	constant MAC_COUNT      : natural;
	constant LAYERS_COUNT   : natural;
	constant SCALE_WIDTH    : natural;
	constant ACC_WIDTH      : natural;
	constant EXP_LAYER_SIZE : natural;
	constant BIAS_MAP       : slve_2D_arr;
	constant WEIGHT_MAP     : slve_2D_arr;
	constant SCALES         : real_arr;
	constant LAYERS         : natural_arr;

	-- Function declarations
	function WeightRomSize return natural;
	function BiasRomSize return natural;
	function RingBufSize return natural;
	function ExpLayerSize return natural;
	function AccWidth return natural;
	--function FxScales return act_fx_scales;
	function WeigthMapInit return slve_2D_arr;
	function BiasMapInit return slve_2D_arr;
	function RomLayersIndexes return natural_arr;
	function to_std_logic(b      : boolean) return std_logic;
	function Log2ceil (arg       : positive) return natural;
	function CeilDivide(dividend : positive; divisor : positive) return natural;

end package NN_package;

package body NN_package is

	--  -----------------
	-- | CONSTANTS INITS |
	--  -----------------

	-- Mac modules count
	constant MAC_COUNT : natural := 4;

	-- Data bit width 
	constant BIAS_WIDTH   : natural := 32;
	constant WEIGHT_WIDTH : natural := 8;  -- Weight / Neuron_val 
	constant SCALE_WIDTH  : natural := 15; -- I0.F(?)

	-- Layers parameters 
	constant LAYERS_COUNT : natural                              := 5;
	constant LAYERS       : natural_arr(0 to (LAYERS_COUNT - 1)) := (4, 8, 6, 4, 4);
	constant SCALES       : real_arr(0 to (LAYERS_COUNT - 2))    := (0.5421, 0.6231, 0.214, 0.03275);

	-- File paths  
	constant BIAS_FILE   : string := "rom_content_hex.txt";
	constant WEIGHT_FILE : string := "rom_content_hex.txt";

	-- AUTO-INIT (Modifying this will corrupt synthesis)
	constant ACC_WIDTH      : natural                                                                                  := AccWidth;
	constant RB_SIZE        : natural                                                                                  := RingBufSize;
	constant EXP_LAYER_SIZE : natural                                                                                  := ExpLayerSize;
	constant BIAS_MAP       : slve_2D_arr(0 to (MAC_COUNT - 1), 0 to (BiasRomSize - 1))((BIAS_WIDTH - 1) downto 0)     := (others => (others => (others => '0'))); --:= BiasMapInit;
	constant WEIGHT_MAP     : slve_2D_arr(0 to (MAC_COUNT - 1), 0 to (WeightRomSize - 1))((WEIGHT_WIDTH - 1) downto 0) := (others => (others => (others => '0'))); --:= WeigthMapInit;

	--  -----------------
	-- | FUNCTIONS INITS |
	--  -----------------

	-- Convert boolen expresssion into std_logic
	function to_std_logic(b : boolean) return std_logic is
	begin
		if b then
			return '1';
		else
			return '0';
		end if;
	end function;

	-- Division with positive ceil
	function CeilDivide(dividend : positive; divisor : positive) return positive is
		variable quotient : positive;
	begin
		if dividend < divisor then
			return 1;
		end if;
		quotient := dividend / divisor;
		if (dividend mod divisor /= 0) then
			quotient := quotient + 1;
		end if;
		return quotient;
	end function;

	-- Get bits count needed to represent natural number
	function Log2Ceil(arg : natural) return natural is
		variable tmp : positive := 1;
		variable log : natural  := 0;
	begin
		if arg = 1 then
			return 0;
		end if;
		while arg > tmp loop
			tmp := tmp * 2;
			log := log + 1;
		end loop;
		return log;
	end function;

	-- Gets the size of expansion layer (widest layer)
	function ExpLayerSize return positive is
		variable expLaySize : positive := 1;
	begin
		for i in 0 to (LAYERS_COUNT - 1) loop
			if (LAYERS(i) > expLaySize) then
				expLaySize := LAYERS(i);
			end if;
		end loop;
		return expLaySize;
	end function;

	-- Get acc width to correct overflow
	function AccWidth return natural is
		variable max_mul : natural;
		variable max_num : natural;
	begin
		return 32;
	--max_num := 2 ** DATA_WIDTH - 1;
	--max_mul := max_num ** 2;
	--return Log2Ceil(max_mul * ExpLayerSize + BIAS);
	end function;

	-- Gets number cells for Weight Map Rom
	function WeightRomSize return natural is
		variable i         : natural := 0;
		variable mac_pairs : natural := 0;
		variable cellsCnt  : natural := 0;
	begin
		for i in 1 to (LAYERS_COUNT - 1) loop
			mac_pairs := ceilDivide(LAYERS(i), MAC_COUNT);
			cellsCnt  := cellsCnt + mac_pairs;
			cellsCnt  := cellsCnt + mac_pairs * LAYERS(i - 1);
		end loop;
		return cellsCnt;
	end function;

	-- Gets number cells for Bias Map Rom
	function BiasRomSize return natural is
		variable i         : natural := 0;
		variable mac_pairs : natural := 0;
		variable cellsCnt  : natural := 0;
	begin
		for i in 1 to (LAYERS_COUNT - 1) loop
			mac_pairs := ceilDivide(LAYERS(i), MAC_COUNT);
			cellsCnt  := cellsCnt + mac_pairs;
			cellsCnt  := cellsCnt + mac_pairs * LAYERS(i - 1);
		end loop;
		return cellsCnt;
	end function;

	-- Get rom indexes of first weight of layers
	function RomLayersIndexes return natural_arr is
		variable i          : natural := 0;
		variable mac_pairs  : natural := 0;
		variable cellsCnt   : natural := 0;
		variable last_pairs : natural_arr(0 to LAYERS_COUNT - 2); -- (Excluding final layer)
	begin
		last_pairs(0) := 0;                   -- Points at flayer start adress
		for i in 1 to (LAYERS_COUNT - 2) loop -- Exclude flayer
			mac_pairs     := ceilDivide(LAYERS(i), MAC_COUNT);
			cellsCnt      := cellsCnt + mac_pairs * LAYERS(i - 1);
			last_pairs(i) := cellsCnt; -- Points at layer start adress
		end loop;
		return last_pairs;
	end function;

	-- Get array of scales in fixed point notation
	--function FxScales return act_fx_scales is
	--	variable i          : natural := 0;
	--	variable scales_arr : act_fx_scales(0 to LAYERS_COUNT - 1)(-1 downto (-1 * SCALE_WIDTH));
	--begin
	--	for i in 0 to (LAYERS_COUNT - 1) loop
	--		scales_arr(i) := to_sfixed(SCALES(i), -1, (-1 * SCALE_WIDTH));
	--	end loop;
	--	return scales_arr;
	--end function;

	-- Initialize Bias map Rom content from file
	function BiasMapInit return slve_2D_arr is
		file text_file     : text open read_mode is BIAS_FILE;
		variable text_line : line;
		variable temp_slv  : std_logic_vector(BiasRomSize - 1 downto 0);
		variable bias_map  : slve_2D_arr(0 to (MAC_COUNT - 1), 0 to (BiasRomSize - 1))((BIAS_WIDTH - 1) downto 0);
	begin
		--for i in 0 to (BiasRomSize - 1) loop
		--	readline(text_file, text_line);
		--	hread(text_line, temp_slv);
		--rom_content(i) := temp_slv;
		--end loop;
		--file_close(text_file);
		return bias_map;
	end function;

	-- Initialize Weights Map Rom content from file
	function WeigthMapInit return slve_2D_arr is
		file text_file      : text open read_mode is WEIGHT_FILE;
		variable text_line  : line;
		variable temp_slv   : std_logic_vector(WeightRomSize - 1 downto 0);
		constant weight_map : slve_2D_arr(0 to (MAC_COUNT - 1), 0 to (WeightRomSize - 1))((WEIGHT_WIDTH - 1) downto 0);
	begin
		--for i in 0 to (WeightRomSize - 1) loop
		--	readline(text_file, text_line);
		--	hread(text_line, temp_slv);
		--	weight_map(i) := temp_slv;
		--end loop;
		--file_close(text_file);
		return weight_map;
	end function;

	-- Get number cells for Ring Buffer
	function RingBufSize return natural is
		variable expLaySize : natural := 1;
	begin
		for i in 1 to (LAYERS_COUNT - 1) loop
			if (LAYERS(i-1) + LAYERS(i)) > expLaySize then
				expLaySize := LAYERS(i-1) + LAYERS(i);
			end if;
		end loop;
		return expLaySize;
	end function;

end package body NN_package;