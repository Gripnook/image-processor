library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram_tb is
end sram_tb;

architecture behaviour of sram_tb is

    component sram is
        generic (ADDR_WIDTH : integer := 16;
                 DATA_WIDTH : integer := 8);
        port (clock : in std_logic;
              read_en : in std_logic;
              write_en : in std_logic;
              address : in std_logic_vector(ADDR_WIDTH-1 downto 0);
              data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
              data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
    end component;

    constant clock_period : time := 1 ns;

    signal clock : std_logic;
    signal read_en, write_en : std_logic;
    signal address : std_logic_vector(15 downto 0);
    signal data_in, data_out : std_logic_vector(7 downto 0);

begin

    memory_block : sram
    port map (clock, read_en, write_en, address, data_in, data_out);

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process;

    test_process : process
    begin

        report "Testing sequential address read/write...";
        report "mem[0] = 1; mem[1] = 2; mem[3] = 3; assert mem[0] = 1; assert mem[1] = 2; assert mem[2] = 3;";

        read_en <= '0';
        write_en <= '1';

        address <= x"0000";
        data_in <= x"01";
        wait for clock_period;
        address <= x"0001";
        data_in <= x"02";
        wait for clock_period;
        address <= x"0002";
        data_in <= x"03";
        wait for clock_period;

        read_en <= '1';
        write_en <= '0';

        address <= x"0000";
        wait for clock_period;
        assert (data_out = x"01") report "mem[0] should be 1 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        address <= x"0001";
        wait for clock_period;
        assert (data_out = x"02") report "mem[1] should be 2 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        address <= x"0002";
        wait for clock_period;
        assert (data_out = x"03") report "mem[2] should be 3 but was " & integer'image(to_integer(unsigned(data_out))) severity error;

        report "Done";
        report "Testing random address read/write...";
        report "mem[3855] = 255; mem[1] = 15; assert mem[1] = 15; assert mem[3855] = 255;";

        read_en <= '0';
        write_en <= '1';

        address <= x"0F0F";
        data_in <= x"FF";
        wait for clock_period;
        address <= x"0001";
        data_in <= x"0F";
        wait for clock_period;

        read_en <= '1';
        write_en <= '0';

        address <= x"0001";
        wait for clock_period;
        assert (data_out = x"0F") report "mem[1] should be 15 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        address <= x"0F0F";
        wait for clock_period;
        assert (data_out = x"FF") report "mem[3855] should be 255 but was " & integer'image(to_integer(unsigned(data_out))) severity error;

        report "Done";
        report "Testing multi-cycle read/write...";
        report "mem[15] = 255; wait; wait; mem[3] = 15; assert mem[15] = 255; wait; assert mem[3] = 15;";

        read_en <= '0';
        write_en <= '1';

        address <= x"000F";
        data_in <= x"FF";
        wait for clock_period;

        read_en <= '0';
        write_en <= '0';

        wait for clock_period;
        wait for clock_period;

        read_en <= '0';
        write_en <= '1';

        address <= x"0003";
        data_in <= x"0F";
        wait for clock_period;

        read_en <= '1';
        write_en <= '0';

        address <= x"000F";
        wait for clock_period;
        assert (data_out = x"FF") report "mem[15] should be 255 but was " & integer'image(to_integer(unsigned(data_out))) severity error;

        read_en <= '0';
        write_en <= '0';

        wait for clock_period;

        read_en <= '1';
        write_en <= '0';

        address <= x"0003";
        wait for clock_period;
        assert (data_out = x"0F") report "mem[3] should be 15 but was " & integer'image(to_integer(unsigned(data_out))) severity error;

        report "Done";
        report "Testing overwrites...";
        report "mem[2] = 10; mem[2] = 15; wait; assert mem[2] = 15;";

        read_en <= '0';
        write_en <= '1';

        address <= x"0002";
        data_in <= x"0A";
        wait for clock_period;
        address <= x"0002";
        data_in <= x"0F";
        wait for clock_period;

        read_en <= '0';
        write_en <= '0';

        wait for clock_period;

        read_en <= '1';
        write_en <= '0';

        address <= x"0002";
        wait for clock_period;
        assert (data_out = x"0F") report "mem[2] should be 15 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        
        report "Done";
        report "Testing write protection while write is disabled...";
        report "mem[0] = 15; set data_in = 0; wait; assert mem[0] = 15;";

        read_en <= '0';
        write_en <= '1';

        address <= x"0000";
        data_in <= x"0F";
        wait for clock_period;

        read_en <= '0';
        write_en <= '0';

        address <= x"0000";
        data_in <= x"00";
        wait for clock_period;

        read_en <= '1';
        write_en <= '0';

        address <= x"0000";
        wait for clock_period;
        assert (data_out = x"0F") report "mem[0] should be 15 but was " & integer'image(to_integer(unsigned(data_out))) severity error;

        report "Done";

        wait;
    end process;

end architecture;
