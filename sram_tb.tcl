proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/sram_tb/clock
    add wave -position end sim:/sram_tb/read_en
    add wave -position end sim:/sram_tb/write_en
    add wave -position end sim:/sram_tb/address
    add wave -position end sim:/sram_tb/data_in
    add wave -position end sim:/sram_tb/data_out
}

vlib work

;# Compile components
vcom sram.vhd
vcom sram_tb.vhd

;# Start simulation
vsim -t ps sram_tb

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 50 ns
run 50ns
