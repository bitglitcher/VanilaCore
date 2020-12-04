//Interface to commmunicate with each CSR
interface csr_int(input clk, input rst);
    //Data
    logic [31:0] data;
    //Control signals
    logic cyc;
    logic sel; //Used to select the low and high parts

    modport slave
    (
        input clk,
        input rst,
        //Data
        input [31:0] data_i,
        //Control signals
        input wr,
        input cyc,
        input sel
    );
    modport master
    (
        input clk,
        input rst,
        //Data
        input  [31:0] data_i,
        //Control signals
        output wr,
        output cy,
        output sel
    );
endinterface //csr_int