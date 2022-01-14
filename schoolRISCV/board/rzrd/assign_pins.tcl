# Tcl package ::quartus::project is required to execute following script
# The command for an execution: source <path>/assign_pins.tcl

# GLOBAL
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
set_global_assignment -name ENABLE_INIT_DONE_OUTPUT OFF

set_location_assignment	PIN_23	-to	clk
set_location_assignment	PIN_25	-to	rst_n

# SW
set_location_assignment	PIN_88	-to	key_sw[0]
set_location_assignment	PIN_89	-to	key_sw[1]
set_location_assignment	PIN_90  -to	key_sw[2]
set_location_assignment	PIN_91	-to	key_sw[3]

# LEDS
set_location_assignment	PIN_87	-to	led[0]
set_location_assignment	PIN_86	-to	led[1]
set_location_assignment	PIN_85  -to	led[2]
set_location_assignment	PIN_84	-to	led[3]

# SEGM
set_location_assignment	PIN_127	-to	hex[7]
set_location_assignment	PIN_124	-to	hex[6]
set_location_assignment	PIN_126	-to	hex[5]
set_location_assignment	PIN_132	-to	hex[4]
set_location_assignment	PIN_129	-to	hex[3]
set_location_assignment	PIN_125	-to	hex[2]
set_location_assignment	PIN_121	-to	hex[1]
set_location_assignment	PIN_128	-to	hex[0]

# DIG
set_location_assignment	PIN_133	-to	digit[0]
set_location_assignment	PIN_135	-to	digit[1]
set_location_assignment	PIN_136	-to digit[2]
set_location_assignment	PIN_137	-to	digit[3]

# BUZZER
set_location_assignment	PIN_110	-to	buzzer
