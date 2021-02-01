import global_pkg::*;
`include "debug_def.sv"



module pmp_unit
(
    //Syscon
    input logic clk,
    input logic rst,

    //Control signals
    input wire [11:0] addr,
    input logic wr,
    input write_mode_t write_mode, //Chose the mode in which to write to the CSR
    input  logic [31:0] din,
    output logic [31:0] dout,
    output logic illegal_address,

    //
    input logic [31:0] ls_address, //Load store address
    input logic [31:0] ls //Memory access instruction
);

/////////////////////////////////////////////////////////////////////
//                         Verify Logic                            //
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
//                     Read and Write Logic                        //
/////////////////////////////////////////////////////////////////////

//Multiplexer to choose the write data
logic [31:0] mux_o_bus;
always_comb begin : csr_din_mux
    unique case(write_mode)
        CSR_SET: mux_o_bus = dout | din;
        CSR_CLEAR: mux_o_bus = dout | ~din;
        CSR_WRITE: mux_o_bus = din;
    endcase
end

//Read


//Write

endmodule 