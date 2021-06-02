//Author: Benjamin Herrerera Navarro.
//Date: 3/17/2021
//5:20PM


//This module strips out the CYC signal and adds other signal from a different source.

module wb_bus_ctrl_cmb
(
    input logic CYC, //This signals that a cycle will begin
    input en,
    //Wishbone bus
    WB4 wb_in,
    WB4 wb_out
);

//Signals that come from the slave device
assign wb_in.ACK = (CYC)? wb_out.ACK : 0;
assign wb_in.ERR = (CYC)? wb_out.ERR : 0;
assign wb_in.RTY = (CYC)? wb_out.RTY : 0;
assign wb_in.DAT_I = wb_out.DAT_I;

//Signals that go to the slave device
assign wb_out.STB = wb_in.STB;
assign wb_out.DAT_O = wb_in.DAT_O;
assign wb_out.WE = wb_in.WE;
assign wb_out.ADR = wb_in.ADR;

assign wb_out.CYC = CYC; //This is the only signal replaced


endmodule