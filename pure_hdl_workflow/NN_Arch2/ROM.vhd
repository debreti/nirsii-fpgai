library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.NN_package.all;

entity ROM is
	generic
	(
		WEIGHT_ROM : boolean := true;
		MEM_SIZE   : natural := 1;
		OUT_WIDTH  : natural := 1 -- MAC_COUNT * WEIGHT_WIDTH
	);
	port
	(
		clk     : in  std_logic;
		rst     : in  std_logic;
		RE      : in  std_logic;
		adr     : in  std_logic_vector((Log2Ceil(MEM_SIZE) - 1) downto 0);
		rom_out : out std_logic_vector((OUT_WIDTH - 1) downto 0)
	);
end entity;

architecture rtl of ROM is
	signal adr_count : natural range 0 to (MEM_SIZE - 1);
	signal rom_data  : slve_arr(0 to (MEM_SIZE - 1))((OUT_WIDTH - 1) downto 0) := (0 => "1");
begin
	rom_out <= rom_data(adr_count);
	-- Rom adress increment
	process(clk,rst)
	begin
		if(rst = '1') then
			adr_count <= 0;
		elsif (rising_edge(clk)) then
			if(RE = '1') then
				if (adr_count = (MEM_SIZE - 1)) then
					adr_count <= 0;
				else
					adr_count <= adr_count + 1;
				end if;
			end if;
		end if;
	end process;
end rtl;