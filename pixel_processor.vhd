-- Implements a basic arithmetic unit synchronized to the clock for
-- pixel processing. The supported operations are:
-- 0: set output to pixel_operand
-- 1: add pixel_operand to pixel_data, capped at maxval
-- 2: subtract pixel_operand from pixel_data, capped at 0
-- 3: perform a bitwise and on pixel_data and pixel_operand
-- 4: perform a bitwise or on pixel_data and pixel_operand
-- 5: perform a bitwise xor on pixel_data and pixel_operand
-- 6: set output to maxval - pixel_data
-- 7: set output to maxval if pixel_data > pixel_operand, otherwise output pixel_data
-- 8: set output to abs(pixel_data - pixel_operand)
-- 9: set output to (pixel_data - pixel_operand + maxval) / 2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_processor is
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
end pixel_processor;

architecture arch of pixel_processor is

    signal data_out_internal : std_logic_vector(7 downto 0);

begin
    
    data_ready <= enable;
    data_valid <= '1'; -- not used

    output_process : process (clock, reset)
    begin
        if (reset = '1') then
            data_out <= (others => '0');
        elsif (rising_edge(clock)) then
            if (enable = '1') then
                data_out <= data_out_internal;
            end if;
        end if;
    end process;

    operation_process : process (operation, pixel_data, pixel_operand, maxval)
        variable data_out_next : std_logic_vector(8 downto 0);
    begin
        case operation is
        when "0000" =>
            data_out_internal <= pixel_operand;
        when "0001" =>
            data_out_next := std_logic_vector(unsigned("0" & pixel_data) + unsigned(pixel_operand));
            if (data_out_next > "0" & maxval) then
                data_out_internal <= maxval; -- cap addition at maxval
            else
                data_out_internal <= data_out_next(7 downto 0);
            end if;
        when "0010" =>
            data_out_next := std_logic_vector(unsigned("0" & pixel_data) - unsigned(pixel_operand));
            if (data_out_next > "0" & maxval) then
                data_out_internal <= (others => '0'); -- cap subtraction at 0
            else
                data_out_internal <= data_out_next(7 downto 0);
            end if;
        when "0011" =>
            data_out_internal <= pixel_data and pixel_operand;
        when "0100" =>
            data_out_internal <= pixel_data or pixel_operand;
        when "0101" =>
            data_out_internal <= pixel_data xor pixel_operand;
        when "0110" =>
            data_out_internal <= std_logic_vector(unsigned(maxval) - unsigned(pixel_data));
        when "0111" =>
            if (pixel_data > pixel_operand) then
                data_out_internal <= maxval;
            else
                data_out_internal <= pixel_data;
            end if;
        when "1000" =>
            if (pixel_data > pixel_operand) then
                data_out_internal <= std_logic_vector(unsigned(pixel_data) - unsigned(pixel_operand));
            else
                data_out_internal <= std_logic_vector(unsigned(pixel_operand) - unsigned(pixel_data));
            end if;
        when "1001" =>
            data_out_next := std_logic_vector(unsigned("0" & pixel_data) - unsigned(pixel_operand) + unsigned(maxval));
            data_out_internal <= data_out_next(8 downto 1);
        when others =>
            data_out_internal <= (others => '0');
        end case;
    end process;

end architecture;
