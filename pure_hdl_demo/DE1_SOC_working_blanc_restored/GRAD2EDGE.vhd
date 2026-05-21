library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GRAD2EDGE is

	generic
	(
		THRESHOLD_UP_SQR : natural := 700;--1000
		THRESHOLD_DOWN_SQR : natural := 450 
	);

	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		grad_info : in std_logic_vector(15 downto 0);	
	
		HS : in std_logic;
		VS: in std_logic;
		R	: out std_logic_vector(7 downto 0);	
		G	: out std_logic_vector(7 downto 0);
		B	: out std_logic_vector(7 downto 0)
		
	);

end entity;

architecture rtl of GRAD2EDGE is

TYPE lines_type IS ARRAY (2 downto 0 ) OF std_logic_vector(1023 downto 0);
signal x_count: integer range 0 to 1023 := 0;

component longbuffering is
	port 
	(
		clk  : in std_logic;
		reset: in std_logic;
		x	  : in std_logic_vector(9 downto 0);
		data : in std_logic_vector(15 downto 0);
		
		T0	: out std_logic_vector(15 downto 0);
		T1	: out std_logic_vector(15 downto 0);
		T2	: out std_logic_vector(15 downto 0)
		
	);
end component;

signal t0,t1,t2: std_logic_vector(15 downto 0);
signal rt0,rt1,rt2: std_logic_vector(15 downto 0);
signal rrt0,rrt1,rrt2: std_logic_vector(15 downto 0);
signal rrrt0,rrrt1,rrrt2: std_logic_vector(15 downto 0);
signal prrrt2: std_logic_vector(15 downto 0);
signal counter: integer range 0 to 2 :=0; 
signal lines: lines_type;
signal rx,ry,rrx,rry: std_logic_vector(10 downto 0);


begin

	gradbuffer: longbuffering PORT MAP 
	(
		clk	=> clk,
		reset	=> reset,
		x		=> std_logic_vector(to_unsigned(x_count,10)),
		data	=> grad_info,
		
		T0		=> rt0,
		T1		=> rt1,
		T2		=> rt2
	);

	
			
	process (clk, reset)
	
	begin
		if ((reset = '0') OR (VS = '0')) then
			x_count <= 1023;
			R <= (OTHERS => '0');
			G <= (OTHERS => '0');
			B <= (OTHERS => '0');
			lines <= (OTHERS => (OTHERS => '0'));
			counter <= 0;
	
		elsif (rising_edge(clk)) then
		
			if (HS = '0') then
				lines(counter) <= (OTHERS => '0');
				x_count <= 1023;
				if (counter < 2) then
					counter <= counter +1;
				else 
					counter <= 0;
					
				end if;	
			else
				x_count <= x_count +1;
			end if;
		
			prrrt2 <= rrrt2;
			rrrt2 <= rrt2; rrt2 <= rt2; --rt2 <= t2;
			rrrt1 <= rrt1; rrt1 <= rt1; --rt1 <= t1;
			rrrt0 <= rrt0; rrt0 <= rt0; --rt0 <= t0;
			
			case rrt1(1 downto 0) is
				when "00" =>
					if ((unsigned(rrt0(15 downto 2)) < unsigned(rrt1(15 downto 2))) AND (unsigned(rrt2(15 downto 2)) < unsigned(rrt1(15 downto 2)))) then
						case counter is
							when 0 => 
								lines(0)(x_count) <= '1';
								lines(2)(x_count) <= '1';
							when 1 =>
								lines(1)(x_count) <= '1';
								lines(0)(x_count) <= '1';
							when 2 =>
								lines(2)(x_count) <= '1';
								lines(1)(x_count) <= '1';
						end case;
					end if;
				when "01" =>
					if ((unsigned(rrrt2(15 downto 2)) < unsigned(rrt1(15 downto 2))) AND (unsigned(rt0(15 downto 2)) < unsigned(rrt1(15 downto 2)))) then
							case counter is
								when 0 => 
									lines(0)(x_count-1) <= '1';
									lines(2)(x_count+1) <= '1';
								when 1 =>
									lines(1)(x_count-1) <= '1';
									lines(0)(x_count+1) <= '1';
								when 2 =>
									lines(2)(x_count-1) <= '1';
									lines(1)(x_count+1) <= '1';
							end case;
					end if;
				when "10" =>
					if ((unsigned(rrrt1(15 downto 2)) < unsigned(rrt1(15 downto 2))) AND (unsigned(rt1(15 downto 2)) < unsigned(rrt1(15 downto 2)))) then
						case counter is
							when 0 => 
								lines(1)(x_count-1) <= '1';
								lines(1)(x_count+1) <= '1';
							when 1 =>
								lines(2)(x_count-1) <= '1';
								lines(2)(x_count+1) <= '1';
							when 2 =>
								lines(0)(x_count-1) <= '1';
								lines(0)(x_count+1) <= '1';
						end case;
					end if;
				when "11" =>
					if ((unsigned(rrrt0(15 downto 2)) < unsigned(rrt1(15 downto 2))) AND (unsigned(rt2(15 downto 2)) < unsigned(rrt1(15 downto 2)))) then
						case counter is
							when 0 => 
								lines(2)(x_count-1) <= '1';
								lines(0)(x_count+1) <= '1';
							when 1 =>
								lines(0)(x_count-1) <= '1';
								lines(1)(x_count+1) <= '1';
							when 2 =>
								lines(1)(x_count-1) <= '1';
								lines(2)(x_count+1) <= '1';
						end case;
					end if;
			end case;
	
		if  ((((counter = 0) AND (lines(0)(x_count-2) = '0')) OR
			 ((counter = 1) AND (lines(1)(x_count-2) = '0')) OR
			 ((counter = 2) AND (lines(2)(x_count-2) = '0')) )
		            AND
		(signed(prrrt2) > THRESHOLD_DOWN_SQR)) then
					R <= (others => '1');
					G <= (others => '1');
					B <= (others => '1');
		else
					R <= (others => '0');
					G <= (others => '0');
					B <= (others => '0');
		end if;	
	
	
		end if;
	end process;
end rtl;
