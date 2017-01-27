-- Implements a controller designed to parse a PGM image file
-- and output the pixels and metadata to a memory block.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.image_io_error.all;

entity image_load_controller is
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
end image_load_controller;

architecture arch of image_load_controller is

    type state_type is (A, B, C, D, E, F, G, H, I, J, Z);

    signal state : state_type;

    constant ASCII_P : std_logic_vector(7 downto 0) := x"50";
    constant ASCII_0 : std_logic_vector(7 downto 0) := x"30";
    constant ASCII_2 : std_logic_vector(7 downto 0) := x"32";
    constant ASCII_9 : std_logic_vector(7 downto 0) := x"39";
    constant ASCII_HASH : std_logic_vector(7 downto 0) := x"23";
    constant ASCII_SPACE : std_logic_vector(7 downto 0) := x"20";
    constant ASCII_TAB : std_logic_vector(7 downto 0) := x"09";
    constant ASCII_CR : std_logic_vector(7 downto 0) := x"0D";
    constant ASCII_LF : std_logic_vector(7 downto 0) := x"0A";

    constant MAX_WIDTH : integer := 255;
    constant MAX_HEIGHT : integer := 255;
    constant MAX_MAXVAL : integer := 255;

begin

    state_transition_process : process (clock, reset)
    begin
        if (reset = '1') then
            state <= A;
            error_code <= NONE;
            done <= '0';
        elsif (rising_edge(clock)) then
            if (load_en = '1') then
                case state is
                when A =>
                    if (data_in = ASCII_P) then
                        state <= B;
                    else
                        state <= Z;
                        error_code <= INVALID_FILETYPE;
                    end if;

                when B =>
                    if (data_in = ASCII_2) then
                        state <= C;
                    else
                        state <= Z;
                        error_code <= INVALID_FILETYPE;
                    end if;

                when C =>
                    if (data_in = ASCII_HASH) then
                        state <= D;
                    elsif (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                        state <= E;
                    else
                        state <= Z;
                        error_code <= INVALID_TOKEN;
                    end if;

                when D =>
                    if (data_in = ASCII_LF) then
                        state <= E;
                    else
                        state <= D;
                    end if;

                when E =>
                    if (data_in = ASCII_HASH) then
                        state <= D;
                    elsif (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                        state <= E;
                    elsif (unsigned(data_in) >= unsigned(ASCII_0) and (unsigned(data_in) <= unsigned(ASCII_9))) then
                        state <= F;
                    else
                        state <= Z;
                        error_code <= INVALID_TOKEN;
                    end if;

                when F =>
                    if (data_index = "00" and unsigned(img_width) > MAX_WIDTH) then
                        state <= Z;
                        error_code <= WIDTH_TOO_LARGE;
                    elsif (data_index = "01" and unsigned(img_height) > MAX_HEIGHT) then
                        state <= Z;
                        error_code <= HEIGHT_TOO_LARGE;
                    elsif (data_index = "10" and unsigned(maxval) > MAX_MAXVAL) then
                        state <= Z;
                        error_code <= MAXVAL_TOO_LARGE;
                    elsif (data_in = ASCII_HASH) then
                        state <= G;
                    elsif (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                        state <= H;
                    elsif (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                        state <= F;
                    else
                        state <= Z;
                        error_code <= INVALID_TOKEN;
                    end if;
                    
                when G =>
                    if (data_in = ASCII_LF) then
                        state <= H;
                    else
                        state <= G;
                    end if;

                when H =>
                    if (data_index = "11") then
                        if (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                            state <= I;
                        else
                            state <= Z;
                            error_code <= INVALID_TOKEN;
                        end if;
                    else
                        if (data_in = ASCII_HASH) then
                            state <= G;
                        elsif (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                            state <= H;
                        elsif (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                            state <= F;
                        else
                            state <= Z;
                            error_code <= INVALID_TOKEN;
                        end if;
                    end if;

                when I =>
                    if (unsigned(pixel_data) > unsigned(maxval)) then
                        state <= Z;
                        error_code <= PIXEL_TOO_LARGE;
                    elsif (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                        if (to_integer(unsigned(address)) = to_integer(unsigned(img_width)) * to_integer(unsigned(img_height))) then
                            state <= Z;
                            error_code <= TOO_MANY_PIXELS;
                        else
                            state <= J;
                        end if;
                    elsif (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                        state <= I;
                    else
                        state <= Z;
                        error_code <= INVALID_TOKEN;
                    end if;

                when J =>
                    if (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                        state <= J;
                    elsif (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                        state <= I;
                    else
                        state <= Z;
                        error_code <= INVALID_TOKEN;
                    end if;

                when others =>
                    null;
                end case;
            else
                -- check if the correct number of pixels have been loaded
                if (state /= Z and to_integer(unsigned(address)) < to_integer(unsigned(img_width)) * to_integer(unsigned(img_height))) then
                    state <= Z;
                    error_code <= TOO_FEW_PIXELS;
                end if;
                -- loading complete
                done <= '1';
            end if;
        end if;
    end process;

    output_process : process (reset, load_en, data_in, data_index, state)
    begin
        if (reset = '1') then
            write_en <= '0';
            data_index_cnt_en <= '0';
            data_en <= '0';
            address_cnt_en <= '0';
            pixel_data_clr <= '0';
        else
            if (load_en = '1') then
                write_en <= '0';
                data_index_cnt_en <= '0';
                data_en <= '0';
                address_cnt_en <= '0';
                pixel_data_clr <= '0';

                case state is
                when E =>
                    if (unsigned(data_in) >= unsigned(ASCII_0) and (unsigned(data_in) <= unsigned(ASCII_9))) then
                        data_en <= '1';
                    end if;

                when F =>
                    if (data_in = ASCII_HASH) then
                        data_index_cnt_en <= '1';
                    elsif (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                        data_index_cnt_en <= '1';
                    elsif (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                        data_en <= '1';
                    end if;
                    
                when H =>
                    if (data_index = "11") then
                        if (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                            data_en <= '1';
                        end if;
                    else
                        if (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                            data_en <= '1';
                        end if;
                    end if;

                when I =>
                    if (data_in = ASCII_SPACE or data_in = ASCII_TAB or data_in = ASCII_CR or data_in = ASCII_LF) then
                        if (to_integer(unsigned(address)) < to_integer(unsigned(img_width)) * to_integer(unsigned(img_height))) then
                            write_en <= '1';
                            address_cnt_en <= '1';
                            pixel_data_clr <= '1';
                        end if;
                    elsif (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                        data_en <= '1';
                    end if;

                when J =>
                    if (unsigned(data_in) >= unsigned(ASCII_0) and unsigned(data_in) <= unsigned(ASCII_9)) then
                        data_en <= '1';
                    end if;

                when others =>
                    null;
                end case;
            end if;
        end if;
    end process;

end architecture;
