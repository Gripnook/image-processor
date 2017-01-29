proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/image_edge_detector_tb/clock
    add wave -position end sim:/image_edge_detector_tb/reset
    add wave -position end sim:/image_edge_detector_tb/start
    add wave -position end sim:/image_edge_detector_tb/reg_in_0
    add wave -position end sim:/image_edge_detector_tb/reg_in_1
    add wave -position end sim:/image_edge_detector_tb/reg_out
    add wave -position end sim:/image_edge_detector_tb/global_operand
    add wave -position end sim:/image_edge_detector_tb/address_increment
    add wave -position end sim:/image_edge_detector_tb/operation
    add wave -position end sim:/image_edge_detector_tb/data_in_load
    add wave -position end sim:/image_edge_detector_tb/read_en_load
    add wave -position end sim:/image_edge_detector_tb/write_en_save
    add wave -position end sim:/image_edge_detector_tb/data_out_save
    add wave -position end sim:/image_edge_detector_tb/done
    add wave -position end sim:/image_edge_detector_tb/error_code
}

vlib work

;# Compile components
vcom sram.vhd
vcom image_io_error.vhd
vcom image_load_controller.vhd
vcom image_load.vhd
vcom image_save_controller.vhd
vcom image_save.vhd
vcom pixel_processor.vhd
vcom image_processor_controller.vhd
vcom image_processor.vhd
vcom image_edge_detector_tb.vhd

;# Start simulation
vsim -t ps image_edge_detector_tb

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 60000 ns
run 60000ns
