library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity edge_from_y is

	generic
	(
		TRESHOLD_SQR : natural := 2000000 
	);

	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		Y	   	: in std_logic_vector(7 downto 0);
		VS	    : in std_logic;
		HS	    : in std_logic;
		
		R	: out std_logic_vector(7 downto 0);	
		G	: out std_logic_vector(7 downto 0);
		B	: out std_logic_vector(7 downto 0)
		
	);

end entity;

architecture rtl of edge_from_y is


signal x_count: integer range 0 to 1023 := 0;

signal rHS: std_logic := '0';
signal rVS: std_logic := '0';

component buffering is
	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		x	: in std_logic_vector(9 downto 0);
		HS : in std_logic;
		data : in std_logic_vector(7 downto 0);
		
		T0	: out std_logic_vector(7 downto 0);
		T1	: out std_logic_vector(7 downto 0);
		T2	: out std_logic_vector(7 downto 0)
		
	);
end component;

component rootlut is
		PORT
	(
		address	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (19 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (19 DOWNTO 0)
	);
end component;

signal t0,t1,t2: std_logic_vector(7 downto 0);
signal rt0,rt1,rt2: std_logic_vector(7 downto 0);
signal rrt0,rrt1,rrt2: std_logic_vector(7 downto 0);

signal x_std_vec: std_logic_vector(9 downto 0);
signal gx: std_logic_vector(9 downto 0);
signal gy: std_logic_vector(9 downto 0);
signal gx_sqr_sig, gy_sqr_sig: std_logic_vector(19 downto 0);


begin
	
	bestbbuffer: buffering PORT MAP 
	(
		clk		=> clk,
		reset		=> reset,
		x		=> x_std_vec,
		HS 	=> HS,
		data	=> Y,
		
		T0		=> t0,
		T1		=> t1,
		T2		=> t2
	);
	
	gx_sqr: rootlut PORT MAP (
		address	=> gx,
		clock		=> clk,
		data	 	=> (OTHERS => '0'),
		wren	 	=> '0',
		q	 		=> gx_sqr_sig
	);
	
	gy_sqr: rootlut PORT MAP (
		address	=> gy,
		clock		=> clk,
		data	 	=> (OTHERS => '0'),
		wren	 	=> '0',
		q	 		=> gy_sqr_sig
	);

	
	x_std_vec <= std_logic_vector(to_unsigned(x_count,10));
			
	process (clk, reset)

	
	begin
	if (reset = '0') then
	--
	x_count <= 0;
	rHS <= '0';
	rVS <= '0';
	
	
		elsif (rising_edge(clk)) then
			rHS <= HS;
			rVS <= VS;

			if (VS = '0' AND rVS = '1') then
				x_count <= 0;
			end if;
			if (HS = '0' AND rHS = '1') then
				x_count <= 0;
			end if;
			if (HS = '1' AND VS = '1') then
				x_count <= x_count + 1;
			end if;
			
			rrt0 <= rt0; rt0 <= t0;
			rrt1 <= rt1; rt1 <= t1;
			rrt2 <= rt2; rt2 <= t2;
			
			gx <= std_logic_vector(to_unsigned( to_integer(unsigned(rrt0)) + to_integer(unsigned(rt0))*2 + to_integer(unsigned(t0))  -  to_integer(unsigned(rrt2)) - to_integer(unsigned(rt2))*2  - to_integer(unsigned(t2)) , 10 ));
			gy <= std_logic_vector(to_unsigned( to_integer(unsigned(t0)) + to_integer(unsigned(t1))*2 + to_integer(unsigned(t2))  -  to_integer(unsigned(rrt2)) - to_integer(unsigned(rrt1))*2  - to_integer(unsigned(rrt0)) , 10 ));
			
			if ((unsigned(gx_sqr_sig) + unsigned(gy_sqr_sig)) > TRESHOLD_SQR ) then
				R <= (OTHERS => '1');
				G <= (OTHERS => '1');
				B <= (OTHERS => '1');
			else
				R <= (OTHERS => '0');
				G <= (OTHERS => '0');
				B <= (OTHERS => '0');
			end if;
				
		end if;
	end process;

	

end rtl;
