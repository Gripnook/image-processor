proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/image_save_tb/clock
    add wave -position end sim:/image_save_tb/reset
    add wave -position end sim:/image_save_tb/save_en
    add wave -position end sim:/image_save_tb/img_width
    add wave -position end sim:/image_save_tb/img_height
    add wave -position end sim:/image_save_tb/maxval
    add wave -position end sim:/image_save_tb/pixel_data
    add wave -position end sim:/image_save_tb/write_en
    add wave -position end sim:/image_save_tb/data_out
    add wave -position end sim:/image_save_tb/read_en
    add wave -position end sim:/image_save_tb/address
    add wave -position end sim:/image_save_tb/done
}

vlib work

;# Compile components
vcom sram.vhd
vcom image_save_controller.vhd
vcom image_save.vhd
vcom image_save_tb.vhd

;# Start simulation
vsim -t ps image_save_tb

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 100 ns
run 100ns
