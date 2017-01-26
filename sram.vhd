-- Implements a static random access memory block
-- that can be used to store and retrieve data.
-- Data accesses are synchronized to the clock.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram is
    generic (ADDR_WIDTH : integer := 16;
             DATA_WIDTH : integer := 8);
    port (clock : in std_logic;
          read_en : in std_logic;
          write_en : in std_logic;
          address : in std_logic_vector(ADDR_WIDTH-1 downto 0);
          data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
          data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
end sram;

architecture arch of sram is

    type sram_type is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal memory : sram_type;

begin

    sram_process : process (clock)
        variable addr : integer;
    begin
        if (rising_edge(clock)) then
            addr := to_integer(unsigned(address));

            data_out <= (others => 'Z'); -- default read state is high impedance
            if (read_en = '1') then
                data_out <= memory(addr);
            end if;

            if (write_en = '1') then
                memory(addr) <= data_in;
            end if;
        end if;
    end process;

end architecture;
