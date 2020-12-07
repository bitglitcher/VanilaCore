//3:23AM Implementation of a simple single cycle RISC V RV32I core
//Author: Benjamin Herrera Navarro
//10/31/2020
`include "debug_def.sv"

module regfile
(
    input clk,
    input rst,
    input  [4:0] ra, 
    input  [4:0] rb,
    input  [4:0] rd,
    output [31:0] ra_d, 
    output [31:0] rb_d,
    input [31:0] rd_d,
    input wr
    `ifdef DEBUG_PORT
    ,output logic [31:0] reg_debug [31:0]
    `endif
);

//32, 32bit registers
reg [31:0] REGS [31:0]; 

`ifdef DEBUG_PORT
    assign reg_debug = REGS;
`endif

always@(posedge clk)
begin
    if(rst) //Reset
    begin
        for(int i = 0;i < 32;i++)
        begin
            REGS[i] = 32'h00000000;
        end
    end 
    else if(wr && (rd > 0)) //Write
    begin
        REGS[rd] = rd_d; 
    end
    else
    begin
        REGS[rd] = REGS[rd];
    end
end

//Register file output
assign ra_d = REGS[ra];
assign rb_d = REGS[rb];


endmodule