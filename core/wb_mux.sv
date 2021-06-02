
//Author: Benjamin Herrera Navarro
//Date: 2/24/2021
//10:56 PM


module wb_mux
(
    input logic sel,
    WB4.slave master0, //Master BUS 0
    WB4.slave master1, //Master BUS 1
    WB4.master muxed_out //This bus is the output of the multiplexer
);

always_comb begin
    if(sel) 
    begin
        muxed_out.STB = master1.STB;
        muxed_out.ADR = master1.ADR;
        muxed_out.CYC = master1.CYC;
        muxed_out.DAT_O = master1.DAT_O;
        muxed_out.WE = master1.WE;
        master1.DAT_I = muxed_out.DAT_I;
        master1.ACK = muxed_out.ACK;
        master1.ERR = muxed_out.ERR;
        master1.RTY = muxed_out.RTY;
        master0.DAT_I = 0;
        master0.ACK = 0;
        master0.ERR = 0;
        master0.RTY = 0;
    end
    else
    begin
        muxed_out.STB = master0.STB;
        muxed_out.ADR = master0.ADR;
        muxed_out.CYC = master0.CYC;
        muxed_out.DAT_O = master0.DAT_O;
        muxed_out.WE = master0.WE;
        master0.DAT_I = muxed_out.DAT_I;
        master0.ACK = muxed_out.ACK;
        master0.ERR = muxed_out.ERR;
        master0.RTY = muxed_out.RTY;
        master1.DAT_I = 0;
        master1.ACK = 0;
        master1.ERR = 0;
        master1.RTY = 0;
    end
end



endmodule