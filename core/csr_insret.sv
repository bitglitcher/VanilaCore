
//This counter counts the number of instructions
module csr_insret
(
    //Syscon
    input logic clk,
    input logic rst,

    //Ins count
    input logic ins_exe, //Instruction execute signal

    //Data buses
    input logic sel, //Word selection High = 1, LOW = 0
    output logic [31:0] data_o,
);

//64bit counter
reg [63:0] counter;

always@(posedge clk)
begin
    //Reset
    if(rst)
    begin
        counter = 64'b0;
    end
    else
    begin
        if(ins_exe)
        begin
            counter = counter + 64'b1;        
        end
        else
        begin
            counter = counter;        
        end
    end
end











endmodule