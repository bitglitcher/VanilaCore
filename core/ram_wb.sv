//8:48AM Wishbone compatible RAM wrapper
//Author: Benjamin Herrera Navarro
//10/31/2020

module ram_wb(WB4.slave wb);

ram #(32, 12) RAM_0
(
    .clk(wb.clk),
	.we(wb.WE & wb.STB & wb.CYC),
	.data(wb.DAT_O),
	.addr(wb.ADR),
	.q(wb.DAT_I)
);

//All wishbone modules have to be reseted on the positive edge of the clock
//Sample signals at the rising edge
logic ack_s; //Signal for the ack line

always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        ack_s = 1'b0;
    end
    else
    begin
        if(wb.CYC & wb.STB)
        begin
            ack_s = 1'b1;
        end
        else
        begin
            ack_s = 1'b0;
        end
    end
end

//Only valid if CYC.
assign wb.ACK = ack_s & wb.CYC;

endmodule