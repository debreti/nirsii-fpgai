-- Quartus Prime VHDL Template
-- Single port RAM with single read/write address 

library ieee;
use ieee.std_logic_1164.all;

entity myconsts is
port
	(
		
		q1024x768		: out std_logic_vector(22 downto 0);
		q512		: out std_logic_vector(10 downto 0)
	);

end entity;

architecture rtl of myconsts is

	

begin

	
	q1024x768 <= (18 =>'1', 19 => '1',others => '0' );
	q512 <= (10 => '1', others => '0');

end rtl;
