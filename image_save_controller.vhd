-- Implements a controller designed to get the data for a PGM
-- image from memory and save it to a file byte by byte.
-- Uses a Mealy type finite state machine.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity image_save_controller is
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
end image_save_controller;

architecture arch of image_save_controller is

    type state_type is (A, B, C, D, E, F, G, H);
    signal state : state_type;

begin

    state_transition_process : process (clock, reset)
    begin
        if (reset = '1') then
            state <= A;
        elsif (rising_edge(clock)) then
            case state is
            when A =>
                if (save_en = '1') then
                    state <= B;
                else
                    state <= A;
                end if;
            when B =>
                state <= C;
            when C =>
                state <= D;
            when D =>
                if (bcd_index = "11") then
                    if (data_index = "11") then
                        state <= E;
                    else
                        state <= D;
                    end if;
                else
                    state <= D;
                end if;
            when E =>
                state <= F;
            when F =>
                state <= G;
            when G =>
                if (bcd_index = "11") then
                    if (to_integer(unsigned(address)) = to_integer(unsigned(img_width)) * to_integer(unsigned(img_height))) then
                        state <= H;
                    else
                        state <= E;
                    end if;
                else
                    state <= G;
                end if;
            when others =>
                null;
            end case;
        end if;
    end process;

    output_process : process (reset, data_index, bcd_index, address, img_width, img_height, state)
    begin
        if (reset = '1') then
            data_index_cnt_en <= '0';
            data_reg_en <= '0';
            bcd_index_cnt_en <= '0';
            bcd_index_cnt_clr <= '0';
            data_out_ctrl <= "000";
            address_cnt_en <= '0';
            write_en <= '0';
            read_en <= '0';
            done <= '0';
        else
            data_index_cnt_en <= '0';
            data_reg_en <= '0';
            bcd_index_cnt_en <= '0';
            bcd_index_cnt_clr <= '0';
            data_out_ctrl <= "000";
            address_cnt_en <= '0';
            write_en <= '0';
            read_en <= '0';
            done <= '0';
            case state is
            when A =>
                data_out_ctrl <= "001";
                write_en <= '1';
            when B =>
                data_out_ctrl <= "010";
                write_en <= '1';
            when C =>
                data_out_ctrl <= "011";
                data_reg_en <= '1';
                data_index_cnt_en <= '1';
                write_en <= '1';
            when D =>
                if (bcd_index = "11") then
                    if (data_index = "11") then
                        data_out_ctrl <= "011";
                        bcd_index_cnt_clr <= '1';
                        write_en <= '1';
                        read_en <= '1';
                    else
                        data_out_ctrl <= "100";
                        data_reg_en <= '1';
                        data_index_cnt_en <= '1';
                        bcd_index_cnt_clr <= '1';
                        write_en <= '1';
                    end if;
                else
                    data_out_ctrl <= "000";
                    bcd_index_cnt_en <= '1';
                    write_en <= '1';
                end if;
            when E =>
                data_reg_en <= '1';
                address_cnt_en <= '1';
            when F =>
                data_out_ctrl <= "000";
                bcd_index_cnt_en <= '1';
                write_en <= '1';
            when G =>
                if (bcd_index = "11") then
                    if (to_integer(unsigned(address)) = to_integer(unsigned(img_width)) * to_integer(unsigned(img_height))) then
                        done <= '1';
                    else
                        data_out_ctrl <= "011";
                        bcd_index_cnt_clr <= '1';
                        write_en <= '1';
                        read_en <= '1';
                    end if;
                else
                    data_out_ctrl <= "000";
                    bcd_index_cnt_en <= '1';
                    write_en <= '1';
                end if;
            when H =>
                done <= '1';
            when others =>
                null;
            end case;
        end if;
    end process;

end architecture;
