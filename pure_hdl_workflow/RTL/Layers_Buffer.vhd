library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.NPU_Package.all;

entity Layers_Buffer is
    generic (
        INST_INX : natural := 0
    );
    port (
        clk               : in     std_logic                                                       := '0';
        rst               : in     std_logic                                                       := '0';
        ext_we            : in     std_logic                                                       := '0';
        we                : in     std_logic                                                       := '0';
        re                : in     std_logic                                                       := '0';
        set_layer_borders : in     std_logic                                                       := '0';
        jmp_layer_start   : in     std_logic                                                       := '0';
        neuron_data       : in     std_logic_vector(NN_CONFIG(INST_INX).Neuron_Width - 1 downto 0) := (others => '0');
        flayer_data       : in     std_logic_vector(NN_CONFIG(INST_INX).Neuron_Width - 1 downto 0) := (others => '0');
        out_data          : out    std_logic_vector(NN_CONFIG(INST_INX).Neuron_Width - 1 downto 0);
        layer_end         : buffer std_logic
    );
end entity;

architecture rtl of Layers_Buffer is
    /* ┏━━━━━━━━━━━━━━━━━┓ */
    -- ┃    CONSTANTS    ┃ --
    /* ┗━━━━━━━━━━━━━━━━━┛ */
    constant NEURON_WIDTH : natural := NN_CONFIG(INST_INX).Neuron_Width;
    constant RB_SIZE      : natural := RingBufSize(INST_INX);
    /* ┏━━━━━━━━━━━━━━┓ */
    -- ┃    ARRAYS    ┃ --
    /* ┗━━━━━━━━━━━━━━┛ */
    type ram_array is array (0 to RB_SIZE - 1) of std_logic_vector((NEURON_WIDTH - 1) downto 0);
    signal ram_data : ram_array := (others => (others => '0'));
    /* ┏━━━━━━━━━━━━━━━┓ */
    -- ┃    SIGNALS    ┃ --
    /* ┗━━━━━━━━━━━━━━━┛ */
    signal last_read      : std_logic                                        := '0';
    signal r_ptr_max      : std_logic                                        := '0';
    signal w_ptr_max      : std_logic                                        := '0';
    signal ram_write_data : std_logic_vector((NEURON_WIDTH - 1) downto 0)    := (others => '0');
    signal r_ptr_vector   : std_logic_vector(Log2Ceil(RB_SIZE) - 1 downto 0) := (others => '0');
    signal w_ptr_vector   : std_logic_vector(Log2Ceil(RB_SIZE) - 1 downto 0) := (others => '0');
    signal lstr_ptr       : natural range 0 to (RB_SIZE - 1)                 := 0; -- Layer start ptr - point at first value of stored layer
    signal w_ptr          : natural range 0 to (RB_SIZE - 1)                 := 0; -- Write(head) ptr for writing op
    signal lend_ptr       : natural range 0 to (RB_SIZE - 1)                 := 0; -- Layer end ptr - points to last value of stored layer
    signal r_ptr          : natural range 0 to (RB_SIZE - 1)                 := 0; -- Read(tail) ptr for reading
begin

    Read_Ptr_Counter : entity work.Counter_FlgQPl
        generic map (
            CNT_MAX => RB_SIZE
        )
        port map (
            clk      => clk,
            aclr     => rst,
            en       => re,
            load     => jmp_layer_start, -- Set r_ptr to layer start
            in_data  => std_logic_vector(to_unsigned(lstr_ptr, Log2Ceil(RB_SIZE))),
            max      => r_ptr_max,
            out_data => r_ptr_vector
        );
    r_ptr <= to_integer(unsigned(r_ptr_vector));

    Write_Ptr_Counter : entity work.Counter_FlgQ
        generic map (
            CNT_MAX => RB_SIZE
        )
        port map (
            clk      => clk,
            rst      => rst,
            en       => we or ext_we,
            max      => w_ptr_max,
            out_data => w_ptr_vector
        );
    w_ptr <= to_integer(unsigned(w_ptr_vector));

    last_read      <= '1'         when (r_ptr = lend_ptr) else '0';
    ram_write_data <= flayer_data when ext_we else neuron_data;
    Seq_Logic : process(clk)
    begin
        if rising_edge(clk) then
            -- Layer end flag register
            layer_end <= re and last_read;
            -- Data out register
            out_data <= ram_data(r_ptr);
            -- Push new data
            if(we or ext_we) then
                ram_data(w_ptr) <= ram_write_data;
            end if;
            -- Save w_ptr to layer end and r_ptr to layer start
            if(set_layer_borders) then
                lend_ptr <= w_ptr;
                lstr_ptr <= r_ptr;
            end if;
        end if;
    end process;

end architecture;