proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/pixel_processor_tb/clock
    add wave -position end sim:/pixel_processor_tb/pixel_data
    add wave -position end sim:/pixel_processor_tb/pixel_operand
    add wave -position end sim:/pixel_processor_tb/maxval
    add wave -position end sim:/pixel_processor_tb/operation
    add wave -position end sim:/pixel_processor_tb/data_out
    add wave -position end sim:/pixel_processor_tb/data_valid
}

vlib work

;# Compile components
vcom pixel_processor.vhd
vcom pixel_processor_tb.vhd

;# Start simulation
vsim -t ps pixel_processor_tb

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 50 ns
run 50ns
