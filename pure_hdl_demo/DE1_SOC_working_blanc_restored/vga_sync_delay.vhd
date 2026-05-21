library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync_delay is

	generic
	(
	 --DELAY: integer := 128
		X_MAX : natural := 1023;
		Y_MAX : natural := 767

	);
	
	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		
		ix	    	: in std_logic_vector(10 downto 0);
		iy	    	: in std_logic_vector(10 downto 0);
		i_VS	    : in std_logic;
		i_HS	    : in std_logic;
		SWITCH_9 : in std_logic;
		
		o_VS	: out std_logic;	
		o_HS	: out std_logic
		
		
	);

end entity;

architecture rtl of vga_sync_delay is

signal HS_count: std_logic;
signal VS_count: std_logic;

--signal HS_sr: std_logic_vector(DELAY-1 downto 0):= (others => '0');
--signal VS_sr: std_logic_vector(DELAY-1 downto 0):= (others => '0');
begin
			
	process (clk, reset)
	
	begin
	if (reset = '0') then

	--	HS_sr <= (others => '0');
	--	VS_sr <= (others => '0');
	HS_count <= '0';
	VS_count <= '0';
	
	elsif (rising_edge(clk)) then
	--	HS_sr(0)	<=	i_HS;
	--	VS_sr(0) <= i_VS;		
	--	HS_sr(DELAY-1 downto 1) <= HS_sr(DELAY-2 downto 0);
	--	VS_sr(DELAY-1 downto 1) <= VS_sr(DELAY-2 downto 0);
		if (ix = std_logic_vector(to_unsigned(X_MAX,11))) then
			HS_count <= '0';
		else 
			HS_count <= '1';
		end if;
		if (iy = std_logic_vector(to_unsigned(Y_MAX,11))) then
			VS_count <= '0';
		else 
			VS_count <= '1';
		end if;
		
	end if;
	
	if (SWITCH_9  = '1') then
	--		o_HS<=HS_sr(DELAY-1);
	--		o_VS<=VS_sr(DELAY-1);
		o_HS<=HS_count;
		o_VS<=VS_count;
			
		else
			o_HS <= i_HS;
			o_VS <= i_VS;
		end if;
		
	end process;
	
	

	

end rtl;
