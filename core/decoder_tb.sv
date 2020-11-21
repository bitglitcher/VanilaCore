//Author: Benjamin Herrera Navarro
//Testbench to test the decoder
//6:23PM
//11/16/2020

module decoder_tb();

decode decoder_int();

reg [31:0] RAM [(16**2)-1:0];

reg [31:0] PC = 0;
logic clk = 0;

initial begin
    $readmemh("C:/Users/camin/Documents/VanilaCore/core/c_code/ROM.hex", RAM);
    repeat(1000000000) #10 clk = ~clk;
end

always@(posedge clk)
begin
    PC = PC + 1;
end

decoder decoder_0
(
    .IR(RAM[PC]),
    .decode_bus(decoder_int)
);



endmodule