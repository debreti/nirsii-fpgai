library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity Mac_Blk is
	generic (
		WEIGHT_WIDTH : natural := 8;
		NEURON_WIDTH : natural := 8;
		ACC_WIDTH    : natural := 32;
		BIAS_WIDTH   : natural := 32
	);
	port
	(
		clk         : in  std_logic                                     := '0';
		mul_en      : in  std_logic                                     := '0';
		acc_en      : in  std_logic                                     := '0';
		acc_sload   : in  std_logic                                     := '0';
		neuron_data : in  std_logic_vector((NEURON_WIDTH - 1) downto 0) := (others => '0');
		bias_data   : in  std_logic_vector((BIAS_WIDTH - 1) downto 0)   := (others => '0');
		weight_data : in  std_logic_vector((WEIGHT_WIDTH - 1) downto 0) := (others => '0');
		out_data    : out std_logic_vector((ACC_WIDTH - 1) downto 0)    := (others => '0');
		nonBlank    : out std_logic                                     := '0'
	);
end entity;

architecture rtl of Mac_Blk is
	/* ┏━━━━━━━━━━━━━━━┓ */
	-- ┃    SIGNALS    ┃ --
	/* ┗━━━━━━━━━━━━━━━┛ */
	signal nz_flag : std_logic                                            := '0';
	signal acc     : signed((ACC_WIDTH - 1) downto 0)                     := (others => '0');
	signal mul_reg : signed(((NEURON_WIDTH + WEIGHT_WIDTH) - 1) downto 0) := (others => '0');
	signal w_reg   : std_logic_vector((WEIGHT_WIDTH - 1) downto 0)        := (others => '0');
	signal n_reg   : std_logic_vector((NEURON_WIDTH - 1) downto 0)        := (others => '0');
begin

	nz_flag  <= OR_REDUCE(w_reg); -- Non-Zero check
	out_data <= std_logic_vector(acc);

	Seq_Logic : process(clk)
	begin
		if(rising_edge(clk)) then
			-- Mul operation
			w_reg <= weight_data;
			n_reg <= neuron_data;
			-- Multiplication
			if(mul_en) then
				mul_reg <= signed(w_reg) * signed(n_reg);
			end if;
			-- Acc sync load / Acc operation 
			if(acc_sload or acc_en) then
				if(acc_sload) then
					acc <= resize(signed(bias_data), acc'length);
				else
					acc <= acc + mul_reg;
				end if;
			end if;
			-- SR_Latch Blank reset / Blank detection 
			if(acc_sload or (mul_en and (not nonBlank))) then
				if(acc_sload) then
					nonBlank <= '0';
				else
					nonBlank <= nz_flag;
				end if;
			end if;
		end if;
	end process;

end architecture;
