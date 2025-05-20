library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.NN_package.all;

entity Ring_Buffer is
	port (
		clk        : in  std_logic;
		rst        : in  std_logic;
		WE         : in  std_logic;
		RE         : in  std_logic;
		sel_data   : in  std_logic;
		sav_w_prt  : in  std_logic;
		sav_r_prt  : in  std_logic;
		jmp_lstart : in  std_logic;
		func_data  : in  std_logic_vector(WEIGHT_WIDTH - 1 downto 0);
		extr_data  : in  std_logic_vector(WEIGHT_WIDTH - 1 downto 0);
		out_val    : out std_logic_vector(WEIGHT_WIDTH - 1 downto 0);
		layer_end  : out std_logic;
		flayer_end : out std_logic
	);
end Ring_Buffer;

architecture rtl of Ring_Buffer is
	signal write_val    : std_logic_vector(WEIGHT_WIDTH - 1 downto 0);
	signal RAM          : mem_type(0 to RingBufSize - 1)(WEIGHT_WIDTH - 1 downto 0);
	signal ram_adr      : natural range 0 to (RingBufSize - 1);
	signal lstr_prt     : natural range 0 to (RingBufSize - 1);
	signal lend_prt     : natural range 0 to (RingBufSize - 1);
	signal w_ptr        : natural range 0 to (RingBufSize - 1);
	signal r_ptr        : natural range 0 to (RingBufSize - 1);
	signal flayer_cnt   : natural range 0 to (LAYERS(0) - 1) := 0;
	constant flayer_max : natural range 0 to (LAYERS(0) - 1) := LAYERS(0) - 1;
begin
	out_val    <= RAM(ram_adr);
	write_val  <= func_data when (sel_data = '1') else extr_data;
	ram_adr    <= w_ptr     when (WE = '1') else r_ptr;
	layer_end  <= to_std_logic(r_ptr = lend_prt);
	flayer_end <= to_std_logic(flayer_cnt = flayer_max);
	-- Read/Write control
	process(clk,rst)
	begin
		if(rst = '1') then
			lstr_prt   <= 0;
			lend_prt   <= 0;
			w_ptr      <= 0;
			r_ptr      <= 0;
			flayer_cnt <= 0;
		elsif (rising_edge(clk)) then
			-- Write op
			if (WE = '1') then
				RAM(ram_adr) <= write_val;
				w_ptr        <= w_ptr + 1;
			end if;
			-- First layer loading
			if (sel_data = '0' AND WE = '1') then
				if (flayer_end) then
					flayer_cnt <= 0;
				else
					flayer_cnt <= flayer_cnt + 1;
				end if;
			end if;
			-- Read ops
			if (jmp_lstart = '1' OR RE = '1') then
				if (jmp_lstart = '1') then
					r_ptr <= lstr_prt;
				else
					r_ptr <= r_ptr + 1;
				end if;
			end if;
			-- Save r_ptr to first layer val
			if (sav_r_prt = '1') then
				lstr_prt <= ram_adr;
			end if;
			-- Save w_ptr to last layer val
			if (sav_w_prt = '1') then
				if (WE = '1') then
					lend_prt <= ram_adr; -- Valid input
				else
					lend_prt <= ram_adr - 1; -- Blank input
				end if;
			end if;
		end if;
	end process;
end rtl;