
transcript on

vlib work
vmap work

#########################
# Simulation parameters #
#   Change as needed    #
#########################
set sim_duration "1 us"
set zoom_start 0ns
set zoom_end   400ns

#######################
# Compile the sources #
#######################
vlog ../src/timer.sv

vlog timer_tb.sv

# Open the testbench module for simulation
vsim work.timer_tb

###############################
# Add signals to time diagram #
###############################
set instance {timer_tb/Dut}

add wave -color #00ff00                 $instance/clk
add wave -color #00ff00                 $instance/rst_n
add wave -color #00ff00                 $instance/to_clear_timer_i
add wave -color #ffff00 -radix unsigned $instance/ns_cnt_o
add wave -color #f0ff00                 $instance/overflow

# run the simulation
run $sim_duration

# expand the signals time diagram
wave zoom range $zoom_start $zoom_end
#wave zoom full