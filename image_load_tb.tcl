proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/image_load_tb/clock
    add wave -position end sim:/image_load_tb/reset
    add wave -position end sim:/image_load_tb/load_en
    add wave -position end sim:/image_load_tb/data_in
    add wave -position end sim:/image_load_tb/img_width
    add wave -position end sim:/image_load_tb/img_height
    add wave -position end sim:/image_load_tb/maxval
    add wave -position end sim:/image_load_tb/write_en
    add wave -position end sim:/image_load_tb/address
    add wave -position end sim:/image_load_tb/pixel_data
    add wave -position end sim:/image_load_tb/done
    add wave -position end sim:/image_load_tb/error_code
}

vlib work

;# Compile components
vcom image_io_error.vhd
vcom image_load_controller.vhd
vcom image_load.vhd
vcom image_load_tb.vhd

;# Start simulation
vsim -t ps image_load_tb

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 12000 ns
run 12000ns
