library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity longbuffering is

	generic
	(
		X_MAX : natural := 1023
	);
	
	port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		x	: in std_logic_vector(9 downto 0);
		data : in std_logic_vector(15 downto 0);
		
		T0	: out std_logic_vector(15 downto 0);
		T1	: out std_logic_vector(15 downto 0);
		T2	: out std_logic_vector(15 downto 0)
		
	);

end entity;

architecture rtl of longbuffering is

component long_buf is
PORT
	(
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
end component;

signal state: integer range 0 to 3 :=0; 
signal wren0, wren1, wren2, wren3: std_logic;
signal q0, q1, q2, q3: std_logic_VECTOR (15 DOWNTO 0);

begin

buf00 : long_buf PORT MAP (
		clock	 => clk,
		data	 => data,
		rdaddress	 => x,
		wraddress	 => x,
		wren	 => wren0,
		q	 => q0
	);
	
buf01 : long_buf PORT MAP (
		clock	 => clk,
		data	 => data,
		rdaddress	 => x,
		wraddress	 => x,
		wren	 => wren1,
		q	 => q1
	);


buf02 : long_buf PORT MAP (
		clock	 => clk,
		data	 => data,
		rdaddress	 => x,
		wraddress	 => x,
		wren	 => wren2,
		q	 => q2
	);


buf03 : long_buf PORT MAP (
		clock	 => clk,
		data	 => data,
		rdaddress	 => x,
		wraddress	 => x,
		wren	 => wren3,
		q	 => q3
	);

process (state)
 begin
	case state is
		when 0 =>
			T0 <= q3;
			T1 <= q2;
			T2 <= q1;
			wren0 <= '1';
			wren1 <= '0';
			wren2 <= '0';
			wren3 <= '0';
		when 1 =>
			T0 <= q0;
			T1 <= q3;
			T2 <= q2;
			wren0 <= '0';
			wren1 <= '1';
			wren2 <= '0';
			wren3 <= '0';
		when 2 =>
			T0 <= q1;
			T1 <= q0;
			T2 <= q3;	
			wren0 <= '0';
			wren1 <= '0';
			wren2 <= '1';
			wren3 <= '0';
		when 3 =>
			T0 <= q2;
			T1 <= q1;
			T2 <= q0;
			wren0 <= '0';
			wren1 <= '0';
			wren2 <= '0';
			wren3 <= '1';
	end case;
end process;

	process (clk, reset)
	begin
		if (reset = '0') then
			state <= 0;
		elsif (rising_edge(clk)) then
			if (unsigned(x) = X_MAX) then
				if (state < 3) then
					state <= state + 1;
				else
					state <= 0;
				end if;
			end if;			
		end if;
	end process;
	
end rtl;