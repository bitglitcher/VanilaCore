

module branch_unit
(
    input [31:0] rs1_d,
    input [31:0] rs2_d,
    input [2:0] funct3,
    input enable,
    output logic branch
);

logic BEQ_S;
logic BNE_S;
logic BLT_S;
logic BGE_S;
logic BLTU_S;
logic BGEU_S;

parameter BEQ = 3'b000;
parameter BNE = 3'b001;
parameter BLT = 3'b100;
parameter BGE = 3'b101;
parameter BLTU = 3'b110;
parameter BGEU = 3'b111;

//Branch logic
assign BEQ_S = ((32'(signed'(rs1_d)) == 32'(signed'(rs2_d))) & (funct3 == BEQ))? 1 : 0;
assign BNE_S = ((32'(signed'(rs1_d)) != 32'(signed'(rs2_d))) & (funct3 == BNE))? 1 : 0;
assign BLT_S = ((32'(signed'(rs1_d)) < 32'(signed'(rs2_d))) & (funct3 == BLT))? 1 : 0;
assign BGE_S = ((32'(signed'(rs1_d)) >= 32'(signed'(rs2_d))) & (funct3 == BGE))? 1 : 0;
assign BLTU_S = ((rs1_d < rs2_d) & funct3 == BLTU)? 1 : 0;
assign BGEU_S = ((rs1_d >= rs2_d) & funct3 == BGEU)? 1 : 0;
assign branch = ((BEQ_S | BNE_S | BLT_S | BGE_S | BLTU_S | BGEU_S) & enable)? 1 : 0;


endmodule