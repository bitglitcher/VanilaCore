

module csr_unit
(
    //Syscon
    input clk,
    input rst,

    //Commands
    input [11:0] i_imm,
    input wr;

    //Data buses
    input [31:0] din,
    output [31:0] dout

    //Exeption or trap signal to jump
    output logic trap,
    
);

//Current Privilege Mode
reg [2:0] cpm;


//Privilege modes
parameter M_MODE = 3;
parameter S_MODE = 1;
parameter U_MODE = 0;


always@(posedge clk)
begin
    
end






endmodule