//3:51AM Arithmetic Logic Unit for the RISC V RV32I implementation

module alu
(
    input  logic [31:0] ra_d,
    input  logic [31:0] rb_d,
    output logic [31:0] rd_d,
    input  logic [2:0] func3,
    input  logic [6:0] func7,
    input  logic imm_t
);

wire signed [31:0] signed_ra = ra_d; 
wire signed [31:0] signed_rb = rb_d; 

//R type
parameter ADD =  10'b0000000000;
parameter SUB =  10'b0100000000;
parameter SLL =  10'b0000000001;
parameter SLT =  10'b0000000010;
parameter SLTU = 10'b0000000011;
parameter XOR =  10'b0000000100;
parameter SRL =  10'b0000000101;
parameter SRA =  10'b0100000101;
parameter OR =   10'b0000000110;
parameter AND =  10'b0000000111;
//I type
parameter ADDI =  10'b???????000;
parameter SLTI =  10'b???????010;
parameter SLTIU = 10'b???????011;
parameter XORI =  10'b???????100;
parameter ORI =   10'b???????110;
parameter ANDI =  10'b???????111;
parameter SLLI =  10'b???????001;
parameter SRLI =  10'b0000000101;
parameter SRAI =  10'b0100000101;

always_comb
begin
    if(imm_t)
    begin
        casez({func7, func3})
            ADDI: rd_d = signed_ra + signed_rb;
            SLTI: rd_d = (signed_ra < signed_rb) ? 32'h00000001 : 32'h00000000;
            SLTIU: rd_d = (ra_d < rb_d) ? 32'h00000001 : 32'h00000000;
            XORI: rd_d = ra_d ^ rb_d;
            ORI: rd_d = ra_d | rb_d;
            ANDI: rd_d = ra_d & rb_d;
            SLLI: rd_d = ra_d << rb_d [4:0];
            SRLI: rd_d = ra_d >> rb_d [4:0];
            SRAI: rd_d = signed'(ra_d) >>> rb_d [4:0];
            default: rd_d = 32'h00000000;
        endcase
    end
    else
    begin
        case({func7, func3})
            ADD: rd_d = signed_ra + signed_rb;
            SUB: rd_d = signed_ra - signed_rb;
            SLL: rd_d = ra_d << rb_d [4:0];
            SLT: rd_d = (signed_ra < signed_rb) ? 32'h00000001 : 32'h00000000;
            SLTU: rd_d = (ra_d < rb_d) ? 32'h00000001 : 32'h00000000;
            XOR: rd_d = ra_d ^ rb_d;
            SRL: rd_d = ra_d >> rb_d [4:0];
            SRA: rd_d = signed'(ra_d) >>> rb_d [4:0];
            OR: rd_d = ra_d | rb_d;
            AND: rd_d = ra_d & rb_d;
            default: rd_d = 32'h00000000;
        endcase
    end
end

endmodule
