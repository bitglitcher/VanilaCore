

module seven_segment_tb();

logic clk;
logic rst;

logic new_clock;
logic new_rst;

initial begin
    new_clock = 0;
end
always@(posedge clk)
begin
    new_clock = ~new_clock;
    new_rst = ~rst;
end

WB4 seven_segment_wb(new_clock, ~new_rst);

seven_segment seven_segment_0(
    .wb(seven_segment_wb), 
    .display_data(display_data),
    .select(select)
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
    repeat(100000000) #10 clk = ~clk;
end


endmodule