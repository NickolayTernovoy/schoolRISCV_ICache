vlib work
vmap work

vlog  ../src/sr_cpu.vh
vlog  ../src/sm_hex_display.v
vlog  ../src/sm_register.v
vlog  ../src/sm_rom.v
vlog  ../src/sr_cpu.v
vlog  ../src/srv_icache.sv
vlog  ../src/srv_mem.sv
vlog  ../src/sm_top.v
vlog  testbench.v

vsim  sm_testbench
add log -r /*


###############################
# Add signals to time diagram #
###############################
#clk and rst
add wave -color red /sm_testbench/CACHE_EN
add wave /sm_testbench/sm_top/clkIn
add wave /sm_testbench/sm_top/rst_n

add wave -color #ff9911 -radix hex -group Cache_IO  \
/sm_testbench/sm_top/sm_icache/imem_req_i \
/sm_testbench/sm_top/sm_icache/imAddr     \
/sm_testbench/sm_top/sm_icache/imData     \
/sm_testbench/sm_top/sm_icache/im_drdy    \
/sm_testbench/sm_top/sm_icache/ext_addr_o \
/sm_testbench/sm_top/sm_icache/ext_req_o  \
/sm_testbench/sm_top/sm_icache/ext_rsp_i  \
/sm_testbench/sm_top/sm_icache/ext_data_i \

add wave -color #1199ff -radix hex -group Mem_Cntrl  \
sm_testbench/sm_top/mem_ctrl/ext_addr_i \
sm_testbench/sm_top/mem_ctrl/ext_req_i \
sm_testbench/sm_top/mem_ctrl/ext_rsp_o \
sm_testbench/sm_top/mem_ctrl/ext_data_o \
sm_testbench/sm_top/mem_ctrl/rom_data_i \
sm_testbench/sm_top/mem_ctrl/rom_addr_o \

add wave -color #ee66ff -radix hex -group CPU  \
/sm_testbench/sm_top/sm_cpu/regAddr \
/sm_testbench/sm_top/sm_cpu/regData \
/sm_testbench/sm_top/sm_cpu/im_req \
/sm_testbench/sm_top/sm_cpu/imAddr \
/sm_testbench/sm_top/sm_cpu/imData \
/sm_testbench/sm_top/sm_cpu/im_drdy \
/sm_testbench/sm_top/sm_cpu/addr_o \
/sm_testbench/sm_top/sm_cpu/data_o \

# cycle cnt
add wave -color #cccc00 -radix unsigned -group CYCLE_CNT  \
/sm_testbench/sm_top/i_cycle_cnt/cycleCnt_o \
sm_testbench/sm_top/i_cycle_cnt/en_i \

run -all