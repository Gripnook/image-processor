library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
use work.image_io_error.all;

entity image_edge_detector_tb is
end image_edge_detector_tb;

architecture arch of image_edge_detector_tb is
    
    component image_processor is
        port (clock : in std_logic; -- clock signal
              reset : in std_logic; -- asynchronous reset
              start : in std_logic; -- starts processing when flags is set
              reg_in_0 : in std_logic_vector(1 downto 0); -- first input register (sram0/sram1/sram2)
              reg_in_1 : in std_logic_vector(1 downto 0); -- second input register (sram0/sram1/sram2/global_operand)
              reg_out : in std_logic_vector(1 downto 0); -- output register (sram0/sram1/sram2)
              global_operand : in std_logic_vector(7 downto 0); -- global operand to use in operations with every pixel of an image
              address_increment : in std_logic_vector(7 downto 0); -- perform shifted operations
              operation : in std_logic_vector(3 downto 0); -- operation to perform
              data_in_load : in std_logic_vector(7 downto 0); -- data being read from file
              read_en_load : in std_logic; -- indicates that there is still data to be read from file
              write_en_save : out std_logic; -- flags that a byte can be written to file
              data_out_save : out std_logic_vector(7 downto 0); -- byte that can be written to file
              done : out std_logic; -- finished processing
              error_code : out std_logic_vector(3 downto 0)); -- errors encountered while processing
    end component;

    constant clock_period : time := 1 ns;

    constant ASCII_LF : std_logic_vector(7 downto 0) := x"0A";

    signal clock : std_logic;
    signal reset : std_logic;
    signal start : std_logic;
    signal reg_in_0 : std_logic_vector(1 downto 0);
    signal reg_in_1 : std_logic_vector(1 downto 0);
    signal reg_out : std_logic_vector(1 downto 0);
    signal global_operand : std_logic_vector(7 downto 0);
    signal address_increment : std_logic_vector(7 downto 0);
    signal operation : std_logic_vector(3 downto 0);
    signal data_in_load : std_logic_vector(7 downto 0);
    signal read_en_load : std_logic;
    signal write_en_save : std_logic;
    signal data_out_save : std_logic_vector(7 downto 0);
    signal done : std_logic;
    signal error_code : std_logic_vector(3 downto 0);

begin

    processor : image_processor
    port map (clock => clock,
              reset => reset,
              start => start,
              reg_in_0 => reg_in_0,
              reg_in_1 => reg_in_1,
              reg_out => reg_out,
              global_operand => global_operand,
              address_increment => address_increment,
              operation => operation,
              data_in_load => data_in_load,
              read_en_load => read_en_load,
              write_en_save => write_en_save,
              data_out_save => data_out_save,
              done => done,
              error_code => error_code);

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process;

    test_process : process
        file img_file : text;
        variable img_line : line;
        variable img_byte : character;
        variable read_byte : boolean;
    begin

        reset <= '1';
        wait for clock_period;
        reset <= '0';

        -- load file 1 into reg0
        file_open(img_file, "people106.pgm", read_mode);
        start <= '1';
        reg_in_0 <= "00";
        reg_in_1 <= "00";
        reg_out <= "00";
        global_operand <= (others => '0');
        address_increment <= (others => '0');
        operation <= "1010";
        read_en_load <= '1';
        wait for clock_period;

        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in_load <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in_load <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        read_en_load <= '0';
        file_close(img_file);
        wait until (done = '1');
        wait for clock_period/2; -- set data on falling edge
        start <= '0';
        wait for clock_period;
        wait for clock_period;
        
        -- load file 2 into reg1
        file_open(img_file, "background.pgm", read_mode);
        start <= '1';
        reg_in_0 <= "00";
        reg_in_1 <= "00";
        reg_out <= "01";
        global_operand <= (others => '0');
        address_increment <= (others => '0');
        operation <= "1010";
        read_en_load <= '1';
        wait for clock_period;

        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in_load <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in_load <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        read_en_load <= '0';
        file_close(img_file);
        wait until (done = '1');
        wait for clock_period/2; -- set data on falling edge
        start <= '0';
        wait for clock_period;
        wait for clock_period;

        -- reg0 <- reg0 ndiff reg1
        start <= '1';
        reg_in_0 <= "00";
        reg_in_1 <= "01";
        reg_out <= "00";
        global_operand <= (others => '0');
        address_increment <= (others => '0');
        operation <= "1001";
        wait until (done = '1');
        wait for clock_period/2; -- set data on falling edge
        start <= '0';
        wait for clock_period;
        wait for clock_period;

        -- reg1 <- reg0 shifted by 1
        start <= '1';
        reg_in_0 <= "00";
        reg_in_1 <= "00";
        reg_out <= "01";
        global_operand <= (others => '0');
        address_increment <= x"01";
        operation <= "0000";
        wait until (done = '1');
        wait for clock_period/2; -- set data on falling edge
        start <= '0';
        wait for clock_period;
        wait for clock_period;

        -- reg2 <- abs(reg0 - reg1)
        start <= '1';
        reg_in_0 <= "00";
        reg_in_1 <= "01";
        reg_out <= "10";
        global_operand <= (others => '0');
        address_increment <= (others => '0');
        operation <= "1000";
        wait until (done = '1');
        wait for clock_period/2; -- set data on falling edge
        start <= '0';
        wait for clock_period;
        wait for clock_period;

        -- reg0 <- reg2 threshold 7
        start <= '1';
        reg_in_0 <= "10";
        reg_in_1 <= "11";
        reg_out <= "00";
        global_operand <= x"07";
        address_increment <= (others => '0');
        operation <= "0111";
        wait until (done = '1');
        wait for clock_period/2; -- set data on falling edge
        start <= '0';
        wait for clock_period;
        wait for clock_period;

        -- save reg0 to file
        start <= '1';
        reg_in_0 <= "00";
        reg_in_1 <= "00";
        reg_out <= "00";
        global_operand <= (others => '0');
        address_increment <= (others => '0');
        operation <= "1011";
        wait for clock_period;

        file_open(img_file, "processor_test_edge_detector.pgm", write_mode);
        while (done = '0') loop
            wait for clock_period/2; -- read data on rising edge
            if (write_en_save = '1') then
                if (data_out_save = ASCII_LF) then
                    writeline(img_file, img_line);
                else
                    img_byte := character'val(to_integer(unsigned(data_out_save)));
                    write(img_line, img_byte);
                end if;
            end if;
            wait for clock_period/2;
        end loop;
        writeline(img_file, img_line); -- flush line buffer
        file_close(img_file);
        wait for clock_period/2; -- set data on falling edge
        start <= '0';
        wait for clock_period;
        wait for clock_period;

        wait;
    end process;

end architecture;
