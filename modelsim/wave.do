onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal -childformat {{{/cross_bar_tb/cross_bar_0/address_bus[1]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/address_bus[0]} -radix hexadecimal}} -expand -subitemconfig {{/cross_bar_tb/cross_bar_0/address_bus[1]} {-height 15 -radix hexadecimal} {/cross_bar_tb/cross_bar_0/address_bus[0]} {-height 15 -radix hexadecimal}} /cross_bar_tb/cross_bar_0/address_bus
add wave -noupdate -radix hexadecimal -childformat {{{/cross_bar_tb/cross_bar_0/occupied_bus[1]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/occupied_bus[0]} -radix hexadecimal}} -expand -subitemconfig {{/cross_bar_tb/cross_bar_0/occupied_bus[1]} {-height 15 -radix hexadecimal} {/cross_bar_tb/cross_bar_0/occupied_bus[0]} {-height 15 -radix hexadecimal}} /cross_bar_tb/cross_bar_0/occupied_bus
add wave -noupdate -radix hexadecimal -childformat {{{/cross_bar_tb/cross_bar_0/sel_0[3]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/sel_0[2]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/sel_0[1]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/sel_0[0]} -radix hexadecimal}} -expand -subitemconfig {{/cross_bar_tb/cross_bar_0/sel_0[3]} {-radix hexadecimal} {/cross_bar_tb/cross_bar_0/sel_0[2]} {-radix hexadecimal} {/cross_bar_tb/cross_bar_0/sel_0[1]} {-radix hexadecimal} {/cross_bar_tb/cross_bar_0/sel_0[0]} {-radix hexadecimal}} /cross_bar_tb/cross_bar_0/sel_0
add wave -noupdate -radix hexadecimal -childformat {{{/cross_bar_tb/cross_bar_0/sel_1[3]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/sel_1[2]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/sel_1[1]} -radix hexadecimal} {{/cross_bar_tb/cross_bar_0/sel_1[0]} -radix hexadecimal}} -expand -subitemconfig {{/cross_bar_tb/cross_bar_0/sel_1[3]} {-radix hexadecimal} {/cross_bar_tb/cross_bar_0/sel_1[2]} {-radix hexadecimal} {/cross_bar_tb/cross_bar_0/sel_1[1]} {-radix hexadecimal} {/cross_bar_tb/cross_bar_0/sel_1[0]} {-radix hexadecimal}} /cross_bar_tb/cross_bar_0/sel_1
add wave -noupdate -radix hexadecimal /cross_bar_tb/cross_bar_0/sel_master
add wave -noupdate -divider CPU
add wave -noupdate -radix hexadecimal /cross_bar_tb/clk
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/clk
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/rst
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/ACK
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/ERR
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/RTY
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/STB
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/ADR
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/CYC
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/DAT_I
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/DAT_O
add wave -noupdate -radix hexadecimal /cross_bar_tb/cpu_wb/WE
add wave -noupdate -divider DMA
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/clk
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/rst
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/ACK
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/ERR
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/RTY
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/STB
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/ADR
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/CYC
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/DAT_I
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/DAT_O
add wave -noupdate -radix hexadecimal /cross_bar_tb/dma_wb/WE
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {123 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 259
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {226 ps}
