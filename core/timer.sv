

module timer
(
    WB4.slave wb,
    output logic interrupt
);

//Address       Register
//0x0000        timecmp low
//0x0004        timecmp high
//0x0008        time low
//0x000c        time high

reg [63:0] mtimecmp;
reg [63:0] mtime;

logic ack_s;

//reading from the timers
always_comb
begin
    case(wb.ADR[3:0])
        4'h0: wb.DAT_I = mtimecmp [31:0];
        4'h4: wb.DAT_I = mtimecmp [63:32];
        4'h8: wb.DAT_I = mtime [31:0];
        4'hc: wb.DAT_I = mtime [63:0];
        default: wb.DAT_I = 32'b0;
    endcase
end

always@(posedge wb.clk)
begin
    if(wb.STB & wb.CYC)
    begin
        ack_s = 1'b1;
        if(wb.WE)
        begin
            unique case(wb.ADR[3:0])
                4'h0: mtimecmp [31:0] = wb.DAT_O;
                4'h4: mtimecmp [63:32] = wb.DAT_O;
                4'h8: mtime [31:0] = wb.DAT_O;
                4'hc: mtime [63:0] = wb.DAT_O;
            endcase
        end
    end
    else
    begin
        ack_s = 1'b0;
    end
end

assign wb.ACK = (ack_s & wb.STB & wb.CYC);

//Hold interrupt line while mtimecmp >= mtime
assign interrupt = (mtimecmp >= mtime)? 1 : 0;


endmodule