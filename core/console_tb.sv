


module console_tb();

logic clk;
logic rst;
logic tx;

WB4 wb(clk, rst);



//Reset
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


console console_0(.wb(wb), .tx(tx));
console_test console_test_0(wb);

endmodule