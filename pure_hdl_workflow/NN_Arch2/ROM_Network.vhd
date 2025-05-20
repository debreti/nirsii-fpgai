library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NN_package.all;

entity ROM_Network is
	port
	(
		clk          : in  std_logic;
		rst          : in  std_logic;
		RE           : in  std_logic;
		flayer_start : out std_logic;
		layer_start  : out std_logic;
		rom_out      : out std_logic_vector(MAC_COUNT * WEIGHT_WIDTH - 1 downto 0)
	);
end entity;

architecture rtl of ROM_Network is
	signal adr_count         : natural range 0 to (RomCellsCount - 1);
	signal matches           : std_logic_vector(0 to LAYERS_COUNT - 2);
	constant layer_start_inx : last_macs_pairs(0 to LAYERS_COUNT - 2)                   := RomLayersIndexes;
	signal ROM_DATA          : mem_type(0 to RomCellsCount - 1)(ROM_WIDTH - 1 downto 0) := RomInit(ROM_FILE);
begin
	rom_out <= ROM_DATA(adr_count);
	GEN_COMPARATORS : for i in 0 to (LAYERS_COUNT - 2) generate
		matches(i) <= to_std_logic(adr_count = layer_start_inx(i));
	end generate;
	flayer_start <= matches(0); -- Point at rom zero adr
	layer_start  <= or_reduce(matches);
	-- Rom adress increment
	process(clk,rst)
	begin
		if(rst = '1') then
			adr_count <= 0;
		elsif (rising_edge(clk)) then
			if(RE = '1') then
				if (adr_count = (RomCellsCount - 1)) then
					adr_count <= 0;
				else
					adr_count <= adr_count + 1;
				end if;
			end if;
		end if;
	end process;
end ROM_Network;