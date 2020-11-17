

module core_tb();

logic clk;
logic rst;

WB4 inst_bus(clk, rst);
WB4 data_bus(clk, rst);


ram_wb MEMORY_INST(.wb(inst_bus));
ram_wb MEMORY_DATA(.wb(data_bus));

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