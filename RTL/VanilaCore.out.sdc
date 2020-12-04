## Generated SDC file "VanilaCore.out.sdc"

## Copyright (C) 2019  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 19.1.0 Build 670 09/22/2019 SJ Lite Edition"

## DATE    "Thu Nov 26 09:58:42 2020"

##
## DEVICE  "EP4CE6E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {new_clock} -period 40.000 -waveform { 0.000 20.000 } [get_registers { new_clock }]
create_clock -name {debounce:debounce_rst|new_slow_clock[21]} -period 10000.000 -waveform { 0.000 5000.000 } [get_registers { debounce:debounce_rst|new_slow_clock[21] }]
create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports { clk }]
create_clock -name {seven_segment:seven_segment_0|cnt[15]} -period 1000.000 -waveform { 0.000 0.500 } [get_registers { seven_segment:seven_segment_0|cnt[15] }]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -rise_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -fall_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -rise_to [get_clocks {new_clock}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -fall_to [get_clocks {new_clock}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -rise_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -fall_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -rise_to [get_clocks {new_clock}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -fall_to [get_clocks {new_clock}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {new_clock}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {new_clock}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -rise_to [get_clocks {new_clock}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -fall_to [get_clocks {new_clock}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -rise_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -fall_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -rise_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -fall_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -rise_to [get_clocks {new_clock}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {new_clock}] -fall_to [get_clocks {new_clock}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -rise_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -fall_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -rise_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -fall_to [get_clocks {seven_segment:seven_segment_0|cnt[15]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -rise_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -fall_to [get_clocks {debounce:debounce_rst|new_slow_clock[21]}] -setup 1000.000  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -rise_to [get_clocks {new_clock}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {new_clock}] -fall_to [get_clocks {new_clock}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************
