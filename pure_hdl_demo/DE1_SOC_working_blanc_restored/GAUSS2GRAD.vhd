library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GAUSS2GRAD is
	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		gauss	   : in std_logic_vector(7 downto 0);
		
		HS: in std_logic;
		VS: in std_logic;
		o_grad : out std_logic_vector(15 downto 0);
		o_gx: out std_logic_vector(7 downto 0);
		o_gy: out std_logic_vector(7 downto 0)
		
	);

end entity;

architecture rtl of GAUSS2GRAD is

signal atan_grad: std_logic_vector(1 downto 0);
signal reg_atan_grad: std_logic_vector(1 downto 0);
signal gxgy : std_logic_vector(15 downto 0);	
signal rx,ry,rrx,rry,rrrx,rrry: std_logic_vector(10 downto 0);
signal x_cont: integer range 0 to 1023;
component buffering is
	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		x	  : in std_logic_vector(9 downto 0);
		data : in std_logic_vector(7 downto 0);
		
		T0	: out std_logic_vector(7 downto 0);
		T1	: out std_logic_vector(7 downto 0);
		T2	: out std_logic_vector(7 downto 0)
	);
end component;

component sqr_lut is
	PORT
	(
		address	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (19 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (19 DOWNTO 0)
	);
end component;

component atanlut
	PORT
	(
		address	: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q			: OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
	);
end component;

signal t0,t1,t2: std_logic_vector(7 downto 0);
signal rt0,rt1,rt2: std_logic_vector(7 downto 0);
signal rrt0,rrt1,rrt2: std_logic_vector(7 downto 0);
signal rrrt0,rrrt1,rrrt2: std_logic_vector(7 downto 0);
signal gx: std_logic_vector(9 downto 0);
signal gy: std_logic_vector(9 downto 0);
signal rgx, rgy: std_logic_vector(9 downto 0);
signal gx_sqr_sig, gy_sqr_sig: std_logic_vector(19 downto 0);
signal reg_gx_sqr_sig, reg_gy_sqr_sig: std_logic_vector(19 downto 0);
signal g_sum: std_logic_vector(20 downto 0);
signal rgx1,rgx2,rgx3,rgy1,rgy2,rgy3: integer;

begin
	bestbbuffer: buffering PORT MAP 
	(
		clk	=> clk,
		reset	=> reset,
		x		=> std_logic_vector(to_unsigned(x_cont,10)),
		data	=> gauss,
		
		T0		=> t0,
		T1		=> t1,
		T2		=> t2
	);
	
	gx_sqr: sqr_lut PORT MAP (
		address	=> gx,
		clock		=> clk,
		data	 	=> (OTHERS => '0'),
		wren	 	=> '0',
		q	 		=> gx_sqr_sig
	);
	
	gy_sqr: sqr_lut PORT MAP (
		address	=> gy,
		clock		=> clk,
		data	 	=> (OTHERS => '0'),
		wren	 	=> '0',
		q	 		=> gy_sqr_sig
	);
	
	atan_lut : atanlut PORT MAP (
		address	=> gxgy,
		clock		=> clk,
		q	 		=> atan_grad
	);
	
	process (clk, reset)
	begin
		g_sum <= std_logic_vector(to_unsigned( to_integer(unsigned(reg_gx_sqr_sig)) + to_integer(unsigned(reg_gy_sqr_sig)), 21));
		if (reset = '0') then
			o_grad <=(OTHERS => '0');
		elsif (rising_edge(clk)) then
		
			
		if (HS = '0') then
			x_cont <= 0;
		else
			x_cont <= x_cont +1;
		end if;
		
			reg_atan_grad <= atan_grad;
			o_grad <= g_sum(20 downto 7) & reg_atan_grad;
			reg_gx_sqr_sig <= gx_sqr_sig;
			reg_gy_sqr_sig <= gy_sqr_sig;
						
			rrrt0 <= rrt0; rrt0 <= rt0; rt0 <= t0(7 downto 3) & "000";
			rrrt1 <= rrt1; rrt1 <= rt1; rt1 <= t1(7 downto 3) & "000";
			rrrt2 <= rrt2; rrt2 <= rt2; rt2 <= t2(7 downto 3) & "000";
	
			rgx1 <= to_integer(unsigned(rrrt0)) -to_integer(unsigned(rrrt2));
			rgx2 <= rgx1 + 2*to_integer(unsigned(rrrt0)) - 2* to_integer(unsigned(rrrt2));
			rgx3 <= rgx2 + to_integer(unsigned(rrrt0)) -to_integer(unsigned(rrrt2));
			if rgx3 < 0 then gx<=std_logic_vector(to_unsigned( -rgx3, 10 )) ; else gx<=std_logic_vector(to_unsigned( rgx3, 10 )) ; end if;
			
			rgy1 <= -to_integer(unsigned(rrrt0)) -to_integer(unsigned(rrrt2)) - 2*to_integer(unsigned(rrrt1)) ;
			rgy2 <= rgy1;
			rgy3 <= rgy2 + to_integer(unsigned(rrrt0)) +to_integer(unsigned(rrrt2)) + 2*to_integer(unsigned(rrrt1)) ;
			if rgy3 < 0 then gy<=std_logic_vector(to_unsigned( -rgy3, 10 )) ; else gy<=std_logic_vector(to_unsigned( rgy3, 10 )) ; end if;
				
			o_gx <= gx(9 downto 2);
			o_gy <= gy(9 downto 2);
			
			gxgy <= std_logic_vector(to_unsigned(rgx3+128, 8)) & std_logic_vector(to_unsigned(rgy3+128, 8));
	
			
		end if;
	end process;
end rtl;
