-- Implements a datapath/controller digital system designed to output a
-- PGM image stored in memory to a file.
-- The inputs are assumed to be connected to a memory block from where the image
-- can be retrieved and the outputs are assumed to be connected to a file writer which
-- writes the output as ascii characters byte by byte on the active clock edge.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity image_save is
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
end image_save;

architecture arch of image_save is

    -- converts an 8-bit binary number to its bcd representation.
    function to_bcd (binary_input : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable i : integer := 0;
        variable j : integer := 1;
        variable bcd :  std_logic_vector(11 downto 0) := (others => '0');
        variable binary_number : std_logic_vector(7 downto 0) := binary_input;
    begin
        for i in 0 to 7 loop
            bcd(11 downto 1) := bcd(10 downto 0); -- shift the bcd bits
            bcd(0) := binary_number(7);
            
            binary_number(7 downto 1) := binary_number(6 downto 0); -- shift the input bits
            binary_number(0) := '0';
            
            for j in 1 to 3 loop -- for each bcd digit add 3 if it is greater than 4
                if (i < 7 and bcd ((4*j-1) downto (4*j-4)) > x"4") then
                    bcd((4*j-1) downto (4*j-4)) := std_logic_vector(unsigned(bcd((4*j-1) downto (4*j-4))) + x"3");
                end if;
            end loop;
        end loop;
        return bcd;
    end to_bcd;

    -- converts a bcd digit to its ascii representation.
    function bcd_to_ascii (bcd : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        return std_logic_vector(unsigned(bcd) + x"30"); -- add the character 0 in ascii
    end bcd_to_ascii;
    
    component image_save_controller is
        port (clock : in std_logic; -- clock signal
              reset : in std_logic; -- asynchronous reset
              save_en : in std_logic; -- starts saving data when flag is set
              img_width : in std_logic_vector(7 downto 0); -- image width
              img_height : in std_logic_vector(7 downto 0); -- image height
              data_index : in std_logic_vector(1 downto 0); -- index of the data being saved
              bcd_index : in std_logic_vector(1 downto 0); -- index of the digit being saved
              address : in std_logic_vector(15 downto 0); -- address of the next pixel to be saved
              data_index_cnt_en : out std_logic; -- increments the data index
              data_reg_en : out std_logic; -- enables loading the next data to save
              bcd_index_cnt_en : out std_logic; -- increments the bcd index
              bcd_index_cnt_clr : out std_logic; -- clears the bcd index
              data_out_ctrl : out std_logic_vector(2 downto 0); -- chooses the next data to save (number/P/2/NEWLINE/SPACE)
              address_cnt_en : out std_logic; -- increments the address
              write_en : out std_logic; -- flags that data can be written to the file
              read_en : out std_logic; -- flags that the next data can be loaded from memory
              done : out std_logic); -- flag set when done saving
    end component;

    constant ASCII_P : std_logic_vector(7 downto 0) := x"50";
    constant ASCII_2 : std_logic_vector(7 downto 0) := x"32";
    constant ASCII_SPACE : std_logic_vector(7 downto 0) := x"20";
    constant ASCII_LF : std_logic_vector(7 downto 0) := x"0A";

    signal data_reg_input : std_logic_vector(7 downto 0);
    signal data_reg_en : std_logic;
    signal data_reg : std_logic_vector(7 downto 0);
    signal data_index : std_logic_vector(1 downto 0);
    signal data_index_cnt_en : std_logic;
    signal address_internal : std_logic_vector(15 downto 0);
    signal address_cnt_en : std_logic;
    signal bcd_index : std_logic_vector(1 downto 0);
    signal bcd_index_cnt_en : std_logic;
    signal bcd_index_cnt_clr : std_logic;
    signal data_out_ctrl : std_logic_vector(2 downto 0);
    signal data_bcd : std_logic_vector(11 downto 0);
    signal data_digit : std_logic_vector(3 downto 0);

begin

    controller : image_save_controller
    port map (clock => clock,
              reset => reset,
              save_en => save_en,
              img_width => img_width,
              img_height => img_height,
              data_index => data_index,
              bcd_index => bcd_index,
              address => address_internal,
              data_index_cnt_en => data_index_cnt_en,
              data_reg_en => data_reg_en,
              bcd_index_cnt_en => bcd_index_cnt_en,
              bcd_index_cnt_clr => bcd_index_cnt_clr,
              data_out_ctrl => data_out_ctrl,
              address_cnt_en => address_cnt_en,
              write_en => write_en,
              read_en => read_en,
              done => done);

    data_index_counter_process : process (clock, reset)
    begin
        if (reset = '1') then
            data_index <= (others => '0');
        elsif (rising_edge(clock)) then
            if (data_index_cnt_en = '1') then
                data_index <= std_logic_vector(unsigned(data_index) + 1);
            end if;
        end if;
    end process;

    address_counter_process : process (clock, reset)
    begin
        if (reset = '1') then
            address_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (address_cnt_en = '1') then
                address_internal <= std_logic_vector(unsigned(address_internal) + 1);
            end if;
        end if;
    end process;

    bcd_index_counter_process : process (clock, reset)
    begin
        if (reset = '1') then
            bcd_index <= (others => '0');
        elsif (rising_edge(clock)) then
            if (bcd_index_cnt_en = '1') then
                bcd_index <= std_logic_vector(unsigned(bcd_index) + 1);
            end if;
            if (bcd_index_cnt_clr = '1') then
                bcd_index <= (others => '0');
            end if;
        end if;
    end process;

    with data_index select data_reg_input <=
        img_width when "00",
        img_height when "01",
        maxval when "10",
        pixel_data when "11",
        (others => '0') when others;

    data_reg_process : process (clock, reset)
    begin
        if (reset = '1') then
            data_reg <= (others => '0');
        elsif (rising_edge(clock)) then
            if (data_reg_en = '1') then
                data_reg <= data_reg_input;
            end if;
        end if;
    end process;

    data_bcd <= to_bcd(data_reg);

    with bcd_index select data_digit <=
        data_bcd(11 downto 8) when "00",
        data_bcd(7 downto 4) when "01",
        data_bcd(3 downto 0) when "10",
        (others => '0') when others;

    with data_out_ctrl select data_out <=
        bcd_to_ascii(data_digit) when "000",
        ASCII_P when "001",
        ASCII_2 when "010",
        ASCII_LF when "011",
        ASCII_SPACE when "100",
        (others => '0') when others;

    address <= address_internal;

end architecture;
