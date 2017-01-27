-- Error definitions for the parsing of a PGM image file.

package image_io_error is
    type error_type is (NONE, INVALID_FILETYPE, WIDTH_TOO_LARGE, HEIGHT_TOO_LARGE, MAXVAL_TOO_LARGE, PIXEL_TOO_LARGE, TOO_MANY_PIXELS, TOO_FEW_PIXELS, INVALID_TOKEN);
end package;
