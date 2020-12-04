
module wishbone_arbitrer
(
    WB4.master master_wb,
    WB4.slave inst_wb,
    WB4.slave data_wb
);

//Data from ram to inst and data buses
assign inst_wb.DAT_I = master_wb.DAT_I;
assign data_wb.DAT_I = master_wb.DAT_I;

//Prioritize DATA bus
assign master_wb.ADR = (data_wb.CYC & data_wb.STB)? data_wb.ADR : inst_wb.ADR;
assign master_wb.DAT_O = (data_wb.CYC & data_wb.STB)? data_wb.DAT_O : inst_wb.DAT_O;
assign master_wb.WE = (data_wb.CYC & data_wb.STB)? data_wb.WE : inst_wb.WE;
assign master_wb.CYC = (data_wb.CYC)? data_wb.CYC : inst_wb.CYC;
assign master_wb.STB = (data_wb.CYC & data_wb.STB)? data_wb.STB : inst_wb.STB;

//Ack signal
assign data_wb.ACK = (data_wb.CYC & data_wb.STB)? master_wb.ACK : 0;
assign inst_wb.ACK = (~(data_wb.CYC & data_wb.STB))? master_wb.ACK : 0;

endmodule 