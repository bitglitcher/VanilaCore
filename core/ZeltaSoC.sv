
`include "debug_def.sv"

module ZeltaSoC
(
    `ifndef sim
	input logic clk,
	input logic rst,
    output logic uart_tx,
    input  logic uart_rx
    `endif
);

logic new_rst;

`ifdef sim
logic clk;
logic rst;
logic uart_tx;
logic uart_rx;
assign new_rst = rst;
`endif

debounce debounce_rst
(
    .clk(clk),
    .debounce(~rst),
    .debounced(new_rst)
);

//Buses from CPU
WB4 inst_bus(clk, new_rst);
WB4 data_bus(clk, new_rst);

//Bus to access memory from data bus
WB4 memory_wb(clk, new_rst);

//Bus to access RAM directly
WB4 memory_mater_wb(clk, new_rst);

//Devices
WB4 uart_wb(clk, new_rst);
WB4 uart_rx_wb(clk, new_rst);

//Timer for timer interrupts
WB4 timer_dev(clk, new_rst);

//Interrupt
logic interrupt;

cross_bar cross_bar_0 
(
    //Define master
    .cpu(data_bus),
    .memory(memory_wb),
    .uart(uart_wb),
    .uart_rx(uart_rx_wb),
    .timer_dev(timer_dev)
);

wishbone_arbitrer wishbone_arbitrer_0
(
    .master_wb(memory_mater_wb),
    .inst_wb(inst_bus),
    .data_wb(memory_wb)
);

//Timer for timer interrupts
timer timer_0
(
    .wb(timer_dev),
    .interrupt(interrupt)
);

//Memory and devices
ram_wb #(32, 16) MEMORY_RAM(.wb(memory_mater_wb));
uart_slave uart_slave_0
(
    .wb(uart_rx_wb),
    .rx(uart_rx)
);
console console_0(.wb(uart_wb), .tx(uart_tx));

core CORE_0
    (
        .inst_bus(inst_bus),
        .data_bus(data_bus),
        .timer_irq(interrupt)
    );

`ifdef sim   
initial begin
    //Begin of reset secuence
    clk <= 0;
    rst <= 0;
    #10
    clk <= 1;
    rst <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    rst <= 0;
    //End of reset secuence
    repeat(100000000) #10 clk = ~clk;
end

`endif

endmodule