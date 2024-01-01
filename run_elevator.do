quit -sim
vcom -work work elevator_controller.vhd
vcom -work work request_resolver.vhd
vcom -work work timer.vhd
vcom -work work unit_control.vhd
vcom -work work floor_counter.vhd
vcom -work work ssd_decoder.vhd
vcom -2008 -work work elevator_tb.vhd

vsim elevator_tb
run -all
