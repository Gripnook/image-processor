-- Implements a controller for an image processor that can perform operations
-- on PGM images. Uses a Mealy type finite state machine.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.image_io_error.all;

entity image_processor_controller is
    port (clock : in std_logic; -- clock signal
          reset : in std_logic; -- asynchronous reset
          start : in std_logic; -- starts processing when flag is set
          operation : in std_logic_vector(3 downto 0); -- operation to perform
          op_data_ready : in std_logic; -- flags that the data is ready to store in memory
          op_data_valid : in std_logic; -- flags that the data is valid [UNUSED]
          done_load : in std_logic; -- finished loading image from file
          error_code_load : in std_logic_vector(3 downto 0); -- io error encountered on load
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
          error_code : out std_logic_vector(3 downto 0)); -- errors encountered while processing
end image_processor_controller;

architecture arch of image_processor_controller is

    type state_type is (A, B, C, D, E, F, G, H);
    signal state : state_type;

begin

    state_transition_process : process (clock, reset)
    begin
        if (reset = '1') then
            state <= A;
            error_code <= NONE;
        elsif (rising_edge(clock)) then
            case state is
            when A =>
                if (start = '1') then
                    state <= B;
                else
                    state <= A;
                end if;
            when B =>
                if (operation = "1001") then
                    state <= D;
                elsif (operation = "1010") then
                    state <= E;
                else
                    state <= C;
                end if;
            when C =>
                if (to_integer(unsigned(address)) = to_integer(unsigned(img_width)) * to_integer(unsigned(img_height))) then
                    state <= H;
                else
                    state <= F;
                end if;
            when D =>
                if (done_load = '1') then
                    if (error_code_load /= NONE) then
                        error_code <= error_code_load;
                    end if;
                    state <= H;
                else
                    state <= D;
                end if;
            when E =>
                if (done_save = '1') then
                    state <= H;
                else
                    state <= E;
                end if;
            when F =>
                state <= G;
            when G =>
                if (op_data_ready = '1') then
                    state <= C;
                else
                    state <= G;
                end if;
            when H =>
                if (start = '0') then
                    state <= A;
                    error_code <= NONE;
                else
                    state <= H;
                end if;
            when others =>
            end case;
        end if;
    end process;

    output_process : process (reset, start, operation, done_load, done_save, op_data_ready, op_data_valid,
        address, img_width, img_height, state)
    begin
        if (reset = '1') then
            controller_reset <= '0';
            input_reg_en <= '0';
            processor_en <= '0';
            metadata_load_ctrl <= '0';
            metadata_reg_en <= '0';
            write_en <= '0';
            write_ctrl <= '0';
            read_en <= '0';
            read_ctrl <= '0';
            address_cnt_en <= '0';
            address_ctrl <= "00";
            save_en <= '0';
            done <= '0';
        else
            controller_reset <= '0';
            input_reg_en <= '0';
            processor_en <= '0';
            metadata_load_ctrl <= '0';
            metadata_reg_en <= '0';
            write_en <= '0';
            write_ctrl <= '0';
            read_en <= '0';
            read_ctrl <= '0';
            address_cnt_en <= '0';
            address_ctrl <= "00";
            save_en <= '0';
            done <= '0';

            case state is
            when A =>
                if (start = '1') then
                    controller_reset <= '1';
                    input_reg_en <= '1';
                else
                    controller_reset <= '1';
                end if;
            when B =>
                if (operation = "1001") then
                    metadata_load_ctrl <= '1';
                    metadata_reg_en <= '1';
                    write_ctrl <= '1';
                    address_ctrl <= "01";
                elsif (operation = "1010") then
                    read_ctrl <= '1';
                    address_ctrl <= "10";
                    save_en <= '1';
                else
                    metadata_reg_en <= '1';
                end if;
            when C =>
                if (to_integer(unsigned(address)) = to_integer(unsigned(img_width)) * to_integer(unsigned(img_height))) then
                    done <= '1';
                else
                    address_ctrl <= "11";
                    read_en <= '1';
                end if;
            when D =>
                if (done_load = '1') then
                    
                    done <= '1';
                else
                    metadata_load_ctrl <= '1';
                    metadata_reg_en <= '1';
                    write_ctrl <= '1';
                    address_ctrl <= "01";
                end if;
            when E =>
                if (done_save = '1') then
                    done <= '1';
                else
                    read_ctrl <= '1';
                    address_ctrl <= "10";
                    save_en <= '1';
                end if;
            when F =>
                processor_en <= '1';
            when G =>
                if (op_data_ready = '1') then
                    -- op_data_valid could be checked here for internal data errors
                    processor_en <= '1';
                    write_en <= '1';
                    address_cnt_en <= '1';
                else
                    processor_en <= '1';
                end if;
            when H =>
                if (start = '0') then
                    controller_reset <= '1';
                    done <= '0';
                else
                    done <= '1';
                end if;
            when others =>
                null;
            end case;
        end if;
    end process;

end architecture;
