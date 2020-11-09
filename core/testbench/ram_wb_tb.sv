

module ram_wb_tb(); //top module

logic clk;
logic rst;

WB4 wb(clk, rst);

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
    repeat(200) #10 clk = ~clk;
end

test_ram test(.wb(wb));
ram_wb ram_0(.wb(wb));

endmodule 