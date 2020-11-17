
import global_pkg::*;

module core
(
    WB4.master inst_bus,
    WB4.master data_bus
);

logic [31:0] PC;
logic [31:0] IR;
logic execute;
logic [31:0] jump_target;
logic jump;
logic stop_cycle;
logic exit_ignore;

//Fetch state machine
fetch_stm fetch_stm_0
(
    .inst_bus(inst_bus),
    .PC_O(PC),
    .IR_O(IR),
    .execute(execute), //Wire to signal the execute cycle
    .jump_target(jump_target),
    .jump(jump),
    .stop_cycle(stop_cycle),
    .exit_ignore(exit_ignore)
);


decode decode_bus();

decoder decoder_0
(
    .IR(IR),
    .decode_bus(decode_bus)
);

/*
logic execute;
sr2_src_t sr2_src;
regfile_src_t regfile_src;
logic regfile_wr;

control_unit control_unit_0
(
    .execute(execute),
    .sr2_src(sr2_src),
    .regfile_src(regfile_src),
    .regfile_wr(regfile_wr)
);


control_unit 
(
    input logic execute,
    output sr2_src_t sr2_src,
    output regfile_src_t regfile_src,
    output logic regfile_wr,
    decode decode_bus,
    //memory_operation mem_op //This seta a command to the memory_stm
    output logic load_data,
    output logic store_data,
    output jmp_target_src_t jmp_target_src,
    output logic jump,
    input stop_cycle,
    output BRANCH_S //Signal to enable branching 
);

logic load_data;
logic store_data;


jmp_target_src_t jmp_target_src;

logic BRANCH_S;

logic [31:0] rs1_d; //This comes from the register file
logic [31:0] rs2_d; //This comes from the register file
logic [31:0] rd_d; //Directly to the register file
logic [31:0] alu_z; //ALU output
logic [31:0] ra_d; //This bus goes to the ALU
logic [31:0] rb_d; //This bus goes to the ALU
logic [31:0] load_data_src;



always_comb
begin
    unique case(jmp_target_src)
        J_IMM: jump_target <= 32'(signed'(j_imm)) + PC;
        I_IMM: jump_target <= (32'(signed'(i_imm)) + rs1_d) & 32'h7fffffff;
        B_IMM: jump_target <= 32'(signed'(b_imm)) + PC;
    endcase
end


branch_unit branch_unit_0
(
    .rs1_d(rs1_d),
    .rs2_d(rs2_d),
    .funct3(funct3),
    .branch(BRANCH_S)
);

//Register file data input multiplexer
always_comb
begin
    unique case(regfile_src)
        ALU_INPUT: rd_d <= alu_z;
        U_IMM_SRC: rd_d <= u_imm;
        AUIPC_SRC: rd_d <= u_imm + PC;
        LOAD_SRC: rd_d <= load_data_src;
        PC_SRC: rd_d <= PC + 4;
    endcase
end
regfile regfile_0
(
    .clk(inst_bus.clk),
    .rst(inst_bus.rst),
    .ra(rs1), 
    .rb(rs2),
    .rd(rd),
    .ra_d(rs1_d), 
    .rb_d(rs2_d),
    .rd_d(rd_d),
    .wr(regfile_wr)
);

//ALU input multiplexer
always_comb
begin
    unique case(sr2_src)
        I_IMM_SRC: rb_d <= 32'(signed'(i_imm));
        REG_SRC: rb_d <= rs2_d;
    endcase
end

alu ALU_0
(
    .ra_d(ra_d),
    .rb_d(rb_d),
    .rd_d(alu_z),
    .func3(funct3),
    .func7(funct7)
);

*/



endmodule 