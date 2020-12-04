
//This unit counts clock cycles 
module csr_cycle 
#(
    parameter LOW_ADDR = 0;
    parameter HIGH_ADDR = 1;
)
(
    //Interface
    csr_int.slave sys_con,

    //Data output bus
    output logic [31:0] data
);

//64bit counter
reg [63:0] counter;

always@(posedge sys_con.clk)
begin
    //Reset
    if(sys_con.rst)
    begin
        counter = 64'b0;
    end
    else
    begin
        //These are read only
        counter = counter + 64'b1;        
    end
end




endmodule