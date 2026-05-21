library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Y2GAUSS is

	port
	(
		clk       : in std_logic;
		reset     : in std_logic;
		Y_Channel : in std_logic_vector(7 downto 0);
		HS        : in std_logic;
		VS        : in std_logic;
		gauss : out std_logic_vector(7 downto 0)

	);

end entity;

architecture rtl of Y2GAUSS is

	component buffering is
		port
		(
			clk   : in std_logic;
			reset : in std_logic;
			x     : in std_logic_vector(9 downto 0);
			data  : in std_logic_vector(7 downto 0);

			T0 : out std_logic_vector(7 downto 0);
			T1 : out std_logic_vector(7 downto 0);
			T2 : out std_logic_vector(7 downto 0)
		);
	end component;

	signal t0,t1,t2       : std_logic_vector(7 downto 0);
	signal rt0,rt1,rt2    : std_logic_vector(7 downto 0);
	signal rrt0,rrt1,rrt2 : std_logic_vector(7 downto 0);

	signal x_cont : integer range 0 to 1023;

begin

		gaussbuffer : buffering PORT MAP
		(
			clk   => clk,
			reset => reset,
			x     => std_logic_vector(to_unsigned(x_cont,10)),
			data  => Y_Channel,

			T0 => t0,
			T1 => t1,
			T2 => t2
		);

	process (clk, reset)

	begin
		if (reset = '0') then
			gauss <= (OTHERS => '0');
		elsif (rising_edge(clk)) then

			if (HS = '0') then
				x_cont <= 0;
			else
				x_cont <= x_cont +1;
			end if;

			rrt0 <= rt0; rt0 <= t0;
			rrt1 <= rt1; rt1 <= t1;
			rrt2 <= rt2; rt2 <= t2;

			gauss <= std_logic_vector(to_unsigned( to_integer(unsigned(rrt2)) + to_integer(unsigned(rt2))*2 + to_integer(unsigned(t2)) + to_integer(unsigned(rrt1))*2 + to_integer(unsigned(rt1))*4 + to_integer(unsigned(t1))*2 + to_integer(unsigned(rrt0)) + to_integer(unsigned(rt0))*2 + to_integer(unsigned(t0)) , 12 )) (11 downto 4);



		end if;
	end process;
end rtl;
