

module core_tb();

logic clk;
logic rst;

WB4 inst_bus(clk, rst);
WB4 data_bus(clk, rst);
WB4 memory_wb(clk, rst);
WB4 uart_wb(clk, rst);


cross_bar cross_bar_0 
(
    //Define master
    .cpu(data_bus),
    .memory(memory_wb),
    .uart(uart_wb)
);

ram_wb MEMORY_INST(.wb(memory_wb));
ram_wb MEMORY_DATA(.wb(uart_wb));

core CORE_0
    (
        .inst_bus(inst_bus),
        .data_bus(data_bus)
    );



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
    rst <= 0;
    //End of reset secuence
    repeat(10000000) #10 clk = ~clk;
end


endmodule