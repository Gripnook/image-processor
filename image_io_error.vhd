-- Error definitions for the parsing of a PGM image file.

library ieee;
use ieee.std_logic_1164.all;

package image_io_error is

    constant NONE : std_logic_vector(3 downto 0) := "0000";
    constant INVALID_FILETYPE : std_logic_vector(3 downto 0) := "0001";
    constant WIDTH_TOO_LARGE : std_logic_vector(3 downto 0) := "0010";
    constant HEIGHT_TOO_LARGE : std_logic_vector(3 downto 0) := "0011";
    constant MAXVAL_TOO_LARGE : std_logic_vector(3 downto 0) := "0100";
    constant PIXEL_TOO_LARGE : std_logic_vector(3 downto 0) := "0101";
    constant TOO_MANY_PIXELS : std_logic_vector(3 downto 0) := "0110";
    constant TOO_FEW_PIXELS : std_logic_vector(3 downto 0) := "0111";
    constant INVALID_TOKEN : std_logic_vector(3 downto 0) := "1000";

end package;
