library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
use work.image_io_error.all;

entity image_load_tb is
end image_load_tb;

architecture arch of image_load_tb is
    
    component image_load is
        port (clock : in std_logic; -- clock signal
              reset : in std_logic; -- asynchronous reset
              load_en : in std_logic; -- loads data while flag is set and finishes loading when flag is reset
              data_in : in std_logic_vector(7 downto 0); -- data being loaded
              img_width : out std_logic_vector(7 downto 0); -- image width loaded so far
              img_height : out std_logic_vector(7 downto 0); -- image height loaded so far
              maxval : out std_logic_vector(7 downto 0); -- maxval loaded so far
              write_en : out std_logic; -- enables writing the current pixel to memory
              address : out std_logic_vector(15 downto 0); -- memory address to write pixel to
              pixel_data : out std_logic_vector(7 downto 0); -- pixel data to write to memory
              done : out std_logic; -- flag set when finished loading
              error_code : out std_logic_vector(3 downto 0)); -- error encountered while parsing image file
    end component;

    constant clock_period : time := 1 ns;

    constant ASCII_LF : std_logic_vector(7 downto 0) := x"0A";

    signal clock : std_logic;
    signal reset : std_logic;
    signal load_en : std_logic;
    signal data_in : std_logic_vector(7 downto 0);
    signal img_width : std_logic_vector(7 downto 0);
    signal img_height : std_logic_vector(7 downto 0);
    signal maxval : std_logic_vector(7 downto 0);
    signal write_en : std_logic;
    signal address : std_logic_vector(15 downto 0);
    signal pixel_data : std_logic_vector(7 downto 0);
    signal done : std_logic;
    signal error_code : std_logic_vector(3 downto 0);

begin

    image_loader : image_load
    port map (clock => clock,
              reset => reset,
              load_en => load_en,
              data_in => data_in,
              img_width => img_width,
              img_height => img_height,
              maxval => maxval,
              write_en => write_en,
              address => address,
              pixel_data => pixel_data,
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

        report "Testing valid file parsing...";

        file_open(img_file, "people106.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (unsigned(img_width) = 48) report "width should be 48 but was " & integer'image(to_integer(unsigned(img_width))) severity error;
        assert (unsigned(img_height) = 36) report "height should be 36 but was " & integer'image(to_integer(unsigned(img_height))) severity error;
        assert (unsigned(maxval) = 255) report "maxval should be 255 but was " & integer'image(to_integer(unsigned(maxval))) severity error;
        assert (error_code = NONE) report "error code should be NONE but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing invalid file type...";

        file_open(img_file, "invalid_file_type.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (error_code = INVALID_FILETYPE) report "error code should be INVALID_FILETYPE but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing file with width too large...";

        file_open(img_file, "large_width.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (error_code = WIDTH_TOO_LARGE) report "error code should be WIDTH_TOO_LARGE but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing file with height too large...";

        file_open(img_file, "large_height.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (unsigned(img_width) = 1) report "width should be 1 but was " & integer'image(to_integer(unsigned(img_width))) severity error;
        assert (error_code = HEIGHT_TOO_LARGE) report "error code should be HEIGHT_TOO_LARGE but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing file with maxval too large...";

        file_open(img_file, "large_maxval.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (unsigned(img_width) = 4) report "width should be 4 but was " & integer'image(to_integer(unsigned(img_width))) severity error;
        assert (unsigned(img_height) = 2) report "height should be 2 but was " & integer'image(to_integer(unsigned(img_height))) severity error;
        assert (error_code = MAXVAL_TOO_LARGE) report "error code should be MAXVAL_TOO_LARGE but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing file with pixel too large...";

        file_open(img_file, "large_pixel.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (unsigned(img_width) = 4) report "width should be 4 but was " & integer'image(to_integer(unsigned(img_width))) severity error;
        assert (unsigned(img_height) = 2) report "height should be 2 but was " & integer'image(to_integer(unsigned(img_height))) severity error;
        assert (unsigned(maxval) = 255) report "maxval should be 255 but was " & integer'image(to_integer(unsigned(maxval))) severity error;
        assert (error_code = PIXEL_TOO_LARGE) report "error code should be PIXEL_TOO_LARGE but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing file with too many pixels...";

        file_open(img_file, "too_many_pixels.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (unsigned(img_width) = 4) report "width should be 4 but was " & integer'image(to_integer(unsigned(img_width))) severity error;
        assert (unsigned(img_height) = 2) report "height should be 2 but was " & integer'image(to_integer(unsigned(img_height))) severity error;
        assert (unsigned(maxval) = 255) report "maxval should be 255 but was " & integer'image(to_integer(unsigned(maxval))) severity error;
        assert (error_code = TOO_MANY_PIXELS) report "error code should be TOO_MANY_PIXELS but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing file with too few pixels...";

        file_open(img_file, "too_few_pixels.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (unsigned(img_width) = 4) report "width should be 4 but was " & integer'image(to_integer(unsigned(img_width))) severity error;
        assert (unsigned(img_height) = 2) report "height should be 2 but was " & integer'image(to_integer(unsigned(img_height))) severity error;
        assert (unsigned(maxval) = 255) report "maxval should be 255 but was " & integer'image(to_integer(unsigned(maxval))) severity error;
        assert (error_code = TOO_FEW_PIXELS) report "error code should be TOO_FEW_PIXELS but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";
        report "Testing file with invalid token...";

        file_open(img_file, "invalid_token.pgm", read_mode);
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        load_en <= '1';
        while (not endfile(img_file)) loop
            readline(img_file, img_line);
            read_byte := true;
            while (read_byte) loop
                read(img_line, img_byte, read_byte);
                if (read_byte) then
                    data_in <= std_logic_vector(to_unsigned(character'pos(img_byte), 8));
                else
                    data_in <= ASCII_LF;
                end if;
                wait for clock_period;
            end loop;
        end loop;
        load_en <= '0';
        file_close(img_file);
        wait until (done = '1');

        assert (error_code = INVALID_TOKEN) report "error code should be INVALID_TOKEN but was " & integer'image(to_integer(unsigned(error_code))) severity error;
        
        report "Done";

        wait;
    end process;

end architecture;
