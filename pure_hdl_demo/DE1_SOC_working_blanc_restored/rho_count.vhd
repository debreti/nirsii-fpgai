library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rho_count is

generic
(
 cos: integer range 0 to 4095 := 0;
 sin: integer range 0 to 4095 := 0
);
	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		edge_info: in std_logic;
		x_std_vec : in std_logic_vector(9 downto 0);
		y_std_vec : in std_logic_vector(9 downto 0);
		--cos_const : in std_logic_vector(11 downto 0);
		--sin_const : in std_logic_vector(11 downto 0);
		
		rho	: out std_logic_vector(9 downto 0)		
	);
end entity;

architecture rtl of rho_count is
signal rho_1: integer range 0 to 2**24-1 := 0;

signal x_count: integer range 0 to 1023 := 0;
signal y_count: integer range 0 to 767  := 0;

begin
x_count <= to_integer(unsigned(x_std_vec));
y_count <= to_integer(unsigned(y_std_vec));

--cos <= to_integer(unsigned(cos_const));
--sin <= to_integer(unsigned(sin_const));
	process (clk, reset)
	begin
		if (reset = '0') then
			rho <= (OTHERS => '0');
			rho_1 <= 0;
		elsif (rising_edge(clk)) then
			rho_1 <= x_count*(cos - 2047) + y_count*sin + 2**22;
			rho <= std_logic_vector(to_unsigned(rho_1,23))(22 downto 13);
		end if;	
	end process;
	
end rtl;