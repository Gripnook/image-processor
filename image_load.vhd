-- Implements a datapath/controller digital system designed to parse
-- a PGM image file and output the pixels and metadata to a memory block.
-- The inputs are assumed to be connected to a file stream feeding in data
-- byte by byte and the outputs are assumed to be connected to a memory block.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.image_io_error.all;

entity image_load is
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
          error_code : out error_type); -- error encountered while parsing image file
end image_load;

architecture arch of image_load is

    component image_load_controller is
        port (clock : in std_logic; -- clock signal
              reset : in std_logic; -- asynchronous reset
              load_en : in std_logic; -- loads data while flag is set and finishes loading when flag is reset
              data_in : in std_logic_vector(7 downto 0); -- data being loaded
              data_index : in std_logic_vector(1 downto 0); -- index of the numeric data being loaded (width/height/maxval/pixel)
              img_width : in std_logic_vector(11 downto 0); -- image width loaded so far
              img_height : in std_logic_vector(11 downto 0); -- image height loaded so far
              maxval : in std_logic_vector(11 downto 0); -- maxval loaded so far
              pixel_data : in std_logic_vector(11 downto 0); -- current pixel being loaded
              address : in std_logic_vector(15 downto 0); -- address of pixel being loaded
              write_en : out std_logic; -- enables writing the current pixel to memory
              data_index_cnt_en : out std_logic; -- increments the data index
              data_en : out std_logic; -- enables loading numeric data
              address_cnt_en : out std_logic; -- increments the address
              pixel_data_clr : out std_logic; -- clear the current pixel
              done : out std_logic; -- flag set when finished loading
              error_code : out error_type); -- error encountered while parsing image file
    end component;

    signal data_index : std_logic_vector(1 downto 0);
    signal img_width_internal : std_logic_vector(11 downto 0);
    signal img_height_internal : std_logic_vector(11 downto 0);
    signal maxval_internal : std_logic_vector(11 downto 0);
    signal pixel_data_internal : std_logic_vector(11 downto 0);
    signal address_internal : std_logic_vector(15 downto 0);
    signal data_index_cnt_en : std_logic;
    signal data_en : std_logic;
    signal address_cnt_en : std_logic;
    signal pixel_data_clr : std_logic;

    signal data_reg_input : std_logic_vector(11 downto 0);

begin

    controller : image_load_controller
    port map (clock => clock,
              reset => reset,
              load_en => load_en,
              data_in => data_in,
              data_index => data_index,
              img_width => img_width_internal,
              img_height => img_height_internal,
              maxval => maxval_internal,
              pixel_data => pixel_data_internal,
              address => address_internal,
              write_en => write_en,
              data_index_cnt_en => data_index_cnt_en,
              data_en => data_en,
              address_cnt_en => address_cnt_en,
              pixel_data_clr => pixel_data_clr,
              done => done,
              error_code => error_code);

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

    data_registers_process : process (clock, reset)
    begin
        if (reset = '1') then
            img_width_internal <= (others => '0');
            img_height_internal <= (others => '0');
            maxval_internal <= (others => '0');
            pixel_data_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (data_en = '1') then
                if (data_index = "00") then
                    img_width_internal <= data_reg_input;
                elsif (data_index = "01") then
                    img_height_internal <= data_reg_input;
                elsif (data_index = "10") then
                    maxval_internal <= data_reg_input;
                elsif (data_index = "11") then
                    pixel_data_internal <= data_reg_input;
                end if;
            end if;
            if (pixel_data_clr = '1') then
                pixel_data_internal <= (others => '0');
            end if;
        end if;
    end process;

    data_reg_input_process : process (data_in, data_index, img_width_internal, img_height_internal, maxval_internal, pixel_data_internal)
        variable feedback_signal : std_logic_vector(11 downto 0);
    begin
        feedback_signal := (others => '0');
        if (data_index = "00") then
            feedback_signal := img_width_internal;
        elsif (data_index = "01") then
            feedback_signal := img_height_internal;
        elsif (data_index = "10") then
            feedback_signal := maxval_internal;
        elsif (data_index = "11") then
            feedback_signal := pixel_data_internal;
        end if;
        -- data_reg_input = 10 * feedback_signal + data_in
        data_reg_input <= std_logic_vector(unsigned(feedback_signal(10 downto 0) & "0") +
            unsigned(feedback_signal(8 downto 0) & "000") +
            (unsigned(data_in) - x"30"));
    end process;

    img_width <= img_width_internal(7 downto 0);
    img_height <= img_height_internal(7 downto 0);
    maxval <= maxval_internal(7 downto 0);
    pixel_data <= pixel_data_internal(7 downto 0);
    address <= address_internal;

end architecture;
