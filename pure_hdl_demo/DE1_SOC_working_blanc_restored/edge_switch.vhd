library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity edge_switch is

		port 
	(
		clk		: in std_logic;
		reset		: in std_logic;
		switches	: in std_logic_vector(2 downto 0);
		
		R_true	: in std_logic_vector(7 downto 0);	
		G_true	: in std_logic_vector(7 downto 0);
		B_true	: in std_logic_vector(7 downto 0);
		
		R_edge	: in std_logic_vector(7 downto 0);	
		G_edge	: in std_logic_vector(7 downto 0);
		B_edge	: in std_logic_vector(7 downto 0);
		
		RGB_Y		: in std_logic_vector(7 downto 0);
		RGB_GAUSS: in std_logic_vector(7 downto 0);
		R_GRAD: in std_logic_vector(7 downto 0);
		G_GRAD: in std_logic_vector(7 downto 0);
		
		
		R_VGA	: out std_logic_vector(9 downto 0);	
		G_VGA	: out std_logic_vector(9 downto 0);
		B_VGA	: out std_logic_vector(9 downto 0)
		
	);

end entity;

architecture rtl of edge_switch is


begin
			
	process (clk, reset)
	
	begin
	
	if (reset = '0') then
		R_VGA <= (OTHERS => '0');
		G_VGA <= (OTHERS => '0');
		B_VGA <= (OTHERS => '0');
			
		elsif (rising_edge(clk)) then
		
		
		case switches is
		  when "000" =>  
				R_VGA <= "00" & R_true  ;
				G_VGA <= "00" & G_true  ;
				B_VGA <= "00" & B_true  ;
		  when "001" =>  				
				R_VGA <= "00" & R_edge  ;
				G_VGA <= "00" & G_edge  ;
				B_VGA <= "00" & B_edge  ;
		  when "010" =>   
		  		R_VGA <= "00" & RGB_Y  ;
				G_VGA <= "00" & RGB_Y  ;
				B_VGA <= "00" & RGB_Y  ;
		  when "011" =>   
				R_VGA <= "00" & RGB_GAUSS  ;
				G_VGA <= "00" & RGB_GAUSS  ;
				B_VGA <= "00" & RGB_GAUSS  ;
		  when "100" =>  
		  		R_VGA <= "00" & R_GRAD  ;
				G_VGA <= "00" & G_GRAD  ;
				B_VGA <= (OTHERS => '0')  ;
		  when others => 
				R_VGA <= "00" & R_true  ;
				G_VGA <= "00" & G_true  ;
				B_VGA <= "00" & B_true  ;
		end case;
						
--			if (switches(1) = '0') then
--				R_VGA <= "00" & R_true  ;
--				G_VGA <= "00" & G_true  ;
--				B_VGA <= "00" & B_true  ;
--			else
--				R_VGA <= "00" & R_edge ;
--				G_VGA <= "00" & G_edge ;
--				B_VGA <= "00" & B_edge ;
--			end if;
				
		end if;
	end process;

end rtl;
