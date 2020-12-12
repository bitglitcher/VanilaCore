//8:48AM Wishbone compatible RAM wrapper
//Author: Benjamin Herrera Navarro
//10/31/2020

`include "debug_def.sv"

module ram_wb #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 20)(WB4.slave wb);

ram #(DATA_WIDTH, ADDR_WIDTH) RAM_0
(
    .clk(wb.clk),
	.we(wb.WE & wb.STB & wb.CYC),
	.data(wb.DAT_O),
	.addr(wb.ADR),
	.q(wb.DAT_I)
    //DEBUG PORT probes
    `ifdef DEBUG_PORT
    ,.debug_data(debug_data),
    .debug_address(debug_address)
    `endif
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

`ifdef MEMORY_DEBUG_MSGS
always@(posedge wb.clk & wb.ACK)
begin
    if(wb.ADR [1:0] != 2'b0) $display("Memory Warning: Unaligned Memory Access");
    if(wb.WE) $display("Memory Write: Address 0x%08x, Data 0x%08x", wb.ADR [(ADDR_WIDTH+1):2], wb.DAT_O);
    else $display("Memory Read: Address 0x%08x, Data 0x%08x", wb.ADR [(ADDR_WIDTH+1):2], wb.DAT_I);
end
`endif

endmodule