library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_processor_tb is
end pixel_processor_tb;

architecture arch of pixel_processor_tb is

    component pixel_processor is
        port (clock : in std_logic; -- clock signal
              reset : in std_logic; -- asynchronous reset
              enable : in std_logic; -- enables the processor
              pixel_data : in std_logic_vector(7 downto 0); -- input pixel
              pixel_operand : in std_logic_vector(7 downto 0); -- input pixel operand
              maxval : in std_logic_vector(7 downto 0); -- maximum pixel value
              operation : in std_logic_vector(3 downto 0); -- operation to perform
              data_out : out std_logic_vector(7 downto 0); -- output pixel
              data_ready : out std_logic; -- flags that the data is ready
              data_valid : out std_logic); -- flags that the output is a valid pixel value
    end component;

    constant HIGH : std_logic := '1';
    constant LOW : std_logic := '0';
    constant clock_period : time := 1 ns;

    signal clock : std_logic;
    signal reset : std_logic;
    signal enable : std_logic;
    signal pixel_data : std_logic_vector(7 downto 0);
    signal pixel_operand : std_logic_vector(7 downto 0);
    signal maxval : std_logic_vector(7 downto 0);
    signal operation : std_logic_vector(3 downto 0);
    signal data_out : std_logic_vector(7 downto 0);
    signal data_ready : std_logic;
    signal data_valid : std_logic;

begin

    processor : pixel_processor
    port map (clock => clock,
              reset => LOW,
              enable => HIGH,
              pixel_data => pixel_data,
              pixel_operand => pixel_operand,
              maxval => maxval,
              operation => operation,
              data_out => data_out,
              data_ready => data_ready,
              data_valid => data_valid);

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process;

    test_process : process
    begin

        report "Testing pixel operations...";

        maxval <= x"0F";

        pixel_data <= x"00";
        pixel_operand <= x"0A";
        operation <= x"0";
        wait for clock_period;
        assert (data_out = x"0A") report "output should be 10 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"02";
        pixel_operand <= x"01";
        operation <= x"1";
        wait for clock_period;
        assert (data_out = x"03") report "output should be 3 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"01";
        pixel_operand <= x"0F";
        operation <= x"1";
        wait for clock_period;
        assert (data_valid = '0') report "data should be invalid but was valid" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"02";
        operation <= x"2";
        wait for clock_period;
        assert (data_out = x"08") report "output should be 8 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"02";
        pixel_operand <= x"03";
        operation <= x"2";
        wait for clock_period;
        assert (data_valid = '0') report "data should be invalid but was valid" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"02";
        operation <= x"3";
        wait for clock_period;
        assert (data_out = x"02") report "output should be 2 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"02";
        operation <= x"4";
        wait for clock_period;
        assert (data_out = x"0A") report "output should be 10 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"02";
        operation <= x"5";
        wait for clock_period;
        assert (data_out = x"08") report "output should be 8 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"00";
        operation <= x"6";
        wait for clock_period;
        assert (data_out = x"05") report "output should be 5 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"08";
        operation <= x"7";
        wait for clock_period;
        assert (data_out = x"0F") report "output should be 15 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"0B";
        operation <= x"7";
        wait for clock_period;
        assert (data_out = x"0A") report "output should be 10 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"0A";
        pixel_operand <= x"04";
        operation <= x"8";
        wait for clock_period;
        assert (data_out = x"06") report "output should be 6 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        pixel_data <= x"04";
        pixel_operand <= x"0A";
        operation <= x"8";
        wait for clock_period;
        assert (data_out = x"06") report "output should be 6 but was " & integer'image(to_integer(unsigned(data_out))) severity error;
        assert (data_valid = '1') report "data should be valid but was not" severity error;

        report "Done";

        wait;
    end process;

end architecture;