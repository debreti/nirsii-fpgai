library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HOUGH_Array is
	generic
	(
		X_MAX : natural := 1023;
		Y_MAX : natural := 767
	);
	
port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		edge_info: in std_logic;
		HS: in std_logic;
		VS: in std_logic;
		o_Hough : out std_logic_vector(9 downto 0)	
	
	);

end entity;

architecture rtl of HOUGH_Array is

type myrho is array (0 TO 179) OF std_logic_vector(9 downto 0);
signal rho, r_rho, rr_rho, data_sig, q_sig, raddr_sig, waddr_sig: myrho;
type mywren is array (0 TO 179) OF std_logic;
signal wren: mywren;
type myarr is array (0 TO 179) OF std_logic_vector(11 downto 0);
CONSTANT sinarr : myarr := (x"000", x"023", x"047", x"06B", x"08E", x"0B2", x"0D6", x"0F9", x"11D", x"140", x"163", x"186", x"1A9", x"1CC", x"1EF", x"212", x"234", x"256", x"278", x"29A", x"2BC", x"2DD", x"2FF", x"320", x"340", x"361", x"381", x"3A1", x"3C1", x"3E0", x"3FF", x"41E", x"43D", x"45B", x"479", x"496", x"4B3", x"4D0", x"4EC", x"508", x"524", x"53F", x"55A", x"574", x"58E", x"5A8", x"5C1", x"5D9", x"5F1", x"609", x"620", x"637", x"64D", x"663", x"678", x"68D", x"6A1", x"6B5", x"6C8", x"6DB", x"6ED", x"6FF", x"710", x"720", x"730", x"740", x"74E", x"75D", x"76A", x"777", x"784", x"790", x"79B", x"7A6", x"7B0", x"7BA", x"7C3", x"7CB", x"7D3", x"7DA", x"7E0", x"7E6", x"7EC", x"7F0", x"7F4", x"7F8", x"7FB", x"7FD", x"7FE", x"7FF", x"800", x"7FF", x"7FE", x"7FD", x"7FB", x"7F8", x"7F4", x"7F0", x"7EC", x"7E6", x"7E0", x"7DA", x"7D3", x"7CB", x"7C3", x"7BA", x"7B0", x"7A6", x"79B", x"790", x"784", x"777", x"76A", x"75D", x"74E", x"740", x"730", x"720", x"710", x"6FF", x"6ED", x"6DB", x"6C8", x"6B5", x"6A1", x"68D", x"678", x"663", x"64D", x"637", x"620", x"609", x"5F1", x"5D9", x"5C1", x"5A8", x"58E", x"574", x"55A", x"53F", x"524", x"508", x"4EC", x"4D0", x"4B3", x"496", x"479", x"45B", x"43D", x"41E", x"3FF", x"3E0", x"3C1", x"3A1", x"381", x"361", x"340", x"320", x"2FF", x"2DD", x"2BC", x"29A", x"278", x"256", x"234", x"212", x"1EF", x"1CC", x"1A9", x"186", x"163", x"140", x"11D", x"0F9", x"0D6", x"0B2", x"08E", x"06B", x"047", x"023");
CONSTANT cosarr : myarr := (x"FFF", x"FFE", x"FFD", x"FFC", x"FFA", x"FF7", x"FF3", x"FEF", x"FEB", x"FE5", x"FDF", x"FD9", x"FD2", x"FCA", x"FC2", x"FB9", x"FAF", x"FA5", x"F9A", x"F8F", x"F83", x"F76", x"F69", x"F5C", x"F4D", x"F3F", x"F2F", x"F1F", x"F0F", x"EFE", x"EEC", x"EDA", x"EC7", x"EB4", x"EA0", x"E8C", x"E77", x"E62", x"E4C", x"E36", x"E1F", x"E08", x"DF0", x"DD8", x"DC0", x"DA7", x"D8D", x"D73", x"D59", x"D3E", x"D23", x"D07", x"CEB", x"CCF", x"CB2", x"C95", x"C78", x"C5A", x"C3C", x"C1D", x"BFE", x"BDF", x"BC0", x"BA0", x"B80", x"B60", x"B3F", x"B1F", x"AFE", x"ADC", x"ABB", x"A99", x"A77", x"A55", x"A33", x"A11", x"9EE", x"9CB", x"9A8", x"985", x"962", x"93F", x"91C", x"8F8", x"8D5", x"8B1", x"88D", x"86A", x"846", x"822", x"7FF", x"7DC", x"7B8", x"794", x"771", x"74D", x"729", x"706", x"6E2", x"6BF", x"69C", x"679", x"656", x"633", x"610", x"5ED", x"5CB", x"5A9", x"587", x"565", x"543", x"522", x"500", x"4DF", x"4BF", x"49E", x"47E", x"45E", x"43E", x"41F", x"400", x"3E1", x"3C2", x"3A4", x"386", x"369", x"34C", x"32F", x"313", x"2F7", x"2DB", x"2C0", x"2A5", x"28B", x"271", x"257", x"23E", x"226", x"20E", x"1F6", x"1DF", x"1C8", x"1B2", x"19C", x"187", x"172", x"15E", x"14A", x"137", x"124", x"112", x"100", x"0EF", x"0DF", x"0CF", x"0BF", x"0B1", x"0A2", x"095", x"088", x"07B", x"06F", x"064", x"059", x"04F", x"045", x"03C", x"034", x"02C", x"025", x"01F", x"019", x"013", x"00F", x"00B", x"007", x"004", x"002", x"001", x"000");

--signal wren : std_logic;

signal r_edge_info, rr_edge_info: std_logic;
signal rx,ry,rrx,rry: std_logic_vector(10 downto 0);
signal x_count: integer range 0 to X_MAX := 0;
signal y_count: integer range 0 to Y_MAX := 0;
signal rHS : std_logic;

component rho_count is
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
end component;

component hough_ram IS
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		rdaddress: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wraddress: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0)
	);
END component;

begin
	
	GEN_block: 
		for I in 0 to 179 generate
			rho_count_inst: rho_count
			generic map
			(cos => to_integer(unsigned(cosarr(I))),
			sin => to_integer(unsigned(sinarr(I)))
			)
		port map
			  (clk		 => clk,
				reset		 => reset,
				edge_info => '0',
				x_std_vec => std_logic_vector(to_unsigned(x_count,10)),
				y_std_vec => std_logic_vector(to_unsigned(y_count,10)),
				--cos_const => cosarr(I),
				--sin_const => sinarr(I),
				rho		 => rho(I)
				);
		
			hough_ram_inst : hough_ram PORT MAP (
				aclr	 	 => not VS,
				clock	 	 => clk,
				data	 	 => data_sig(I), 
				rdaddress => raddr_sig(I),
				wraddress => waddr_sig(I), 
				wren		 => wren(I),
				q			 => q_sig(I)    
			);
	end generate GEN_block;	

	process (clk, reset)
	begin
	
		for I in 0 to 179 loop
			if (y_count < 588) then -- esli menshe -> stroim
					if (to_integer(unsigned(q_sig(I))) < 1023) then
						data_sig(I)	<= std_logic_vector(to_unsigned(to_integer(unsigned(q_sig(I))) + 1, 10));
					else
						data_sig(I) <= (others => '1');
					end if; -- to avoid inferred latches
					raddr_sig(I) <= rho(I);
					waddr_sig(I) <= rr_rho(I); --dobavila
					if (x_count>5 AND y_count>5) then
						wren(I) <= edge_info;
					else
						wren(I) <= '0';
					end if;
			else							-- esli bolshe -> vivodim i obnulyaem
				raddr_sig(I) <= std_logic_vector(to_unsigned(x_count,10));
				waddr_sig(I) <= std_logic_vector(to_unsigned(x_count-2,10));--dobavila
				data_sig(I) <= (others => '0');
				if (I = (y_count-588)) then
					wren(I) <= '1';
				else
					wren(I) <= '0';
				end if;
			end if;
		end loop;
		
		
		if (reset = '0' OR VS ='0') then
			r_rho <= (OTHERS => (OTHERS => '0'));
			rr_rho <= (OTHERS => (OTHERS => '0'));
			--waddr_sig <= rr_rho; 
			--rrr_rho <= (OTHERS => (OTHERS => '0'));
			
			--rr_edge_info <= '0';
			--r_edge_info <= '0';
			rHS <= '0';
			x_count <= 0;
			y_count <=0;

		elsif (rising_edge(clk)) then
			--waddr_sig <= rr_rho; 
			rr_rho <= r_rho;
			r_rho  <= rho;
			--rr_edge_info <= r_edge_info;
			--r_edge_info <= edge_info;
			
			rHS <= HS;
			
			if (HS = '0') then
				x_count <= 0;
			else
				x_count <= x_count +1;
			end if;
			
			if (rHS = '0' AND HS = '1' ) then
				y_count <= y_count+1;
			end if;
			
			if (y_count >= 588) then
				o_Hough <= q_sig(y_count-588);
			else
				o_Hough <= (others=>'0');
			end if;
		end if;
	end process;
end rtl;