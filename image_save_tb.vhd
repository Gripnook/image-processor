library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;

entity image_save_tb is
end image_save_tb;

architecture arch of image_save_tb is
    
    component image_save is
        port (clock : in std_logic; -- clock signal
              reset : in std_logic; -- asynchronous reset
              save_en : in std_logic; -- starts saving data when flag is set
              img_width : in std_logic_vector(7 downto 0); -- image width
              img_height : in std_logic_vector(7 downto 0); -- image height
              maxval : in std_logic_vector(7 downto 0); -- max pixel value
              pixel_data : in std_logic_vector(7 downto 0); -- pixel being saved
              write_en : out std_logic; -- flags that data can be written to file
              data_out : out std_logic_vector(7 downto 0); -- ascii character to save to file
              read_en : out std_logic; -- flags that the next data can be loaded from memory
              address : out std_logic_vector(15 downto 0); -- address of the next pixel to be saved
              done : out std_logic); -- flag set when done saving
    end component;

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

    constant ASCII_LF : std_logic_vector(7 downto 0) := x"0A";

    signal clock : std_logic;
    signal reset : std_logic;
    signal save_en : std_logic;
    signal img_width : std_logic_vector(7 downto 0);
    signal img_height : std_logic_vector(7 downto 0);
    signal maxval : std_logic_vector(7 downto 0);
    signal pixel_data : std_logic_vector(7 downto 0);
    signal write_en : std_logic;
    signal data_out : std_logic_vector(7 downto 0);
    signal read_en : std_logic;
    signal address : std_logic_vector(15 downto 0);
    signal done : std_logic;

    signal data_in : std_logic_vector(7 downto 0);
    signal sram_write_en : std_logic;
    signal sram_read_en : std_logic;
    signal sram_address : std_logic_vector(15 downto 0);

begin

    image_saver : image_save
    port map (clock => clock,
              reset => reset,
              save_en => save_en,
              img_width => img_width,
              img_height => img_height,
              maxval => maxval,
              pixel_data => pixel_data,
              write_en => write_en,
              data_out => data_out,
              read_en => read_en,
              address => address,
              done => done);

    memory : sram
    port map (clock => clock, read_en => sram_read_en, write_en => sram_write_en, address => sram_address, data_in => data_in, data_out => pixel_data);

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
    begin

        report "Testing file write...";
        -- P2
        -- 4 2
        -- 255
        -- 255 221 187 153
        -- 119 85 51 17

        reset <= '1';
        wait for clock_period;
        reset <= '0';

        img_width <= x"04";
        img_height <= x"02";
        maxval <= x"FF";
        sram_write_en <= '1';
        sram_read_en <= '0';
        sram_address <= x"0000";
        data_in <= x"FF";
        wait for clock_period;
        sram_address <= x"0001";
        data_in <= x"DD";
        wait for clock_period;
        sram_address <= x"0002";
        data_in <= x"BB";
        wait for clock_period;
        sram_address <= x"0003";
        data_in <= x"99";
        wait for clock_period;
        sram_address <= x"0004";
        data_in <= x"77";
        wait for clock_period;
        sram_address <= x"0005";
        data_in <= x"55";
        wait for clock_period;
        sram_address <= x"0006";
        data_in <= x"33";
        wait for clock_period;
        sram_address <= x"0007";
        data_in <= x"11";
        wait for clock_period;
        sram_write_en <= '0';

        -- write to file using sram
        file_open(img_file, "write_test.pgm", write_mode);
        save_en <= '1';
        while (done = '0') loop
            sram_read_en <= read_en;
            sram_address <= address;
            wait for clock_period/2; -- read data on rising edge
            if (write_en = '1') then
                if (data_out = ASCII_LF) then
                    writeline(img_file, img_line);
                else
                    img_byte := character'val(to_integer(unsigned(data_out)));
                    write(img_line, img_byte);
                end if;
            end if;
            wait for clock_period/2;
        end loop;
        writeline(img_file, img_line); -- flush line buffer
        save_en <= '0';
        file_close(img_file);

        report "Wrote file write_test.pgm";
        report "Done";

        wait;
    end process;

end architecture;
