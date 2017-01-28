-- Implements an image processor that can perform operations on PGM images.
-- 
-- Supported operations are:
-- 0: reg_out <- reg_in_1
-- 1: reg_out <- reg_in_0 + reg_in_1, capped at MAXVAL
-- 2: reg_out <- reg_in_0 - reg_in_1, capped at 0
-- 3: reg_out <- reg_in_0 AND reg_in_1
-- 4: reg_out <- reg_in_0 OR reg_in_1
-- 5: reg_out <- reg_in_0 XOR reg_in_1
-- 6: reg_out <- MAXVAL - reg_in_0
-- 7: reg_out <- reg_in_0 > reg_in_1 ? MAXVAL : reg_in_0
-- 8: reg_out <- abs(reg_in_0 - reg_in_1)
-- 9: reg_out <- file
-- 10: file <- reg_in_0
-- 
-- reg_in_0 can be any of 00,01,10
-- reg_in_1 can be any of 00,01,10,11
-- reg_out can be any of 00,01,10
-- 
-- register 11 is a proxy for the global operand. If it is selected for reg_in_1, the constant value
-- global_operand is used in all operations.
-- 
-- Note that after each operation, start must be reset and a minimum of two clock cycles are required
-- for the processor to be ready for the next operation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.image_io_error.all;

entity image_processor is
    port (clock : in std_logic; -- clock signal
          reset : in std_logic; -- asynchronous reset
          start : in std_logic; -- starts processing when flags is set
          reg_in_0 : in std_logic_vector(1 downto 0); -- first input register (sram0/sram1/sram2)
          reg_in_1 : in std_logic_vector(1 downto 0); -- second input register (sram0/sram1/sram2/global_operand)
          reg_out : in std_logic_vector(1 downto 0); -- output register (sram0/sram1/sram2)
          global_operand : in std_logic_vector(7 downto 0); -- global operand to use in operations with every pixel of an image
          operation : in std_logic_vector(3 downto 0); -- operation to perform
          data_in_load : in std_logic_vector(7 downto 0); -- data being read from file
          read_en_load : in std_logic; -- indicates that there is still data to be read from file
          write_en_save : out std_logic; -- flags that a byte can be written to file
          data_out_save : out std_logic_vector(7 downto 0); -- byte that can be written to file
          done : out std_logic; -- finished processing
          error_code : out error_type); -- errors encountered while processing
end image_processor;

architecture arch of image_processor is

    component image_processor_controller is
        port (clock : in std_logic; -- clock signal
              reset : in std_logic; -- asynchronous reset
              start : in std_logic; -- starts processing when flag is set
              operation : in std_logic_vector(3 downto 0); -- operation to perform
              op_data_ready : in std_logic; -- flags that the data is ready to store in memory
              op_data_valid : in std_logic; -- flags that the data is valid [UNUSED]
              done_load : in std_logic; -- finished loading image from file
              error_code_load : in error_type; -- io error encountered on load
              done_save : in std_logic; -- finished saving image to file
              address : in std_logic_vector(15 downto 0); -- address of current pixel to be stored in memory
              img_width : in std_logic_vector(7 downto 0); -- width of the image being processed
              img_height : in std_logic_vector(7 downto 0); -- height of the image being processed
              input_reg_en : out std_logic; -- controls when inputs get loaded to registers
              controller_reset : out std_logic; -- reset the volatile components of the datapath
              processor_en : out std_logic; -- enabled the pixel processor to operate on data
              metadata_load_ctrl : out std_logic; -- controls which metadata to load to memory (internal/file)
              metadata_reg_en : out std_logic; -- enables loading metadata to memory
              write_en : out std_logic; -- enables writing pixel to memory
              write_ctrl : out std_logic; -- controls which pixel to load to memory (internal/file)
              read_en : out std_logic; -- enables reading pixel from memory
              read_ctrl : out std_logic; -- controls who gets to read from memory (internal/file)
              address_cnt_en : out std_logic; -- increments address of current pixel
              address_ctrl : out std_logic_vector(1 downto 0); -- controls who gets to set the memory address (internal/file load/file save)
              save_en : out std_logic; -- enables the image save submodule
              done : out std_logic; -- finished processing
              error_code : out error_type); -- errors encountered while processing
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
              error_code : out error_type); -- error encountered while parsing image file
    end component;

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

    signal reset_internal, controller_reset : std_logic;

    signal metadata_load_ctrl : std_logic;
    signal metadata_reg_en : std_logic;
    signal img_width_0, img_width_1, img_width_sram_0, img_width_sram_1, img_width_sram_2, img_width_load, img_width_next : std_logic_vector(7 downto 0);
    signal img_height_0, img_height_1, img_height_sram_0, img_height_sram_1, img_height_sram_2, img_height_load, img_height_next : std_logic_vector(7 downto 0);
    signal maxval_0, maxval_1, maxval_sram_0, maxval_sram_1, maxval_sram_2, maxval_load, maxval_next : std_logic_vector(7 downto 0);

    signal write_en, write_en_0, write_en_1, write_en_2, write_en_load, write_en_next : std_logic;
    signal data_write, data_write_load, data_write_next : std_logic_vector(7 downto 0);
    signal write_ctrl : std_logic;

    signal read_en, read_en_save, read_en_next : std_logic;
    signal read_ctrl : std_logic;
    signal data_read_0, data_read_1 : std_logic_vector(7 downto 0);
    signal data_read_sram_0, data_read_sram_1, data_read_sram_2 : std_logic_vector(7 downto 0);

    signal address, address_internal, address_save, address_load : std_logic_vector(15 downto 0);
    signal address_cnt_en : std_logic;
    signal address_ctrl : std_logic_vector(1 downto 0);

    signal input_reg_en : std_logic;
    signal reg_in_0_internal, reg_in_1_internal, reg_out_internal : std_logic_vector(1 downto 0);
    signal global_operand_internal : std_logic_vector(7 downto 0);
    signal operation_internal : std_logic_vector(3 downto 0);

    signal processor_en : std_logic;
    signal op_data_ready : std_logic;
    signal op_data_valid : std_logic;

    signal done_load : std_logic;
    signal error_code_load : error_type;

    signal done_save : std_logic;
    signal save_en : std_logic;

begin

    reset_internal <= '1' when reset = '1' else
        controller_reset;

    controller : image_processor_controller
    port map (clock => clock,
              reset => reset,
              start => start,
              operation => operation_internal,
              op_data_ready => op_data_ready,
              op_data_valid => op_data_valid,
              done_load => done_load,
              error_code_load => error_code_load,
              done_save => done_save,
              address => address_internal,
              img_width => img_width_0,
              img_height => img_height_0,
              controller_reset => controller_reset,
              input_reg_en => input_reg_en,
              processor_en => processor_en,
              metadata_load_ctrl => metadata_load_ctrl,
              metadata_reg_en => metadata_reg_en,
              write_en => write_en,
              write_ctrl => write_ctrl,
              read_en => read_en,
              read_ctrl => read_ctrl,
              address_cnt_en => address_cnt_en,
              address_ctrl => address_ctrl,
              save_en => save_en,
              done => done,
              error_code => error_code);

    reg0 : sram
    port map (clock => clock,
              read_en => read_en_next,
              write_en => write_en_0,
              address => address,
              data_in => data_write_next,
              data_out => data_read_sram_0);

    reg1 : sram
    port map (clock => clock,
              read_en => read_en_next,
              write_en => write_en_1,
              address => address,
              data_in => data_write_next,
              data_out => data_read_sram_1);

    reg2 : sram
    port map (clock => clock,
              read_en => read_en_next,
              write_en => write_en_2,
              address => address,
              data_in => data_write_next,
              data_out => data_read_sram_2);

    metadata_load_process : process (metadata_load_ctrl, img_width_0, img_width_load, img_height_0, img_height_load, maxval_0, maxval_load)
    begin
        if (metadata_load_ctrl = '1') then
            img_width_next <= img_width_load;
            img_height_next <= img_height_load;
            maxval_next <= maxval_load;
        else
            img_width_next <= img_width_0;
            img_height_next <= img_height_0;
            maxval_next <= maxval_0;
        end if;
    end process;

    metadata_reg_process : process (clock, reset)
    begin
        if (reset = '1') then
            img_width_sram_0 <= (others => '0');
            img_width_sram_1 <= (others => '0');
            img_width_sram_2 <= (others => '0');
            img_height_sram_0 <= (others => '0');
            img_height_sram_1 <= (others => '0');
            img_height_sram_2 <= (others => '0');
            maxval_sram_0 <= (others => '0');
            maxval_sram_1 <= (others => '0');
            maxval_sram_2 <= (others => '0');
        elsif (rising_edge(clock)) then
            if (metadata_reg_en = '1') then
                case reg_out_internal is
                when "00" =>
                    img_width_sram_0 <= img_width_next;
                    img_height_sram_0 <= img_height_next;
                    maxval_sram_0 <= maxval_next;
                when "01" =>
                    img_width_sram_1 <= img_width_next;
                    img_height_sram_1 <= img_height_next;
                    maxval_sram_1 <= maxval_next;
                when "10" =>
                    img_width_sram_2 <= img_width_next;
                    img_height_sram_2 <= img_height_next;
                    maxval_sram_2 <= maxval_next;
                when others =>
                    null;
                end case;
            end if;
        end if;
    end process;

    processor : pixel_processor
    port map (clock => clock,
              reset => reset_internal,
              enable => processor_en,
              pixel_data => data_read_0,
              pixel_operand => data_read_1,
              maxval => maxval_0,
              operation => operation_internal,
              data_out => data_write,
              data_ready => op_data_ready,
              data_valid => op_data_valid);

    load : image_load
    port map (clock => clock,
              reset => reset_internal,
              load_en => read_en_load,
              data_in => data_in_load,
              img_width => img_width_load,
              img_height => img_height_load,
              maxval => maxval_load,
              write_en => write_en_load,
              address => address_load,
              pixel_data => data_write_load,
              done => done_load,
              error_code => error_code_load);

    save : image_save
    port map (clock => clock,
              reset => reset_internal,
              save_en => save_en,
              img_width => img_width_0,
              img_height => img_height_0,
              maxval => maxval_0,
              pixel_data => data_read_0,
              write_en => write_en_save,
              data_out => data_out_save,
              read_en => read_en_save,
              address => address_save,
              done => done_save);

    input_reg_process : process (clock, reset)
    begin
        if (reset = '1') then
            reg_in_0_internal <= (others => '0');
            reg_in_1_internal <= (others => '0');
            reg_out_internal <= (others => '0');
            global_operand_internal <= (others => '0');
            operation_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (input_reg_en = '1') then
                reg_in_0_internal <= reg_in_0;
                reg_in_1_internal <= reg_in_1;
                reg_out_internal <= reg_out;
                global_operand_internal <= global_operand;
                operation_internal <= operation;
            end if;
        end if;
    end process;

    reg_in_0_process : process (reg_in_0_internal, data_read_sram_0, data_read_sram_1, data_read_sram_2, global_operand_internal,
        img_width_sram_0, img_width_sram_1, img_width_sram_2, img_height_sram_0, img_height_sram_1, img_height_sram_2, maxval_sram_0, maxval_sram_1, maxval_sram_2)
    begin
        case reg_in_0_internal is
        when "00" =>
            data_read_0 <= data_read_sram_0;
            img_width_0 <= img_width_sram_0;
            img_height_0 <= img_height_sram_0;
            maxval_0 <= maxval_sram_0;
        when "01" =>
            data_read_0 <= data_read_sram_1;
            img_width_0 <= img_width_sram_1;
            img_height_0 <= img_height_sram_1;
            maxval_0 <= maxval_sram_1;
        when "10" =>
            data_read_0 <= data_read_sram_2;
            img_width_0 <= img_width_sram_2;
            img_height_0 <= img_height_sram_2;
            maxval_0 <= maxval_sram_2;
        when others =>
            data_read_0 <= (others => '0'); -- reg0 is not allowed to be a global operand
            img_width_0 <= (others => '0');
            img_height_0 <= (others => '0');
            maxval_0 <= (others => '0');
        end case;
    end process;

    reg_in_1_process : process (reg_in_1_internal, data_read_sram_0, data_read_sram_1, data_read_sram_2, global_operand_internal,
        img_width_sram_0, img_width_sram_1, img_width_sram_2, img_height_sram_0, img_height_sram_1, img_height_sram_2, maxval_sram_0, maxval_sram_1, maxval_sram_2)
    begin
        case reg_in_1_internal is
        when "00" =>
            data_read_1 <= data_read_sram_0;
            img_width_1 <= img_width_sram_0;
            img_height_1 <= img_height_sram_0;
            maxval_1 <= maxval_sram_0;
        when "01" =>
            data_read_1 <= data_read_sram_1;
            img_width_1 <= img_width_sram_1;
            img_height_1 <= img_height_sram_1;
            maxval_1 <= maxval_sram_1;
        when "10" =>
            data_read_1 <= data_read_sram_2;
            img_width_1 <= img_width_sram_2;
            img_height_1 <= img_height_sram_2;
            maxval_1 <= maxval_sram_2;
        when others =>
            data_read_1 <= global_operand_internal;
            img_width_1 <= (others => '0');
            img_height_1 <= (others => '0');
            maxval_1 <= (others => '0');
        end case;
    end process;

    with read_ctrl select read_en_next <=
        read_en_save when '1',
        read_en when others;

    with write_ctrl select write_en_next <=
        write_en_load when '1',
        write_en when others;
    with write_ctrl select data_write_next <=
        data_write_load when '1',
        data_write when others;

    write_decoder_process : process (reg_out_internal, write_en_next)
    begin
        write_en_0 <= '0';
        write_en_1 <= '0';
        write_en_2 <= '0';
        if (reg_out_internal = "00") then
            write_en_0 <= write_en_next;
        elsif (reg_out_internal = "01") then
            write_en_1 <= write_en_next;
        elsif (reg_out_internal = "10") then
            write_en_2 <= write_en_next;
        end if;
    end process;

    address_counter_process : process (clock, reset_internal)
    begin
        if (reset_internal = '1') then
            address_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (address_cnt_en = '1') then
                address_internal <= std_logic_vector(unsigned(address_internal) + 1);
            end if;
        end if;
    end process;

    with address_ctrl select address <=
        address_internal when "00",
        address_load when "01",
        address_save when others;

end architecture;
