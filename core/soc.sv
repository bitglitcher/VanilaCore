

module soc
(
	input logic clk,
	input logic rst,
    output logic uart_tx,
    output [6:0] display_data,
    output [3:0] select
);


logic new_clock;
logic new_rst;

//logic clk;
//logic rst;
//logic uart_tx;
//logic [6:0] display_data;
//logic [3:0] select;
//assign new_rst = rst;

initial begin
    new_clock = 0;
end
always@(posedge clk)
begin
    new_clock = ~new_clock;
end

debounce debounce_rst
(
    .clk(clk),
    .debounce(~rst),
    .debounced(new_rst)
);

WB4 inst_bus(new_clock, new_rst);
WB4 data_bus(new_clock, new_rst);
WB4 memory_wb(new_clock, new_rst);
WB4 uart_wb(new_clock, new_rst);
WB4 seven_segment_wb(new_clock, new_rst);

cross_bar cross_bar_0 
(
    //Define master
    .cpu(data_bus),
    .memory(memory_wb),
    .uart(uart_wb),
    .seven_segments(seven_segment_wb)
);

//Memory and devices
ram_wb MEMORY_INST(.wb(inst_bus));
ram_wb MEMORY_DATA(.wb(memory_wb));
console console_0(.wb(uart_wb), .tx(uart_tx));
seven_segment seven_segment_0(
    .wb(seven_segment_wb), 
    .display_data(display_data),
    .select(select)
    );



core CORE_0
    (
        .inst_bus(inst_bus),
        .data_bus(data_bus)
    );

    
//initial begin
//    //Begin of reset secuence
//    clk <= 0;
//    rst <= 0;
//    #10
//    clk <= 1;
//    rst <= 1;
//    #10
//    clk <= 0;
//    #10
//    clk <= 1;
//    rst <= 0;
//    //End of reset secuence
//    repeat(100000000) #10 clk = ~clk;
//end


endmodule