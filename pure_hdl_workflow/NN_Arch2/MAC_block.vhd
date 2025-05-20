library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.NN_package.all;

entity MAC_block is
	port
	(
		clk         : in  std_logic;
		rst         : in  std_logic;
		WE          : in  std_logic;
		weight_load : in  std_logic;
		neuron_val  : in  std_logic_vector((WEIGHT_WIDTH - 1) downto 0);
		bias_val    : in  std_logic_vector((BIAS_WIDTH - 1) downto 0);
		weight_val  : in  std_logic_vector((WEIGHT_WIDTH - 1) downto 0);
		acc_out     : out std_logic_vector((ACC_WIDTH - 1) downto 0);
		isBlank     : out std_logic
	);
end entity;

architecture FirstMac of MAC_block is
	signal mul_sig : signed((2 * WEIGHT_WIDTH - 1) downto 0);
	signal sum_sig : signed((ACC_WIDTH - 1) downto 0);
	signal acc     : signed((ACC_WIDTH - 1) downto 0);
begin
	isBlank <= '0';
	mul_sig <= signed(weight_val) * signed(neuron_val);
	sum_sig <= signed(acc_out) + mul_sig;
	acc_out <= std_logic_vector(acc);
	-- Computation
	process(clk,rst)
	begin
		if(rst = '1') then
			acc <= (others => '0');
		elsif (rising_edge(clk)) then
			if (WE = '1') then
				-- Bias/weight load
				if (weight_load = '1') then
					acc <= sum_sig;
				else
					acc <= resize(signed(bias_val), acc'length);
				end if;
			end if;
		end if;
	end process;
end FirstMac;

architecture SubMac of MAC_block is
	signal nz_flag : std_logic;
	signal mul_sig : signed((2 * WEIGHT_WIDTH - 1) downto 0);
	signal sum_sig : signed((ACC_WIDTH - 1) downto 0);
	signal acc     : signed((ACC_WIDTH - 1) downto 0);
begin
	mul_sig <= signed(weight_val) * signed(neuron_val);
	sum_sig <= signed(acc_out) + mul_sig;
	nz_flag <= to_std_logic(to_integer(unsigned(weight_val)) /= 0);
	acc_out <= std_logic_vector(acc);
	-- Computation
	process(clk,rst)
	begin
		if(rst = '1') then
			isBlank <= '0';
			acc     <= (others => '0');
		elsif (rising_edge(clk)) then
			if (WE = '1') then
				-- Bias/weight load
				if (weight_load = '1') then
					isBlank <= nz_flag OR isBlank;
					acc     <= sum_sig;
				else
					isBlank <= '0';
					acc     <= resize(signed(bias_val), acc'length);
				end if;
			end if;
		end if;
	end process;
end SubMac;
