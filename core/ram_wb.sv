//8:48AM Wishbone compatible RAM wrapper
//Author: Benjamin Herrera Navarro
//10/31/2020

module ram_wb(WB4.slave wb);

ram #(32, 13) RAM_0
(
    .clk(wb.clk),
	.we(wb.WE & wb.STB & wb.CYC),
	.data(wb.DAT_O),
	.addr(wb.ADR),
	.q(wb.DAT_I)
);

//All wishbone modules have to be reseted on the positive edge of the clock
//Sample signals at the rising edge
always@(posedge wb.clk)
begin
    if(wb.CYC & wb.STB)
    begin
        wb.ACK = 1'b1;
    end
    else
    begin
        wb.ACK = 1'b0;
    end
end


endmodule